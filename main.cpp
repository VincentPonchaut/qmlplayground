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
    appControl.start("qrc:/main.qml", &engine);
#else
    QDirIterator it(":",
                    QStringList() << "*.qml" << "*.js" << "*.png" << "*.svg",
                    QDir::NoFilter,
                    QDirIterator::Subdirectories);

    QDir appDir = QDir::current();

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
#endif

    return app.exec();
}
