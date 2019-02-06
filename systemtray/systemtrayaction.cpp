#include "systemtrayaction.h"

SystemTrayAction::SystemTrayAction(QObject *parent) : QObject(parent)
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
