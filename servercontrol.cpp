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

    connect(&mUdpTimer, &QTimer::timeout, this, &ServerControl::broadcastDatagram);
}

ServerControl::~ServerControl()
{
    mServer->deleteLater();
}

bool ServerControl::start()
{
    // ----------------------------------------------------------
    // First, start the actual listening
    // ----------------------------------------------------------
    if (!startListening(m_serverPort))
        return false;

    // ----------------------------------------------------------
    // Then, start broadcasting the availability on the network
    // ----------------------------------------------------------

    if (udpSocket4.state() != QAbstractSocket::UnconnectedState)
    {
//        qDebug() << "\n\nUDP SOCKET 4 is not unconnnected. " << udpSocket4.state();
//        udpSocket4.close();
        udpSocket4.disconnectFromHost();
        udpSocket4.waitForDisconnected();
    }
    if (udpSocket6.state() != QAbstractSocket::UnconnectedState)
    {
//        qDebug() << "\n\nUDP SOCKET 6 is not unconnnected. " << udpSocket6.state();
//        udpSocket6.close();
        udpSocket6.disconnectFromHost();
        udpSocket6.waitForDisconnected();
    }

    // force binding to their respective families
    udpSocket4.bind(QHostAddress(QHostAddress::AnyIPv4), 0);
    udpSocket6.bind(QHostAddress(QHostAddress::AnyIPv6), udpSocket4.localPort());

    bool ipv4 = udpSocket4.state() == QAbstractSocket::BoundState;
    bool ipv6 = udpSocket6.state() == QAbstractSocket::BoundState;

    if (!ipv4) qDebug() << tr("IPv4 failed.");
    if (!ipv6) qDebug() << tr("IPv6 failed.");

    if ((!ipv4) && (!ipv6))
        return false;

    // we only set the TTL on the IPv4 socket, as that changes the multicast scope
    udpSocket4.setSocketOption(QAbstractSocket::MulticastTtlOption, 4);

    startBroadcasting();

    setAvailable(true);
    return true;
}

bool ServerControl::stop()
{
    mServer->close();
    stopBroadcasting();
    setAvailable(false);
    return true;
}

bool ServerControl::startListening(int port)
{
    // Start listening on both ipv4 and ipv6
    bool success = mServer->listen(QHostAddress::Any, port);
    setAvailable(success);

    // Now we need to find what addresses will be seen by clients and report them to the user

    // The server seemingly does not report the actual address(es) it is listening on
    // Thus we cannot report exactly what address is "the good one"
//    qDebug() << "url:" << mServer->serverUrl()
//             << "address:" << mServer->serverAddress()
//             << "port:" << mServer->serverPort()
//             << "proxy:" << mServer->proxy()
//             << "error:" << mServer->errorString()
//             ;

    QList<QHostAddress> list = QNetworkInterface::allAddresses();
    QList<QHostAddress> filtered;

    for (auto&& interface: QNetworkInterface::allInterfaces())
    {
        // Filter out invalid and localhost
        if (!interface.isValid() ||
             interface.type() == QNetworkInterface::Loopback)
            continue;

        for (auto&& entry: interface.addressEntries())
        {
            // Keep only DNS eligible addresses (idk if that's acceptable)
            if (entry.dnsEligibility() != QNetworkAddressEntry::DnsEligible)
                continue;

            filtered << entry.ip();

            qDebug() << "interface:" << interface.humanReadableName();
            qDebug() << "\tentry: ip:" << entry.ip()
                     << ", broadcast:" << entry.broadcast()
                     << ", netmask:" << entry.netmask()
                     << ", dnsEligible:" << entry.dnsEligibility()
                     << ", permanent:" << entry.isPermanent()
                     ;
        }
    }

    QString hostAddressStr;
    for (auto&& hostAddress: filtered)
        hostAddressStr += hostAddress.toString() + ":12345\n";
//    QString hostAddressStr = ipAddress.toString() + ":" + QString::number(mServer->serverPort());
//    QString hostAddressStr = mServer->serverAddress().toString() + ":" + QString::number(mServer->serverPort());
    setHostAddress(hostAddressStr);
    qDebug() << "Server is listening at" << hostAddressStr;


//    for (auto&& interface: QNetworkInterface::allInterfaces())
//    {
//        for (auto&& entry: interface.addressEntries())
//        {
//            qDebug() << "interface:" << interface.humanReadableName();
//            qDebug() << "\tentry: ip:" << entry.ip()
//                     << ", broadcast:" << entry.broadcast()
//                     << ", netmask:" << entry.netmask()
//                     << ", dnsEligible:" << entry.dnsEligibility()
//                     << ", permanent:" << entry.isPermanent()
//                     ;
//        }
//    }

    return success;
}

void ServerControl::onNewConnection()
{
    while (mServer->hasPendingConnections())
    {
        //QTcpSocket *socket = server.nextPendingConnection();
        QWebSocket* socket = mServer->nextPendingConnection();
        qDebug() << "NEW CONNECTION ESTABLISHED!" << socket
                                                  << socket->origin()
                                                  << socket->peerName()
                                                  << socket->peerAddress()
                                                  << socket->peerPort();

        //socket->sendTextMessage("Hello from server");
        mClients.push_back(socket);
        setActiveClients(mClients.size());
        emit newConnection();

        connect(socket, &QWebSocket::disconnected, [=]()
        {
            mClients.removeOne(socket);
            setActiveClients(mClients.size());
        });

        connect(socket, QOverload<QAbstractSocket::SocketError>::of(&QWebSocket::error), [=](QAbstractSocket::SocketError error)
        {
            qDebug() << error;
            if (error == QAbstractSocket::RemoteHostClosedError)
            {
                mClients.removeOne(socket);
                setActiveClients(mClients.size());
            }
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

void ServerControl::stopBroadcasting()
{
    mUdpTimer.stop();
}

inline QString message(QString tag, QString content)
{
    return QString("<%1>%2</%1>").arg(tag).arg(content);
}

void ServerControl::broadcastDatagram()
{
    static uint n = 0;
    ++n;

    qDebug() << "broadcasting datagram" << n;

    QString datagramStr = "qmlplayground " + message("id", m_serverId);
    QByteArray datagram = QByteArray::fromStdString(datagramStr.toStdString());
    udpSocket4.writeDatagram(datagram, groupAddress4, 45454);
    if (udpSocket6.state() == QAbstractSocket::BoundState)
        udpSocket6.writeDatagram(datagram, groupAddress6, 45454);
}
