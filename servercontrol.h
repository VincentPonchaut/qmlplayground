#ifndef SERVERCONTROL_H
#define SERVERCONTROL_H

#include <QObject>
#include <QWebSocketServer>

class ServerControl: public QObject
{
    Q_OBJECT

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

public slots:
    void setAvailable(bool available);

signals:
    void availableChanged(bool available);

private:
    QWebSocketServer *mServer = nullptr;
    QVector<QWebSocket*> mClients;
    bool m_available;
};

#endif // SERVERCONTROL_H
