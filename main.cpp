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

void registerQmlTypes(QQmlApplicationEngine& pEngine)
{
    Q_UNUSED(pEngine)
    qmlRegisterType<MaskedMouseArea>("Tools", 1, 0, "MaskedMouseArea");
    qmlRegisterType<SyntaxHighlighter>("SyntaxHighlighter", 1, 1, "SyntaxHighlighter");
}

int main(int argc, char *argv[])
{
    // Prepare the application
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setOrganizationName("QmlEnterprise");
    QCoreApplication::setOrganizationDomain("qmlenterprise.com");
    QCoreApplication::setApplicationName("QmlPlayground");
    QApplication app(argc, argv);

    app.setWindowIcon(QIcon(":/img/appIcon.png"));

    QSettings::setDefaultFormat(QSettings::IniFormat);

    // Prepare the QML engine
    QQmlApplicationEngine engine;
    registerQmlTypes(engine);

    ApplicationControl appControl;

    // Set style for QtQuickControls 2
    QQuickStyle::setStyle("Material");


    appControl.start("qrc:/main.qml", &engine);

    return app.exec();
}
