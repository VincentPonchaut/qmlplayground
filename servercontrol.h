#ifndef SERVERCONTROL_H
#define SERVERCONTROL_H

#include <QObject>
#include <QWebSocketServer>

class ServerControl: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString hostAddress READ hostAddress WRITE setHostAddress NOTIFY hostAddressChanged)
    Q_PROPERTY(bool available READ isAvailable WRITE setAvailable NOTIFY availableChanged)

public:
    ServerControl();
    virtual ~ServerControl();

    bool startListening(int port);
    void onNewConnection();

    Q_INVOKABLE void sendToClients(const QString& message);

// ------------------------------------------------------------------
// QProperties
// ------------------------------------------------------------------
public:
    bool isAvailable() const;
    QString hostAddress() const;

public slots:
    void setAvailable(bool available);
    void setHostAddress(QString hostAddress);

signals:
    void availableChanged(bool available);
    void hostAddressChanged(QString hostAddress);

private:
    QWebSocketServer *mServer = nullptr;
    QVector<QWebSocket*> mClients;
    bool m_available;
    QString m_hostAddress;
};

#endif // SERVERCONTROL_H
