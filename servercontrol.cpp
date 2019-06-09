#include "servercontrol.h"

#include <QWebSocket>
#include <QNetworkInterface>
#include <QDebug>
#include <QFile>

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
//    QString ipAddress;
//    QHostAddress hostAddress;
//    QList<QHostAddress> ipAddressesList = QNetworkInterface::allAddresses();
//    for (int i = 0; i < ipAddressesList.size(); ++i)
//    {
//        QHostAddress h = ipAddressesList.at(i);
//        bool isIPV4 = true;
//        h.toIPv4Address(&isIPV4);

//        if (h != QHostAddress::LocalHost && isIPV4 && h.isInSubnet(QHostAddress("255.255.255"), 0))
//        {
//            hostAddress = ipAddressesList.at(i);
//            ipAddress = ipAddressesList.at(i).toString();
//            break;
//        }
//    }
    QList<QHostAddress> list = QNetworkInterface::allAddresses();
    QHostAddress ipAddress;
    for (int nIter=0; nIter < list.count(); nIter++)
    {
        if(!list[nIter].isLoopback() &&
            list[nIter] != QHostAddress::LocalHost &&
            list[nIter].protocol() == QAbstractSocket::IPv4Protocol)
        {
            ipAddress = list[nIter];
            qDebug() << list[nIter].toString();
            break;
        }

    }

    bool success = mServer->listen(QHostAddress::AnyIPv4, port);
    setAvailable(success);

    QString hostAddressStr = ipAddress.toString() + ":" + QString::number(mServer->serverPort());
//    QString hostAddressStr = mServer->serverAddress().toString() + ":" + QString::number(mServer->serverPort());
    setHostAddress(hostAddressStr);
    qDebug() << "Server is listening at" << hostAddressStr;
    return success;
}

void ServerControl::onNewConnection()
{
    while (mServer->hasPendingConnections())
    {
        //QTcpSocket *socket = server.nextPendingConnection();
        QWebSocket* socket = mServer->nextPendingConnection();
        qDebug() << "NEW CONNECTION ESTABLISHED!" << socket;

        //socket->sendTextMessage("Hello from server");
        mClients.push_back(socket);
        setActiveClients(mClients.size());

        connect(socket, &QWebSocket::disconnected, [=](){
            mClients.removeOne(socket);
            setActiveClients(mClients.size());
        });
    }
}

void ServerControl::sendToClients(const QString& message)
{
    for (QWebSocket* client: mClients)
    {
        client->sendTextMessage(message);
    }
}

void ServerControl::sendFilesToClients(const QStringList &files)
{
    QString message;

    for (const QString& filename: files)
    {
        // Read file content
        QFile file(filename);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        {
            qDebug() << "cannot open " << filename;
            continue;
        }

        QTextStream textStream(&file);
        QString fileContent = textStream.readAll();

        // Generate header
        QString header = QString("<file>%1</file>").arg(file.fileName());

        // Append content
        message += header + QString("<content>\n%1\n</content>").arg(fileContent);

        // Append separator
        message += "\n";
    }

    sendToClients(message);
}

void ServerControl::sendByteArrayToClients(const QByteArray &message)
{
    for (QWebSocket* client: mClients)
    {
        client->sendBinaryMessage(message);
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

int ServerControl::activeClients() const
{
    return m_activeClients;
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

void ServerControl::setActiveClients(int activeClients)
{
    if (m_activeClients == activeClients)
        return;

    m_activeClients = activeClients;
    emit activeClientsChanged(m_activeClients);
}
