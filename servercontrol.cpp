#include "servercontrol.h"

#include <QWebSocket>
#include <QNetworkInterface>
#include <QUdpSocket>
#include <QDebug>
#include <QFile>

ServerControl::ServerControl()
    : QObject(),
      groupAddress4(QStringLiteral("239.255.255.250")), // Simple Service Discovery Protocol" Address (https://forum.qt.io/topic/74822/multicast-sender-and-receiver-example/7)
      groupAddress6(QStringLiteral("ff12::2115"))
{
    mServer = new QWebSocketServer("qmlplaygroundserver", QWebSocketServer::NonSecureMode);
    QObject::connect(mServer, &QWebSocketServer::newConnection, this, &ServerControl::onNewConnection);

    // force binding to their respective families
    udpSocket4.bind(QHostAddress(QHostAddress::AnyIPv4), 0);
    udpSocket6.bind(QHostAddress(QHostAddress::AnyIPv6), udpSocket4.localPort());

    if (udpSocket6.state() != QAbstractSocket::BoundState)
        qDebug() << tr("IPv6 failed. Ready to multicast datagrams to group %1 on port 45454").arg(groupAddress4.toString());

    // we only set the TTL on the IPv4 socket, as that changes the multicast scope
    udpSocket4.setSocketOption(QAbstractSocket::MulticastTtlOption, 4);

    connect(&mUdpTimer, &QTimer::timeout, this, &ServerControl::broadcastDatagram);
    startBroadcasting();
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
    qDebug() << "url:" << mServer->serverUrl()
             << "address:" << mServer->serverAddress()
             << "port:" << mServer->serverPort()
             << "proxy:" << mServer->proxy()
             << "error:" << mServer->errorString()
             ;

    QString hostAddressStr = ipAddress.toString() + ":" + QString::number(mServer->serverPort());
//    QString hostAddressStr = mServer->serverAddress().toString() + ":" + QString::number(mServer->serverPort());
    setHostAddress(hostAddressStr);
    qDebug() << "Server is listening at" << hostAddressStr;


    for (auto&& interface: QNetworkInterface::allInterfaces())
    {
        for (auto&& entry: interface.addressEntries())
        {
            qDebug() << "interface:" << interface.humanReadableName();
            qDebug() << "\tentry: ip:" << entry.ip()
                     << ", broadcast:" << entry.broadcast()
                     << ", netmask:" << entry.netmask()
                     << ", dnsEligible:" << entry.dnsEligibility()
                     << ", permanent:" << entry.isPermanent()
                     ;
        }
    }

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

void ServerControl::startBroadcasting()
{
    mUdpTimer.start(1000);
}

void ServerControl::broadcastDatagram()
{
    static uint n = 0;
    ++n;

    QByteArray datagram = "qmlplayground Broadcast message #" + QByteArray::number(n);
    udpSocket4.writeDatagram(datagram, groupAddress4, 45454);
    if (udpSocket6.state() == QAbstractSocket::BoundState)
        udpSocket6.writeDatagram(datagram, groupAddress6, 45454);
}
