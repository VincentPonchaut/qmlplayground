#include "applicationcontrol.h"

#include <QDebug>
#include <QQmlContext>
#include <QDirIterator>
#include <QProcess>
#include <QGuiApplication>
#include <QClipboard>
#include <QSettings>
#include <QDir>
#include <QQuickItem>
#include <QQmlProperty>
#include <QTemporaryFile>
#include <QGuiApplication>
#include <QScreen>
#include <QtConcurrent>
#include <private/qzipreader_p.h>
#include <private/qzipwriter_p.h>

#include <QStandardPaths>
#include <iostream>

inline QString beginTag(const QString& tag)
{
    return "<" + tag + ">";
}

inline QString endTag(const QString& tag)
{
    return "</" + tag + ">";
}


QByteArray zipFolder(QString folder, QString newFolderChangeMessage)
{
    qDebug() << "Hello from thread" << QThread::currentThread();

    // Ensure source content exists
    QString folderPath = folder;
    folderPath = folderPath.replace("file:///", "");
    QDir srcDir(folderPath);
    if (!srcDir.exists())
        return QByteArray();
    QString projectName = srcDir.dirName();

    // Prepare resulting file
    QString filePath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + QString("/qmlplayground_cache/%1.zip").arg(projectName);

    QFileInfo fileInfo(filePath);

    // Ensure resulting directory exists
    if (!QDir().mkpath(fileInfo.absolutePath()))
    {
        return QByteArray();
    }

    // Remove previous file if it exists
    if (fileInfo.exists() && !QFile::remove(filePath))
    {
        return QByteArray();
    }

    // Create the resulting file
    QFile file(filePath);
    if (!file.open(QIODevice::ReadWrite))
    {
        return QByteArray();
    }

    // zip the folder
    QZipWriter writer(&file);
    writer.setCreationPermissions(QFile::ReadOther | QFile::WriteOther | QFile::ExeOther);


    QStringList nameFilters;
    nameFilters << "*";

    QDirIterator it(folderPath, nameFilters, QDir::NoFilter, QDirIterator::Subdirectories);
    QStringList invalidEntries;
    invalidEntries << folderPath + "/."
                   << folderPath + "/..";
    while (it.hasNext())
    {
        QString itPath = it.next();
        if (it.fileInfo().isDir() ||
                invalidEntries.contains(itPath) ||
                itPath.endsWith("/.") || itPath.endsWith("/..") ||
                itPath.split(".").last() == "qmlc")
        {
            //            qDebug() << itPath << "is invalid";
            continue;
        }

        QFile f(itPath);
        if (!f.open(QIODevice::ReadOnly))
        {
            qDebug() << itPath << "could not be opened";
            continue;
        }

        // Add the file to the archive while respecting
        // the hierarchy
        QString itFilePath = it.fileInfo().filePath();
        QString itSubPath = itFilePath.remove(folderPath);
        if (itSubPath.startsWith("/"))
            itSubPath.remove(0, 1);

        writer.addFile(itSubPath, f.readAll());
        f.close();
    }
    writer.close();
    file.close();

    // Now we have the zip file, we have to send it to clients
    if (!file.open(QIODevice::ReadOnly))
        return QByteArray();

    //    QByteArray binaryMessage = file.readAll();
    //    mServerControl.sendByteArrayToClients(binaryMessage);

    // Prepare a datastream to compose the message
    QByteArray binaryMessage;
    QDataStream stream(&binaryMessage, QIODevice::WriteOnly);

    // Get relevant message parts
    QByteArray data = file.readAll();
    qint32 dataLength = data.length();

    // Write message, starting with project name and zip file byte length
    stream << projectName;
    stream << dataLength;
    stream << newFolderChangeMessage;
    binaryMessage.append(data);

    qDebug() << "Finished working in thread" << QThread::currentThread();
    return binaryMessage;
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

    connect(&mFutureWatcher, SIGNAL(finished()), this, SLOT(onZippedFolderReadyToSend));
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
//        sendFolderToClients("");
//        emit this->newConnection(); // TODO: uniformize who does what where

        sendZippedFolderToClients(this->currentFolder());
        // TODO: setCurrentFile from the directory
        sendFolderChangeMessage();
        emit this->newConnection();
    });

//    if (!mServerControl.startListening(pServerPort))
//        qDebug() << "failed to start server on port " << pServerPort;
    mServerControl.setServerPort(pServerPort);

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

    // BUG: when there is only one folder, QVariant mistakes it for a simple QString
    QSettings settings;
    QVariant folderList = settings.value("folderList");
    QStringList folderListAsList = folderList.value<QStringList>();
    setFolderList(folderListAsList);
}

void ApplicationControl::onLogMessage(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    QString file(context.file);
    QString category(context.category);

    // The message was generated by something from the author's qml files (not console.log)
    if (file.startsWith("file:///"))
    {
        switch (type)
        {
        case QtMsgType::QtWarningMsg:
        {
            emit warningMessage(msg, file, context.line);
            break;
    }
        default:
        {
            emit logMessage(msg, file, context.line);
            break;
        }
        }
    }

    // The message comes from the author's qml files (console.log)
    if (category == "qml" && !file.startsWith("qrc:"))
    {
    emit logMessage(msg, file, context.line);
        return;
}

    // Otherwise, print the message to debug
    std::cout << msg.toStdString() << std::endl;
}

int ApplicationControl::runCommand(const QString &pCommand)
{
    qDebug() << "Executing command " << pCommand;
    return QProcess::execute(pCommand);
}


int ApplicationControl::runAsyncCommand(const QString &pCommand)
{
    qDebug() << "Executing command " << pCommand;
    return QProcess::startDetached(pCommand);
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

QStringList ApplicationControl::listFiles(const QString &pPath, const QStringList& pNameFilters)
{
    QString lActualPath = pPath;
    lActualPath.remove("file:///");

    if (lActualPath.isEmpty() || lActualPath == "/" || !QDir(lActualPath).exists())
        return QStringList();

//    qDebug() << "Looking up files in " << lActualPath;

    QStringList lNameFilters = pNameFilters;
    QStringList lFileList;

    QDirIterator it(lActualPath, lNameFilters, QDir::NoFilter, QDirIterator::Subdirectories);
    while (it.hasNext())
    {
        QString lPath = it.next();
        lPath = lPath.split(lActualPath).last();
//        lPath = lPath.startsWith("/") ? lPath.remove(0,1) : lPath; // TODO

        lFileList << lPath;
    }

//    qDebug() << "returning filelist" << lFileList;
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

bool ApplicationControl::copyFile(QString pSrcPath, QString pDstPath)
{
    QString srcPath = pSrcPath.replace("file:///", "");
    QString dstPath = pDstPath.replace("file:///", "");

    return QFile::copy(srcPath, dstPath);
}

bool ApplicationControl::copyFeaturePack(QString pFeaturePackPrefix, QString pDstPath)
{
    QString dstPath = pDstPath.replace("file:///", "");

    if (!QDir::root().exists(dstPath))
    {
        QDir::root().mkpath(dstPath);
    }

    bool success = true;
    QStringList entries = QDir(":/" + pFeaturePackPrefix).entryList();
    foreach (const QString& file, entries)
    {
        qDebug() << "copying" << file << "to" << dstPath;
        QString srcFile = ":/" + pFeaturePackPrefix + "/" + file;
        QString dstFile = dstPath + "/" + file;

        success &= QFile::copy(srcFile, dstFile);
    }

    return success;
}

template<typename T>
void write(QFile& f, const T t)
{
  f.write((const char*)&t, sizeof(t));
}

bool savePixmapsToICO(const QList<QPixmap>& pixmaps, const QString& path)
{
  static_assert(sizeof(short) == 2, "short int is not 2 bytes");
  static_assert(sizeof(int) == 4, "int is not 4 bytes");

  QFile f(path);
  if (!f.open(QFile::OpenModeFlag::WriteOnly)) return false;

  // Header
  write<short>(f, 0);
  write<short>(f, 1);
  write<short>(f, pixmaps.count());

  // Compute size of individual images
  QList<int> images_size;
  for (int ii = 0; ii < pixmaps.count(); ++ii) {
    QTemporaryFile temp;
    temp.setAutoRemove(true);
    if (!temp.open()) return false;

    const auto& pixmap = pixmaps[ii];
    pixmap.save(&temp, "PNG");

    temp.close();

    images_size.push_back(QFileInfo(temp).size());
  }

  // Images directory
  constexpr unsigned int entry_size = sizeof(char) + sizeof(char) + sizeof(char) + sizeof(char) + sizeof(short) + sizeof(short) + sizeof(unsigned int) + sizeof(unsigned int);
  static_assert(entry_size == 16, "wrong entry size");

  unsigned int offset = 3 * sizeof(short) + pixmaps.count() * entry_size;
  for (int ii = 0; ii < pixmaps.count(); ++ii) {
    const auto& pixmap = pixmaps[ii];
//    if (pixmap.width() > 256 || pixmap.height() > 256) continue;

    write<char>(f, pixmap.width() == 256 ? 0 : pixmap.width());
    write<char>(f, pixmap.height() == 256 ? 0 : pixmap.height());
    write<char>(f, 0); // palette size
    write<char>(f, 0); // reserved
    write<short>(f, 1); // color planes
    write<short>(f, pixmap.depth()); // bits-per-pixel
    write<unsigned int>(f, images_size[ii]); // size of image in bytes
    write<unsigned int>(f, offset); // offset
    offset += images_size[ii];
  }

  for (int ii = 0; ii < pixmaps.count(); ++ii) {
    const auto& pixmap = pixmaps[ii];
//    if (pixmap.width() > 256 || pixmap.height() > 256) continue;
    pixmap.save(&f, "PNG");
  }

  return true;
}

bool ApplicationControl::saveImageAsIco(QString pSrcPath, QString pDstPath)
{
    QString srcPath = pSrcPath;
    srcPath = srcPath.replace("file:///", "");

    if (!QFile::exists(srcPath))
        return false;

    QString dstPath = pDstPath;
    dstPath = dstPath.replace("file:///", "");

    QPixmap pixmap(srcPath);
    QList<QPixmap> pixmapList;
    pixmapList << pixmap;

    return savePixmapsToICO(pixmapList, dstPath);
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
    Q_UNUSED(folder);

    QString message;

    // TODO: Handle non-text files
    QStringList nameFilters;
    nameFilters << "*.qml"
                << "*.js";

    QStringList fileList = this->listFiles(currentFolder(), nameFilters);

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

void ApplicationControl::sendZippedFolderToClients(const QString &folder)
{
//    // Ensure source content exists
//    QString folderPath = folder;
//    folderPath = folderPath.replace("file:///", "");
//    QDir srcDir(folderPath);
//    if (!srcDir.exists())
//        return;
//    QString projectName = srcDir.dirName();

//    // Prepare resulting file
//    QString filePath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + QString("/qmlplayground_cache/%1.zip").arg(projectName);

//    QFileInfo fileInfo(filePath);

//    // Ensure resulting directory exists
//    if (!QDir().mkpath(fileInfo.absolutePath()))
//    {
//        return;
//    }

//    // Remove previous file if it exists
//    if (fileInfo.exists() && !QFile::remove(filePath))
//    {
//        return;
//    }

//    // Create the resulting file
//    QFile file(filePath);
//    if (!file.open(QIODevice::ReadWrite))
//    {
//        return;
//    }

//    // zip the folder
//    QZipWriter writer(&file);
//    writer.setCreationPermissions(QFile::ReadOther | QFile::WriteOther | QFile::ExeOther);


//    QStringList nameFilters;
//    nameFilters << "*";

//    QDirIterator it(folderPath, nameFilters, QDir::NoFilter, QDirIterator::Subdirectories);
//    QStringList invalidEntries;
//    invalidEntries << folderPath + "/."
//                   << folderPath + "/..";
//    while (it.hasNext())
//    {
//        QString itPath = it.next();
//        if (it.fileInfo().isDir() ||
//            invalidEntries.contains(itPath) ||
//            itPath.endsWith("/.") || itPath.endsWith("/..") ||
//            itPath.split(".").last() == "qmlc")
//        {
////            qDebug() << itPath << "is invalid";
//            continue;
//        }

//        QFile f(itPath);
//        if (!f.open(QIODevice::ReadOnly))
//        {
//            qDebug() << itPath << "could not be opened";
//            continue;
//        }

//        // Add the file to the archive while respecting
//        // the hierarchy
//        QString itFilePath = it.fileInfo().filePath();
//        QString itSubPath = itFilePath.remove(folderPath);
//        if (itSubPath.startsWith("/"))
//            itSubPath.remove(0, 1);

//        writer.addFile(itSubPath, f.readAll());
//        f.close();
//    }
//    writer.close();
//    file.close();

//    // Now we have the zip file, we have to send it to clients
//    if (!file.open(QIODevice::ReadOnly))
//        return;

////    QByteArray binaryMessage = file.readAll();
////    mServerControl.sendByteArrayToClients(binaryMessage);

//    // Prepare a datastream to compose the message
//    QByteArray binaryMessage;
//    QDataStream stream(&binaryMessage, QIODevice::WriteOnly);

//    // Get relevant message parts
//    QByteArray data = file.readAll();
//    qint32 dataLength = data.length();

//    // Write message, starting with project name and zip file byte length
//    stream << projectName;
//    stream << dataLength;
//    stream << newFolderChangeMessage();
//    binaryMessage.append(data);

//    ZipTask* zipTask = new ZipTask();
//    zipTask->folder = folder;
//    zipTask->newFolderChangeMessage = newFolderChangeMessage();

//    connect(zipTask, &ZipTask::finished, [=](QByteArray result)
//    {
//        qDebug() << "sending bytearray";
//        mServerControl.sendByteArrayToClients(result);
//    });

//    QThreadPool::globalInstance()->start(zipTask);

    if (mFutureWatcher.isRunning())
        return;

    mFuture = QtConcurrent::run<QByteArray>(zipFolder, folder, newFolderChangeMessage());
    mFutureWatcher.setFuture(mFuture);

    // Send the message
//    mServerControl.sendByteArrayToClients(binaryMessage);

}

void ApplicationControl::sendFolderChangeMessage()
{
    QString message = newFolderChangeMessage();
    mServerControl.sendToClients(message);
}

void ApplicationControl::setClipboardText(const QString &clipboard)
{
    QGuiApplication::clipboard()->setText(clipboard);
}

bool ApplicationControl::exists(const QString &path)
{
    return QDir(path).exists() || QFile::exists(path);
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
//    qDebug() << "file changed " << pPath;

    mEngine->trimComponentCache();
    mEngine->clearComponentCache();

#if 0
//    mQuickView->hide();
    mQuickView->setSource(mMainQmlPath);
//    mQuickView->show();
#endif
    mFileWatcher.addPath(pPath); // BUG: sometimes file watcher remove paths once a signal has been emitted
//    qDebug() << "Still watching files ---------------------------------";
//    qDebug() << mFileWatcher.files();
//    qDebug() << "------------------------------------------------------";

    emit fileChanged(pPath);

    // TODO: bug: when only one file is modified, this slot is not called
}

void ApplicationControl::onDirectoryChanged(const QString &pPath)
{
//    qDebug() << "directory changed " << pPath;

    mEngine->trimComponentCache();
    mEngine->clearComponentCache();

    mFileWatcher.addPath(pPath); // BUG: sometimes file watcher remove paths once a signal has been emitted
//    qDebug() << "Still watching directories ---------------------------";
//    qDebug() << mFileWatcher.directories();
//    qDebug() << "------------------------------------------------------";

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

void ApplicationControl::onZippedFolderReadyToSend()
{
    if (mFuture.result().isNull())
        return;
    mServerControl.sendByteArrayToClients(mFuture.result());
}

void ApplicationControl::setupWatchOnFolder(const QString &pPath)
{
    qDebug() << "setting up watch on " << pPath;
    mFileWatcher.addPath(pPath);

    // Iterate over directories
    QDirIterator it(pPath, QStringList(), QDir::AllDirs | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
    QStringList lNestedFolderList;
    while (it.hasNext())
    {
        QString lPath = it.next();

        if (!it.fileInfo().isDir())
            continue;

//        qDebug() << "Found nested folder " << lPath;
        lNestedFolderList << lPath;
    }
    mFileWatcher.addPaths(lNestedFolderList);

    // Iterate over all qml files : because some editors do not delete/replace an edited file, it will not trigger a directory change
    // TODO: avoid having two signals fired for the same file
    QStringList lNameFilters = { "*.qml" };
    QStringList lFileList;

    QDirIterator it2(pPath, lNameFilters, QDir::NoFilter, QDirIterator::Subdirectories);
    while (it2.hasNext())
    {
        QString lPath = it2.next();
//        qDebug() << "adding watchee " << lPath;
        lFileList << lPath;
    }

    if (!lFileList.isEmpty())
        mFileWatcher.addPaths(lFileList);
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

QString ApplicationControl::newFolderChangeMessage()
{
    QString message;
    // Specify message type
    message += beginTag("messagetype") + "folderchange" + endTag("messagetype");

    // Add current folder
    message += beginTag("folder") + "\n" +
               currentFolder() +
               endTag("folder") + "\n";

    // Add files
    QStringList nameFilters;
    nameFilters << "*.qml"
                << "*.js";

    QStringList fileList = this->listFiles(currentFolder(), nameFilters);
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

    return message;
}

