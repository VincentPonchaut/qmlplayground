#include <QApplication>
#include <QQmlApplicationEngine>
#include <QFileSystemWatcher>
#include <QDirIterator>
#include <QDebug>
#include <QQuickView>
#include <QFileDialog>
#include <QSettings>
#include <QQuickStyle>

#include "tools/maskedmousearea.h"
#include "applicationcontrol.h"
#include "SyntaxHighlighter.h"

#include "systemtray/systemtrayicon.h"

#include <QtGlobal>
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
    qmlRegisterType<MaskedMouseArea>("Tools", 1, 0, "MaskedMouseArea");
    qmlRegisterType<SyntaxHighlighter>("SyntaxHighlighter", 1, 1, "SyntaxHighlighter");

    SystemTrayIcon::registerQmlTypes();
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

    app.setWindowIcon(QIcon(":/img/appIcon.png"));

    QSettings::setDefaultFormat(QSettings::IniFormat);

    // Prepare the QML engine
    QQmlApplicationEngine engine;
    registerQmlTypes(engine);

    ApplicationControl appControl;
    theApplicationControl = &appControl;

    // Set style for QtQuickControls 2
    QQuickStyle::setStyle("Material");

    appControl.start("qrc:/main.qml", &engine);

    return app.exec();
}
