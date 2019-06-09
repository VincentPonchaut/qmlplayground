#ifndef APPLICATIONCONTROL_H
#define APPLICATIONCONTROL_H

#include <QObject>
#include <QQuickView>
#include <QFileSystemWatcher>
#include <QQmlApplicationEngine>
#include <QQmlComponent>

#include "servercontrol.h"

class ApplicationControl: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QStringList folderList READ folderList WRITE setFolderList NOTIFY folderListChanged)

    Q_PROPERTY(QString currentFile READ currentFile WRITE setCurrentFile NOTIFY currentFileChanged)
    Q_PROPERTY(QString currentFolder READ currentFolder WRITE setCurrentFolder NOTIFY currentFolderChanged)


public:
    explicit ApplicationControl(QObject *parent = nullptr);
    ~ApplicationControl();

    QStringList folderList() const;

    void start(const QString &pMainQmlPath,
               QQmlApplicationEngine* pEngine,
               int pServerPort = 12345);

    void onLogMessage(QtMsgType type, const QMessageLogContext &context, const QString &msg);

    Q_INVOKABLE int runCommand(const QString& pCommand);
    Q_INVOKABLE int runAsyncCommand(const QString& pCommand);
    Q_INVOKABLE int runCommandWithArgs(const QString& pCommand, const QStringList& pArgs);
    Q_INVOKABLE QStringList listFiles(const QString& pPath, const QStringList& pNameFilters = QStringList("*.qml"));
    Q_INVOKABLE void openFileExternally(const QString& pPath);

    Q_INVOKABLE bool createFolder(QString pPath, QString pFolderName);
    Q_INVOKABLE bool createFile(QString pPath, QString pFileName);
    Q_INVOKABLE bool copyFile(QString pSrcPath, QString pDstPath);
    Q_INVOKABLE bool copyFeaturePack(QString pFeaturePackPrefix, QString pDstPath);
    Q_INVOKABLE bool saveImageAsIco(QString pSrcPath, QString pDstPath);

    Q_INVOKABLE void addToFolderList(const QString& pFolderPath);
    Q_INVOKABLE void removeFromFolderList(const QString& pFolderPath);

    Q_INVOKABLE void requestClearQmlComponentCache();

    Q_INVOKABLE QString readFileContents(const QString& pFilePath);
    Q_INVOKABLE bool writeFileContents(const QString& pFilePath, const QString& pFileContents);

    Q_INVOKABLE void addContextProperty(const QString& pKey, QVariant pData);

    Q_INVOKABLE void sendFolderToClients(const QString& folder);
    Q_INVOKABLE void sendFileToClients(const QString& file);
    Q_INVOKABLE void sendDataMessage(const QString& data);
    Q_INVOKABLE void sendZippedFolderToClients(const QString& folder);
    Q_INVOKABLE void sendFolderChangeMessage();

    Q_INVOKABLE void setClipboardText(const QString& clipboard);

    Q_INVOKABLE bool exists(const QString& path);

    QString currentFile() const;
    QString currentFolder() const;

signals:
    void folderListChanged(QStringList folderList);
    void fileChanged(const QString& pFilePath);
    void directoryChanged(const QString& pDirectoryPath);
    void currentFileChanged(QString currentFile);
    void currentFolderChanged(QString currentFolder);
    void newConnection();

    void logMessage(const QString& message, const QString& file, int line);
    void warningMessage(const QString& message, const QString& file, int line);

public slots:
    void setFolderList(QStringList folderList);
    void onFileChanged(const QString& pPath);
    void onDirectoryChanged(const QString& pPath);
    void setCurrentFile(QString currentFile);
    void setCurrentFolder(QString currentFolder);

protected slots:
    void onFolderListChanged();

protected:
    void setupWatchOnFolder(const QString& pPath);
    QString newFileContent();
    bool addFileToMessage(const QString& path, QString& message);

private:
    // Owned
    QQuickView *mQuickView = nullptr; // deprecated
    QQmlComponent* mQuickComponent = nullptr;
    QString mMainQmlPath;
    QFileSystemWatcher mFileWatcher;
    ServerControl mServerControl;

    // QProperties
    QStringList mFolderList;
    QString m_currentFile;
    QString m_currentFolder;

    // External
    QQmlApplicationEngine* mEngine = nullptr;
};

#endif // APPLICATIONCONTROL_H
