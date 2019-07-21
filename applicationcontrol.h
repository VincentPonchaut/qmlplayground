#ifndef APPLICATIONCONTROL_H
#define APPLICATIONCONTROL_H

#include <QObject>
#include <QQuickView>
#include <QFileSystemWatcher>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QFuture>
#include <QFutureWatcher>
#include <QThread>
#include <QMutex>


#include "macros.h"
#include "servercontrol.h"
#include "multirootfolderlistmodel.h"

// -------------------------------------------------------------------

class FileSystemWatcher: public QObject
{
    Q_OBJECT

public slots:
    void doWork();
    void setWatchedDirectory(const QString& pDirectory);

signals:
    void needToReloadQml();
    void needToReloadAssets();

private:
    void listFiles(QString path);

    bool mNeedRefresh = false;
    QMutex mMutex;
    QString mWatchedDirectory;
    QFileInfoList mQmlJsFiles;
    QFileInfoList mAssets;
    QMap<QString, QDateTime> mFileTimes;
};

// -------------------------------------------------------------------

class ApplicationControl: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QStringList folderList READ folderList WRITE setFolderList NOTIFY folderListChanged)
    PROPERTY(QString, currentFile, setCurrentFile)
    PROPERTY(QString, currentFolder, setCurrentFolder)

    PROPERTY(MultiRootFolderListModel*, folderModel, setFolderModel)

public:
    explicit ApplicationControl(QObject *parent = nullptr);
    ~ApplicationControl();

    void start(const QString &pMainQmlPath,
               QQmlApplicationEngine* pEngine,
               int pServerPort = 12345);

    void onLogMessage(QtMsgType type, const QMessageLogContext &context, const QString &msg);

    Q_INVOKABLE int runCommand(const QString& pCommand);
    Q_INVOKABLE int runAsyncCommand(const QString& pCommand);
    Q_INVOKABLE int runCommandWithArgs(const QString& pCommand, const QStringList& pArgs);
    Q_INVOKABLE QStringList listFiles(const QString& pPath, const QStringList& pNameFilters = QStringList("*.qml"));
    Q_INVOKABLE void openFileExternally(QString pPath);

    Q_INVOKABLE bool createFolder(QString pPath, QString pFolderName);
    Q_INVOKABLE bool createFile(QString pPath, QString pFileName);
    Q_INVOKABLE bool copyFile(QString pSrcPath, QString pDstPath);
    Q_INVOKABLE bool copyFeaturePack(QString pFeaturePackPrefix, QString pDstPath);
    Q_INVOKABLE bool saveImageAsIco(QString pSrcPath, QString pDstPath);

    Q_INVOKABLE void addToFolderList(QString pFolderPath);
    Q_INVOKABLE void removeFromFolderList(QString pFolderPath);
    Q_INVOKABLE bool isInFolderList(QString pFolderPath);
    Q_INVOKABLE bool isAlreadyWatched(QString pFolderPath);

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

    Q_INVOKABLE void setCurrentFileAndFolder(QString folder, QString file);

    QStringList folderList() const;

    QObject *quickRootObject() const;

signals:
    void fileChanged(const QString& pFilePath);
    void directoryChanged(const QString& pDirectoryPath);
    void reloadRequest();
    void newConnection();
    void startWatching(const QString& pDirectory);
    void logMessage(const QString& message, const QString& file, int line);
    void warningMessage(const QString& message, const QString& file, int line);
    void folderListChanged(QStringList READ);

public slots:
    void onFileChanged(const QString& pPath);
    void onDirectoryChanged(const QString& pPath);
    void setFolderList(QStringList folderList);

protected slots:
    void onZippedFolderReadyToSend();
    void onNeedToReloadQml();
    void onNeedToReloadAssets();

protected:
    QString newFileContent();
    bool addFileToMessage(const QString& path, QString& message);
    QString newFolderChangeMessage();

private:
    // Owned
    QQmlComponent* mQuickComponent = nullptr;
    QObject* mQuickRootObject = nullptr;
    QString mMainQmlPath;
    ServerControl mServerControl;
    QThread mWatcherThread;
    QMutex mMutex;

    // External
    QQmlApplicationEngine* mEngine = nullptr;

    // Zip task
    QFuture<QByteArray> mFuture;
    QFutureWatcher<QByteArray> mFutureWatcher;
    QStringList m_folderList;
};

#endif // APPLICATIONCONTROL_H
