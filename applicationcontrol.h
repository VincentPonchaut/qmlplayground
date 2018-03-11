#ifndef APPLICATIONCONTROL_H
#define APPLICATIONCONTROL_H

#include <QObject>
#include <QQuickView>
#include <QFileSystemWatcher>
#include <QQmlApplicationEngine>
#include <QQmlComponent>

class ApplicationControl : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QStringList folderList READ folderList WRITE setFolderList NOTIFY folderListChanged)

public:
    explicit ApplicationControl(QObject *parent = nullptr);
    ~ApplicationControl();

    QStringList folderList() const;

    void start(const QString &pMainQmlPath, QQmlApplicationEngine* pEngine);

    Q_INVOKABLE int runCommand(const QString& pCommand);
    Q_INVOKABLE int runCommandWithArgs(const QString& pCommand, const QStringList& pArgs);
    Q_INVOKABLE QStringList listFiles(const QString& pPath);
    Q_INVOKABLE void openFileExternally(const QString& pPath);

    Q_INVOKABLE bool createFolder(QString pPath, QString pFolderName);
    Q_INVOKABLE bool createFile(QString pPath, QString pFileName);

signals:
    void folderListChanged(QStringList folderList);
    void fileChanged(const QString& pFilePath);
    void directoryChanged(const QString& pDirectoryPath);

public slots:
    void setFolderList(QStringList folderList);
    void onFileChanged(const QString& pPath);
    void onDirectoryChanged(const QString& pPath);

protected:
    void setupWatchOnFolder(const QString& pPath);
    QString newFileContent();

private:
    // Owned
    QQuickView *mQuickView = nullptr; // deprecated
    QQmlComponent* mQuickComponent = nullptr;
    QString mMainQmlPath;
    QFileSystemWatcher mFileWatcher;

    // QProperties
    QStringList mFolderList;

    // External
    QQmlApplicationEngine* mEngine = nullptr;
};

#endif // APPLICATIONCONTROL_H
