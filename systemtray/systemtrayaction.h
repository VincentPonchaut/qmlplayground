#ifndef SYSTEMTRAYACTION_H
#define SYSTEMTRAYACTION_H

#include <QObject>

class SystemTrayAction : public QObject
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

#endif // SYSTEMTRAYACTION_H
