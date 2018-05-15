#include "servercontrol.h"

#include <QWebSocket>
#include <QNetworkInterface>
#include <QDebug>

ServerControl::ServerControl()
    : QObject()
{
    mServer = new QWebSocketServer("qmlplaygroundserver", QWebSocketServer::NonSecureMode);
    QObject::connect(mServer, &QWebSocketServer::newConnection, this, &ServerControl::onNewConnection);
}

ServerControl::~ServerControl()
{
    mServer->deleteLater();
}

bool ServerControl::startListening(int port)
{
    QString ipAddress;
    QList<QHostAddress> ipAddressesList = QNetworkInterface::allAddresses();
    for (int i = 0; i < ipAddressesList.size(); ++i)
    {
        if (ipAddressesList.at(i) != QHostAddress::LocalHost && ipAddressesList.at(i).toIPv4Address())
        {
            ipAddress = ipAddressesList.at(i).toString();
            break;
        }
    }

    bool success = mServer->listen(QHostAddress::AnyIPv4, port);
    setAvailable(success);

    QString hostAddress = ipAddress + ":" + QString::number(mServer->serverPort());
    setHostAddress(hostAddress);
    qDebug() << "Server is listening at" << hostAddress;
    return success;
}

void ServerControl::onNewConnection()
{
    while(mServer->hasPendingConnections())
    {
        //QTcpSocket *socket = server.nextPendingConnection();
        QWebSocket* socket = mServer->nextPendingConnection();
        qDebug() << "NEW CONNECTION ESTABLISHED!" << socket;

        //socket->sendTextMessage("Hello from server");
        mClients.push_back(socket);
    }
}

void ServerControl::sendToClients(const QString& message)
{
    for (QWebSocket* client: mClients)
    {
        client->sendTextMessage(message);
    }
}

bool ServerControl::isAvailable() const
{
    return m_available;
}

QString ServerControl::hostAddress() const
{
    return m_hostAddress;
}

void ServerControl::setAvailable(bool available)
{
    if (m_available == available)
        return;

    m_available = available;
    emit availableChanged(m_available);
}

void ServerControl::setHostAddress(QString hostAddress)
{
    if (m_hostAddress == hostAddress)
        return;

    m_hostAddress = hostAddress;
    emit hostAddressChanged(m_hostAddress);
}
