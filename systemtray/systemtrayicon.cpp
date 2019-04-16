#include "systemtrayicon.h"
#include <QQmlEngine>

SystemTrayIcon::SystemTrayIcon(QObject *parent)
    : QObject(parent)
{
    mMenu = new QMenu();
    connect(mMenu, &QMenu::triggered, [=](QAction* a) {
        emit mActionMap[a]->triggered();
    });

    mSystemTrayIcon = new QSystemTrayIcon(this);
    QPixmap pixmap(":/img/appIcon.png");
    mSystemTrayIcon->setIcon(QIcon(pixmap));
    mSystemTrayIcon->setContextMenu(mMenu);

    mSystemTrayIcon->show();
}

QUrl SystemTrayIcon::iconUrl() const
{
    return mIconUrl;
}

void SystemTrayIcon::setIconUrl(QUrl iconUrl)
{
    if (mIconUrl == iconUrl)
        return;

    QString iconPath = iconUrl.path().replace("file:///", "");

    if (iconPath.startsWith("/"))
        iconPath = iconPath.remove(0, 1);

    if (iconUrl.scheme() == "qrc")
        iconPath = ":" + iconPath; // from something like "/img/myimg.png" to ":/img/myimg.png"

    mIconUrl = iconUrl;
    mSystemTrayIcon->setIcon(QIcon(iconPath));

    emit iconUrlChanged(mIconUrl);
}

QQmlListProperty<SystemTrayMenuItem> SystemTrayIcon::menuItems()
{
    return QQmlListProperty<SystemTrayMenuItem>(this, this,
             &SystemTrayIcon::appendMenuItem,
             &SystemTrayIcon::menuItemCount,
             &SystemTrayIcon::menuItem,
             &SystemTrayIcon::clearMenuItems);
}

void SystemTrayIcon::appendMenuItem(SystemTrayMenuItem* p)
{
    if (p->inherits("SystemTraySeparator"))
    {
        mMenu->addSeparator();
        return;
    }
    else if (p->inherits("SystemTrayAction"))
    {
        SystemTrayAction* a = qobject_cast<SystemTrayAction*>(p);
        QAction* newQAction = mMenu->addAction(a->name());
        mActionMap[newQAction] = a;
    }

    mMenuItems.append(p);

}

int SystemTrayIcon::menuItemCount() const
{
    return mMenuItems.count();
}

SystemTrayMenuItem *SystemTrayIcon::menuItem(int index) const
{
    return mMenuItems.at(index);
}

void SystemTrayIcon::clearMenuItems()
{
    mMenuItems.clear();
}

void SystemTrayIcon::registerQmlTypes(const char *uri)
{
    qmlRegisterType<SystemTrayIcon>(uri, 1, 0, "SystemTrayIcon");

    qmlRegisterType<SystemTrayMenuItem>();
    qmlRegisterType<SystemTrayAction>(uri, 1, 0, "SystemTrayAction");
    qmlRegisterType<SystemTraySeparator>(uri, 1, 0, "SystemTraySeparator");
}

// static

void SystemTrayIcon::appendMenuItem(QQmlListProperty<SystemTrayMenuItem>* list, SystemTrayMenuItem* p)
{
    reinterpret_cast< SystemTrayIcon* >(list->data)->appendMenuItem(p);
}

void SystemTrayIcon::clearMenuItems(QQmlListProperty<SystemTrayMenuItem>* list)
{
    reinterpret_cast< SystemTrayIcon* >(list->data)->clearMenuItems();
}

SystemTrayMenuItem* SystemTrayIcon::menuItem(QQmlListProperty<SystemTrayMenuItem>* list, int i)
{
    return reinterpret_cast< SystemTrayIcon* >(list->data)->menuItem(i);
}

int SystemTrayIcon::menuItemCount(QQmlListProperty<SystemTrayMenuItem>* list)
{
    return reinterpret_cast< SystemTrayIcon* >(list->data)->menuItemCount();
}
