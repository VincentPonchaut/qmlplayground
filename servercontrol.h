#ifndef SERVERCONTROL_H
#define SERVERCONTROL_H

#include <QObject>
#include <QTimer>
#include <QWebSocketServer>

#include <QtNetwork>

QT_BEGIN_NAMESPACE
class QUdpSocket;
QT_END_NAMESPACE

class ServerControl: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString hostAddress READ hostAddress WRITE setHostAddress NOTIFY hostAddressChanged)
    Q_PROPERTY(bool available READ isAvailable WRITE setAvailable NOTIFY availableChanged)
    Q_PROPERTY(int activeClients READ activeClients WRITE setActiveClients NOTIFY activeClientsChanged)

public:
    ServerControl();
    virtual ~ServerControl();

    bool startListening(int port);
    void onNewConnection();

    Q_INVOKABLE void sendToClients(const QString& message);
    Q_INVOKABLE void sendFilesToClients(const QStringList& files);    
    Q_INVOKABLE void sendByteArrayToClients(const QByteArray& message);

// ------------------------------------------------------------------
// QProperties
// ------------------------------------------------------------------
public:
    bool isAvailable() const;
    QString hostAddress() const;

    int activeClients() const;

public slots:
    void setAvailable(bool available);
    void setHostAddress(QString hostAddress);
    void setActiveClients(int activeClients);

signals:
    void availableChanged(bool available);
    void hostAddressChanged(QString hostAddress);
    void activeClientsChanged(int activeClients);

private:
    void startBroadcasting();
    void broadcastDatagram();

private:
    QWebSocketServer *mServer = nullptr;
    QVector<QWebSocket*> mClients;

    QUdpSocket udpSocket4;
    QUdpSocket udpSocket6;
    QHostAddress groupAddress4;
    QHostAddress groupAddress6;

    QTimer mUdpTimer;

    bool m_available;
    QString m_hostAddress;
    int m_activeClients;
};

#endif // SERVERCONTROL_H
