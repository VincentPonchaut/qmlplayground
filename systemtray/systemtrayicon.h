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
    Q_PROPERTY(QQmlListProperty<SystemTrayAction> actions READ actions)

public:
    explicit SystemTrayIcon(QObject* parent = nullptr);
    QUrl iconUrl() const;

    QQmlListProperty<SystemTrayAction> actions();
    void appendAction(SystemTrayAction*);
    int actionCount() const;
    SystemTrayAction *action(int) const;
    void clearActions();

    static void registerQmlTypes();

public slots:
    void setIconUrl(QUrl iconUrl);

signals:
    void iconUrlChanged(QUrl iconUrl);

private:
    static void appendAction(QQmlListProperty<SystemTrayAction>*, SystemTrayAction*);
    static int actionCount(QQmlListProperty<SystemTrayAction>*);
    static SystemTrayAction *action(QQmlListProperty<SystemTrayAction>*,int);
    static void clearActions(QQmlListProperty<SystemTrayAction>*);

    QUrl m_iconUrl;
    QVector<SystemTrayAction*> m_actions;
    QHash<QAction*, SystemTrayAction*> m_actionsMap;
    QSystemTrayIcon* m_systemTrayIcon;
    QMenu* m_menu;
};

#endif // SYSTEMTRAYICON_H
