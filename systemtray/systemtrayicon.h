#ifndef SYSTEMTRAYICON_H
#define SYSTEMTRAYICON_H

#include <QObject>
#include <QAction>
#include <QQmlListProperty>
#include <QUrl>
#include <QSystemTrayIcon>
#include <QMenu>

#include "systemtrayaction.h"


class SystemTrayIcon: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QUrl iconUrl READ iconUrl WRITE setIconUrl NOTIFY iconUrlChanged)
    Q_PROPERTY(QQmlListProperty<SystemTrayMenuItem> menuItems READ menuItems)
    Q_CLASSINFO("DefaultProperty", "menuItems")


public:
    explicit SystemTrayIcon(QObject* parent = nullptr);
    QUrl iconUrl() const;

    QQmlListProperty<SystemTrayMenuItem> menuItems();
    void appendMenuItem(SystemTrayMenuItem*);
    int menuItemCount() const;
    SystemTrayMenuItem *menuItem(int) const;
    void clearMenuItems();

    static void registerQmlTypes();

public slots:
    void setIconUrl(QUrl iconUrl);

signals:
    void iconUrlChanged(QUrl iconUrl);

private:
    static void appendMenuItem(QQmlListProperty<SystemTrayMenuItem>*, SystemTrayMenuItem*);
    static int menuItemCount(QQmlListProperty<SystemTrayMenuItem>*);
    static SystemTrayMenuItem *menuItem(QQmlListProperty<SystemTrayMenuItem>*,int);
    static void clearMenuItems(QQmlListProperty<SystemTrayMenuItem>*);

    QUrl mIconUrl;
    QVector<SystemTrayMenuItem*> mMenuItems;
    QHash<QAction*, SystemTrayAction*> mActionMap;
    QSystemTrayIcon* mSystemTrayIcon;
    QMenu* mMenu;
};

#endif // SYSTEMTRAYICON_H
