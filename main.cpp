#include <QApplication>
#include <QQmlApplicationEngine>
#include <QFileSystemWatcher>
#include <QDirIterator>
#include <QDebug>
#include <QQuickView>
#include <QFileDialog>
#include <QSettings>
#include <QQuickStyle>
#include <QtWebEngine>
#include <QtWebView>
#include <QMessageBox>

#include "tools/maskedmousearea.h"
#include "applicationcontrol.h"
#include "SyntaxHighlighter.h"

#include "systemtray/systemtrayicon.h"
#include "svg/svgimageitem.h"


#include <QtGlobal>
#include <QSettings>
#include <stdio.h>
#include <stdlib.h>

static ApplicationControl* theApplicationControl = nullptr;

void myMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    if (!theApplicationControl)
        return;

    theApplicationControl->onLogMessage(type, context, msg);
}

void registerQmlTypes(QQmlApplicationEngine& pEngine)
{
    Q_UNUSED(pEngine)
    qmlRegisterType<MaskedMouseArea>("QmlPlayground", 1, 0, "MaskedMouseArea");
    qmlRegisterType<SyntaxHighlighter>("QmlPlayground", 1, 0, "SyntaxHighlighter");

    SystemTrayIcon::registerQmlTypes("QmlPlayground");
    SvgImageItem::registerQmlTypes("QmlPlayground");
}

bool copyFile(QString srcPath, QString dstPath)
{
    QFile srcFile(srcPath);
    if (!srcFile.open(QIODevice::ReadOnly))
        return false;

    QFile dstFile(dstPath);
    if (!dstFile.open(QIODevice::WriteOnly))
        return false;

    auto bytesWritten = dstFile.write(srcFile.readAll());
    if (bytesWritten == -1)
        return false;

    return true;
}

int main(int argc, char *argv[])
{
    // Install a custom handler for qDebug etc...
    qInstallMessageHandler(myMessageOutput);

    // Prepare the application
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setOrganizationName("QmlPlayground");
    QCoreApplication::setOrganizationDomain("QmlPlayground.com");
    QCoreApplication::setApplicationName("QmlPlayground");
    QApplication app(argc, argv);

    app.setWindowIcon(QIcon(":/img/appIcon.ico"));

    QSettings::setDefaultFormat(QSettings::IniFormat);

    QtWebView::initialize();
    QtWebEngine::initialize();

    // Prepare the QML engine
    QQmlApplicationEngine engine;
    registerQmlTypes(engine);

    ApplicationControl appControl;
    theApplicationControl = &appControl;

    // Set style for QtQuickControls 2
    QQuickStyle::setStyle("Material");


#ifdef QT_NO_DEBUG
//#if 1
    appControl.start("qrc:/main.qml", &engine);
#else
    QStringList nameFilters = QStringList() << "*.qml" << "*.js" << "*.png" << "*.svg";
    QDirIterator it(":",
                    nameFilters,
                    QDir::NoFilter,
                    QDirIterator::Subdirectories);

    QDir appDir = QDir::current();
    QString thePath = appDir.absoluteFilePath("qmldebug/");
    QUrl url(thePath);

    // If files already exists, ask whether or not to copy them
    QDir qmldebugDir(thePath);
    if (qmldebugDir.exists())
    {
        auto answer = QMessageBox::question(nullptr,
                                            "Hello",
                                            "qmldebug folder already exists, do you want to copy its content back to sources ?");
        if (answer == QMessageBox::Yes)
        {
            auto sourcesFolder = QFileDialog::getExistingDirectory(nullptr,
                                                                   "Select the sources folder",
                                                                   QDir::currentPath());
            QDir sourceDir(sourcesFolder);
            assert(sourceDir.exists());

            // Copy the files

            QDirIterator oldFiles(thePath,
                                  nameFilters,
                                  QDir::NoFilter,
                                  QDirIterator::Subdirectories);
            while (oldFiles.hasNext())
            {
                auto oldFile = oldFiles.next();

                QFileInfo oldFileInfo(oldFile);
                assert(oldFileInfo.exists());

                QString oldFileRelativePath = oldFileInfo.absoluteFilePath().remove(qmldebugDir.absolutePath());
                if (oldFileRelativePath.startsWith("/"))
                    oldFileRelativePath.remove(0,1);

                QString srcFile(sourceDir.absolutePath() + "/" + oldFileRelativePath);
                QFileInfo srcFileInfo(srcFile);
                //assert(srcFileInfo.exists());
                // if the file does not exist, it does not come from our sources
                if (!srcFileInfo.exists())
                    continue;

                auto success = copyFile(oldFileInfo.absoluteFilePath(), srcFileInfo.absoluteFilePath());
                assert(success);
            }

        }
    }

    // Generate actual files from QRC
    QStringList toBeWatched;
    while (it.hasNext())
    {
        it.next();

        // Read source file
        QFileInfo qrcFileInfo = it.fileInfo();
//        qDebug() << qrcFileInfo;

        QFile qrcFile(qrcFileInfo.absoluteFilePath());
        bool openSrc = qrcFile.open(QIODevice::ReadOnly | QFile::Text);
        assert(openSrc);

        QString qrcPath = qrcFileInfo.absolutePath().remove(":");
        QString localPath = "qmldebug" + qrcPath;
        appDir.mkpath(localPath);

        // Write source file contents into a new local file
        QFile diskFile(localPath + "/" + it.fileName());
        bool openDst = diskFile.open(QIODevice::WriteOnly | QFile::Text);
        assert(openDst);

        diskFile.write(qrcFile.readAll());

        QFileInfo diskFileInfo(diskFile);
        toBeWatched << diskFileInfo.absoluteFilePath();
    }

    // Add newly created paths to the watcher
    QFileSystemWatcher watcher;

    auto loadApp = [&appControl, &engine, &watcher](QString path)
    {
        qDebug() << "Loading app";
        // BUG: watcher removes the path once a change has been detected...
        watcher.addPath(path);

        QObject* rootObject = appControl.quickRootObject();
        if (rootObject)
        {
            rootObject->setProperty("visible", false);
//            rootObject->deleteLater();
//            delete rootObject;
        }
        engine.clearComponentCache();

        appControl.start("qmldebug/main.qml", &engine);
    };
    QObject::connect(&watcher, &QFileSystemWatcher::fileChanged, loadApp);
    QObject::connect(&watcher, &QFileSystemWatcher::directoryChanged, loadApp);

    watcher.addPaths(toBeWatched);

    loadApp("");    
    QDesktopServices::openUrl(url);
#endif

    return app.exec();
}
