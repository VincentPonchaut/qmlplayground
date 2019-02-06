#include "systemtrayicon.h"
#include <QQmlEngine>

SystemTrayIcon::SystemTrayIcon(QObject *parent)
    : QObject(parent)
{
    m_menu = new QMenu();
    connect(m_menu, &QMenu::triggered, [=](QAction* a) {
        emit m_actionsMap[a]->triggered();
    });

    m_systemTrayIcon = new QSystemTrayIcon(this);
    QPixmap pixmap(":/img/appIcon.png");
    m_systemTrayIcon->setIcon(QIcon(pixmap));
    m_systemTrayIcon->setContextMenu(m_menu);

    m_systemTrayIcon->show();
}

QUrl SystemTrayIcon::iconUrl() const
{
    return m_iconUrl;
}

void SystemTrayIcon::setIconUrl(QUrl iconUrl)
{
    if (m_iconUrl == iconUrl)
        return;

    QString iconPath = iconUrl.path().replace("file:///", "");

    if (iconPath.startsWith("/"))
        iconPath = iconPath.remove(0, 1);

    if (iconUrl.scheme() == "qrc")
        iconPath = ":" + iconPath; // from something like "/img/myimg.png" to ":/img/myimg.png"

    m_iconUrl = iconUrl;
    m_systemTrayIcon->setIcon(QIcon(iconPath));

    emit iconUrlChanged(m_iconUrl);
}

QQmlListProperty<SystemTrayAction> SystemTrayIcon::actions()
{
    return QQmlListProperty<SystemTrayAction>(this, this,
             &SystemTrayIcon::appendAction,
             &SystemTrayIcon::actionCount,
             &SystemTrayIcon::action,
             &SystemTrayIcon::clearActions);
}

void SystemTrayIcon::appendAction(SystemTrayAction* p)
{
    m_actions.append(p);
    QAction* newQAction = m_menu->addAction(p->name());

    m_actionsMap[newQAction] = p;
}

int SystemTrayIcon::actionCount() const
{
    return m_actions.count();
}

SystemTrayAction *SystemTrayIcon::action(int index) const
{
    return m_actions.at(index);
}

void SystemTrayIcon::clearActions()
{
    m_actions.clear();
}

void SystemTrayIcon::registerQmlTypes()
{
    qmlRegisterType<SystemTrayAction>("SystemTray", 1, 0, "SystemTrayAction");
    qmlRegisterType<SystemTrayIcon>("SystemTray", 1, 0, "SystemTrayIcon");
}

// static

void SystemTrayIcon::appendAction(QQmlListProperty<SystemTrayAction>* list, SystemTrayAction* p)
{
    reinterpret_cast< SystemTrayIcon* >(list->data)->appendAction(p);
}

void SystemTrayIcon::clearActions(QQmlListProperty<SystemTrayAction>* list)
{
    reinterpret_cast< SystemTrayIcon* >(list->data)->clearActions();
}

SystemTrayAction* SystemTrayIcon::action(QQmlListProperty<SystemTrayAction>* list, int i)
{
    return reinterpret_cast< SystemTrayIcon* >(list->data)->action(i);
}

int SystemTrayIcon::actionCount(QQmlListProperty<SystemTrayAction>* list)
{
    return reinterpret_cast< SystemTrayIcon* >(list->data)->actionCount();
}
