#include "systemtrayaction.h"

SystemTrayMenuItem::SystemTrayMenuItem(QObject *parent)
    : QObject (parent)
{

}

SystemTrayAction::SystemTrayAction(QObject *parent) : SystemTrayMenuItem (parent)
{

}

QString SystemTrayAction::name() const
{
    return m_name;
}

void SystemTrayAction::setName(QString name)
{
    if (m_name == name)
        return;

    m_name = name;
    emit nameChanged(m_name);
}

