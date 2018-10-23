#include "applicationcontrol.h"

#include <QDebug>
#include <QQmlContext>
#include <QDirIterator>
#include <QProcess>
#include <QGuiApplication>
#include <QClipboard>

#include <iostream>

inline QString beginTag(const QString& tag)
{
    return "<" + tag + ">";
}

inline QString endTag(const QString& tag)
{
    return "</" + tag + ">";
}

ApplicationControl::ApplicationControl(QObject *parent) : QObject(parent)
{
    QObject::connect(&mFileWatcher,
                     &QFileSystemWatcher::fileChanged,
                     this,
                     &ApplicationControl::onFileChanged);
    QObject::connect(&mFileWatcher,
                     &QFileSystemWatcher::directoryChanged,
                     this,
                     &ApplicationControl::onDirectoryChanged);

    // Self connection
    QObject::connect(this,
                     &ApplicationControl::folderListChanged,
                     this,
                     &ApplicationControl::onFolderListChanged);
}

ApplicationControl::~ApplicationControl()
{
    if (mQuickView)
        mQuickView->deleteLater();
    if (mQuickComponent)
        mQuickComponent->deleteLater();
}

QStringList ApplicationControl::folderList() const
{
    return mFolderList;
}

void ApplicationControl::start(const QString& pMainQmlPath, QQmlApplicationEngine* pEngine, int pServerPort)
{
    if (!pEngine)
        return;

    mMainQmlPath = pMainQmlPath;
    mEngine = pEngine;

    mEngine->rootContext()->setContextProperty("appControl", this);

    // Server management
    mEngine->rootContext()->setContextProperty("serverControl", &mServerControl);

    connect(&mServerControl, &ServerControl::activeClientsChanged, [=]() {
        sendFolderToClients("");
        emit this->newConnection(); // TODO: uniformize who does what where
    });

    if (!mServerControl.startListening(pServerPort))
        qDebug() << "failed to start server on port " << pServerPort;

//    mQuickView = new QQuickView(mEngine, nullptr);
//    mQuickView->setIcon(QIcon(":/img/appIcon.png"));
//    mQuickView->setResizeMode(QQuickView::SizeRootObjectToView);
//    mQuickView->setSource(mMainQmlPath);
//    mQuickView->show();

    mQuickComponent = new QQmlComponent(mEngine, nullptr);
    mQuickComponent->loadUrl(mMainQmlPath);

    if (!mQuickComponent->create())
    {
        qDebug() << mQuickComponent->errorString();
    }
}

void ApplicationControl::onLogMessage(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    Q_UNUSED(type);
    QString file(context.file);

    if (QString(context.category) != "qml" || // This is a regular message
        file.startsWith("qrc:"))              // This is a message from the app's QML files
    {
        std::cout << msg.toStdString() << std::endl;
        return;
    }

    emit logMessage(msg, file, context.line);
}

int ApplicationControl::runCommand(const QString &pCommand)
{
    qDebug() << "Executing command " << pCommand;
    return QProcess::execute(pCommand);
}

int ApplicationControl::runCommandWithArgs(const QString &pCommand, const QStringList &pArgs)
{
    QStringList lArgs;
    for (const QString& iArg: pArgs)
    {
        if (iArg.contains(" "))
        {
            lArgs << "\"" + iArg + "\"";
        }
        else
        {
            lArgs << iArg;
        }
    }

    qDebug() << "Executing command " << pCommand << " with args " << lArgs;

    return QProcess::execute(pCommand, lArgs);
}

QStringList ApplicationControl::listFiles(const QString &pPath)
{
    qDebug() << "Looking up files in " << pPath;

    if (pPath.isEmpty())
        return QStringList();

    QString lActualPath = pPath;
    lActualPath.remove("file:///");

    QStringList lNameFilters = { "*.qml" };
    QStringList lFileList;

    QDirIterator it(lActualPath, lNameFilters, QDir::NoFilter, QDirIterator::Subdirectories);
    while (it.hasNext())
    {
        QString lPath = it.next();
        lPath = lPath.split(lActualPath).last();
//        lPath = lPath.startsWith("/") ? lPath.remove(0,1) : lPath; // TODO

        lFileList << lPath;
    }

    qDebug() << "returning filelist" << lFileList;
    return lFileList;
}

inline QString quoted(const QString& pToQuote) { return "\"" + pToQuote + "\""; }

void ApplicationControl::openFileExternally(const QString &pPath)
{
    QStringList lSrcPathFields = pPath.split("/");
    QStringList lDstPathFields;

    for (const QString& iSrcPathField: lSrcPathFields)
    {
        if (iSrcPathField.contains(" "))
        {
            lDstPathFields << quoted(iSrcPathField);
        }
        else
        {
            lDstPathFields << iSrcPathField;
        }
    }

    QString lCommandArg = pPath;// lDstPathFields.join("/");

    qDebug() << "Opening external file: " << lCommandArg;

    //QProcess::execute("cmd /c" + quoted("start %1").arg(lCommandArg));
    QProcess::execute("start", {lCommandArg});
}

bool ApplicationControl::createFolder(QString pPath, QString pFolderName)
{
    QString lPath = pPath.replace("file:///", "");
    QString lFilePath = lPath + "/" + pFolderName;

    QDir dir(lPath);
    if (!dir.mkpath(lFilePath))
    {
        qDebug() << "Failed to create folder " << lFilePath;
        return false;
    }
    return true;
}

bool ApplicationControl::createFile(QString pPath, QString pFileName)
{
    QString lPath = pPath.replace("file:///", "");

    QFile file(lPath + "/" + pFileName);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text))
    {
        QTextStream textStream(&file);
        textStream << newFileContent();
    }
    else
    {
        qDebug() << QString("Unable to create file \"%1\"").arg(lPath + "/" + pFileName);
        return false;
    }
    return true;
}

void ApplicationControl::addToFolderList(const QString &pFolderPath)
{
    if (mFolderList.contains(pFolderPath))
        return;

    mFolderList.append(pFolderPath);
    emit folderListChanged(mFolderList);
}

void ApplicationControl::removeFromFolderList(const QString &pFolderPath)
{
    if (!mFolderList.contains(pFolderPath))
        return;

    mFolderList.removeAll(pFolderPath);
    emit folderListChanged(mFolderList);
}

void ApplicationControl::requestClearQmlComponentCache()
{
    mEngine->clearComponentCache();
    mEngine->trimComponentCache();
}

QString ApplicationControl::readFileContents(const QString &pFilePath)
{
    QString filePath = pFilePath;
    filePath = filePath.replace("file:///", "");

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return QString();

    QTextStream stream(&file);
    return stream.readAll();
}

bool ApplicationControl::writeFileContents(const QString &pFilePath, const QString &pFileContents)
{
    QString filePath = pFilePath;
    filePath = filePath.replace("file:///", "");

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly))
        return false;

    QTextStream stream(&file);
    stream << pFileContents;

    return true;
}

void ApplicationControl::addContextProperty(const QString &pKey, QVariant pData)
{
    mEngine->rootContext()->setContextProperty(pKey, pData);
}

void ApplicationControl::sendFolderToClients(const QString &folder)
{
    QString message;
    QStringList fileList = this->listFiles(currentFolder());

    // Specify message type
    message += beginTag("messagetype") + "folderchange" + endTag("messagetype");

    // Add current folder
    message += beginTag("folder") + "\n" +
               currentFolder() +
               endTag("folder") + "\n";

    for (const QString& fileName: fileList)
    {
        if (!addFileToMessage(fileName, message))
        {
            qDebug() << "Could not add " << fileName << "to message";
            continue;
        }
    }

    // Specify current file
    message += beginTag("currentfile") + currentFile() + endTag("currentfile");

    mServerControl.sendToClients(message);
}

void ApplicationControl::sendFileToClients(const QString &file)
{
    QString message;

    // Specify message type
    message += beginTag("messagetype") + "filechange" + endTag("messagetype");

    if (!addFileToMessage(file, message))
    {
        qDebug() << "Could not add " << file << "to message";
        return;
    }

    // Specify current file
    message += beginTag("currentfile") + currentFile() + endTag("currentfile");

    mServerControl.sendToClients(message);
}

void ApplicationControl::sendDataMessage(const QString &data)
{
    QString message;

    // Specify message type
    message += beginTag("messagetype") + "data" + endTag("messagetype");

    // Add data content
    message += beginTag("json") + data + endTag("json");

    // Send
    mServerControl.sendToClients(message);
}

void ApplicationControl::setClipboardText(const QString &clipboard)
{
    QGuiApplication::clipboard()->setText(clipboard);
}

QString ApplicationControl::currentFile() const
{
    return m_currentFile;
}

QString ApplicationControl::currentFolder() const
{
    return m_currentFolder;
}

void ApplicationControl::setFolderList(QStringList folderList)
{
    if (mFolderList == folderList)
        return;

    mFolderList = folderList;

//    // internal handle folder list changed
//    QSet<QString> lAlreadyWatched = QSet<QString>::fromList(mFileWatcher.directories());
//    QSet<QString> lNewFolders = QSet<QString>::fromList(mFolderList).subtract(lAlreadyWatched);
//    for (QString iNewFolder: lNewFolders)
//    {
//        QString lFolderPath = iNewFolder.remove("file:///");
//    }



    emit folderListChanged(mFolderList);
}

void ApplicationControl::onFileChanged(const QString &pPath)
{
    qDebug() << "file changed " << pPath;

    mEngine->trimComponentCache();
    mEngine->clearComponentCache();

#if 0
//    mQuickView->hide();
    mQuickView->setSource(mMainQmlPath);
//    mQuickView->show();
#endif
    mFileWatcher.addPath(pPath); // BUG: sometimes file watcher remove paths once a signal has been emitted
    qDebug() << "Still watching files ---------------------------------";
    qDebug() << mFileWatcher.files();
    qDebug() << "------------------------------------------------------";

    emit fileChanged(pPath);

    // TODO: bug: when only one file is modified, this slot is not called
}

void ApplicationControl::onDirectoryChanged(const QString &pPath)
{
    qDebug() << "directory changed " << pPath;

    mEngine->trimComponentCache();
    mEngine->clearComponentCache();

    mFileWatcher.addPath(pPath); // BUG: sometimes file watcher remove paths once a signal has been emitted
    qDebug() << "Still watching directories ---------------------------";
    qDebug() << mFileWatcher.directories();
    qDebug() << "------------------------------------------------------";

    emit directoryChanged(pPath);

//    // Notify clients of any change
    sendFolderToClients("");
    // TODO BUG: this function seems to call itself recurisvely
//    // TODO: find a way to send only file by file
//    if (!mServerControl.isAvailable())
//        return;

//    QStringList fileList = this->listFiles(currentFolder());
//    for (const QString& file: fileList)
//        sendFileToClients(file);
}

void ApplicationControl::setCurrentFile(QString currentFile)
{
    if (m_currentFile == currentFile)
        return;

    m_currentFile = currentFile;
    emit currentFileChanged(m_currentFile);
}

void ApplicationControl::setCurrentFolder(QString currentFolder)
{
    if (m_currentFolder == currentFolder)
        return;

    m_currentFolder = currentFolder;
    emit currentFolderChanged(m_currentFolder);
}

void ApplicationControl::onFolderListChanged()
{
    mFileWatcher.removePaths(mFileWatcher.directories() + mFileWatcher.files());
    for (QString iNewFolder: mFolderList)
    {
        QString lFolderPath = iNewFolder.remove("file:///");
        setupWatchOnFolder(lFolderPath);
    }
}

void ApplicationControl::setupWatchOnFolder(const QString &pPath)
{
    qDebug() << "setting up watch on " << pPath;
    mFileWatcher.addPath(pPath);

    QDirIterator it(pPath, QStringList(), QDir::AllDirs | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
    QStringList lNestedFolderList;
    while (it.hasNext())
    {
        QString lPath = it.next();

        if (!it.fileInfo().isDir())
            continue;

        qDebug() << "Found nested folder " << lPath;
        lNestedFolderList << lPath;
    }
    mFileWatcher.addPaths(lNestedFolderList);

//    // Iterate over all qml files
//    QStringList lNameFilters = { "*.qml" };
//    QStringList lFileList;

//    QDirIterator it(pPath, lNameFilters, QDir::NoFilter, QDirIterator::Subdirectories);
//    while (it.hasNext())
//    {
//        QString lPath = it.next();
//        qDebug() << "adding watchee " << lPath;
//        lFileList << lPath;
//    }

//    if (!lFileList.isEmpty())
    //        mFileWatcher.addPaths(lFileList);
}

QString ApplicationControl::newFileContent()
{
    static QStringList newFileContent
            = QStringList() << "import QtQuick 2.0\n"
                            << "Item {"
                            << "    Text { "
                            << "        anchors.centerIn: parent"
                            << "        text: \"Not implemented yet\""
                            << "    }"
                            << "}";
    return newFileContent.join("\n");
}

bool ApplicationControl::addFileToMessage(const QString &path, QString &message)
{
    // Prep filepath
    QString filePath = currentFolder() + path;
    filePath = filePath.remove("file:///");

    // Attempt open file
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        qDebug() << "cannot open " << filePath;
        return false;
    }

    QTextStream textStream(&file);
    QString fileContent = textStream.readAll();

    // Generate header
    QString header = beginTag("file") +
                     file.fileName() +
                     endTag("file") + "\n";

    // Append content
    message += header +
               beginTag("content") + "\n" +
               fileContent + "\n" +
               endTag("content") + "\n";

    // Append file separator
    message += "\n";

    return true;
}
