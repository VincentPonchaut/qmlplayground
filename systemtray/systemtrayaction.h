#ifndef SYSTEMTRAYACTION_H
#define SYSTEMTRAYACTION_H

#include <QObject>

class SystemTrayMenuItem: public QObject
{
    Q_OBJECT
public:
    explicit SystemTrayMenuItem(QObject* parent = nullptr);
};

class SystemTrayAction : public SystemTrayMenuItem
{
    Q_OBJECT

    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)

public:
    explicit SystemTrayAction(QObject *parent = nullptr);

    QString name() const;

public slots:
    void setName(QString name);

signals:
    void triggered();
    void nameChanged(QString name);

private:
    QString m_name;
};


class SystemTraySeparator: public SystemTrayMenuItem
{
    Q_OBJECT
};

#endif // SYSTEMTRAYACTION_H
