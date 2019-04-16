#include <QApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include <QSettings>
#include <QtWebView>

#include "systemtray/systemtrayicon.h"

void registerQmlTypes(QQmlApplicationEngine& pEngine)
{
    Q_UNUSED(pEngine)
//    qmlRegisterType<MaskedMouseArea>("Tools", 1, 0, "MaskedMouseArea");
//    qmlRegisterType<SyntaxHighlighter>("SyntaxHighlighter", 1, 1, "SyntaxHighlighter");

    SystemTrayIcon::registerQmlTypes("SystemTray");
}

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setOrganizationName("%1");
    QCoreApplication::setOrganizationDomain("%1");
    QCoreApplication::setApplicationName("%1");

    QSettings::setDefaultFormat(QSettings::IniFormat);

    QApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/appIcon.png"));

    QtWebView::initialize();

    QQmlApplicationEngine engine;
    registerQmlTypes(engine);

    engine.load(QUrl(QStringLiteral("qrc:/qmlplayground_generated_main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
