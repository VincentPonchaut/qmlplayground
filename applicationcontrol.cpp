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
#include <QPrinter>
#include <private/qzipreader_p.h>
#include <private/qzipwriter_p.h>

#include <QStandardPaths>
#include <QMutexLocker>
#include <iostream>
#include <QDesktopServices>
#include <QPrintDialog>
#include <QPainter>
#include <QFileDialog>

// --------------------------------------------------------------------------------

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

// --------------------------------------------------------------------------------

ApplicationControl::ApplicationControl(QObject *parent) : QObject(parent)
{
    // Prepare the file system model
    m_folderModel = new MultiRootFolderListModel(this);
    connect(m_folderModel, &MultiRootFolderListModel::updateNeeded,
    [=](){
        emit folderModelChanged(m_folderModel);
        onNeedToReloadQml();
    });


    // When the current folder changes, notify all clients if any
    connect(this,
            &ApplicationControl::currentFolderChanged,
            this,
            &ApplicationControl::sendZippedFolderToClients);

    // Zip task: when thread finished zipping assets, send them to clients
    bool ok = connect(&mFutureWatcher,
                      SIGNAL(finished()),
                      this,
                      SLOT(onZippedFolderReadyToSend()));
    assert(ok);

    connect(m_folderModel, &MultiRootFolderListModel::dataChanged, [this]()
    {
        emit this->folderModelChanged(m_folderModel);
    });
}

ApplicationControl::~ApplicationControl()
{
    if (mQuickComponent)
        mQuickComponent->deleteLater();

    mWatcherThread.quit();
    mWatcherThread.wait();

    QSettings settings;
    settings.setValue("currentFile", currentFile());
    settings.setValue("currentFolder", currentFolder());
    settings.setValue("folderList", folderList());
}

inline QString dpiCategory(qreal pDp)
{
    return pDp < 120 ? "ldpi"    :
           pDp < 160 ? "mdpi"    :
           pDp < 213 ? "tvdpi"   :
           pDp < 240 ? "hdpi"    :
           pDp < 320 ? "xhdpi"   :
           pDp < 480 ? "xxhdpi"  :
           pDp < 640 ? "xxxhdpi" :
                       "nodpi"   ;
}
inline qreal dpiPixelRatio(QString pCategory)
{
    return pCategory == "ldpi"    ? 0.75 :
           pCategory == "mdpi"    ? 1.00 :
           pCategory == "tvdpi"   ? 1.33 :
           pCategory == "hdpi"    ? 1.50 :
           pCategory == "xhdpi"   ? 2.00 :
           pCategory == "xxhdpi"  ? 3.00 :
           pCategory == "xxxhdpi" ? 4.00 :
                                    1.00 ;
}
inline void addDpiInfoToQmlContext(QQmlContext* pContext)
{
    qreal xDpi = QGuiApplication::primaryScreen()->physicalDotsPerInchX() * QGuiApplication::primaryScreen()->devicePixelRatio();
    qreal yDpi = QGuiApplication::primaryScreen()->physicalDotsPerInchY() * QGuiApplication::primaryScreen()->devicePixelRatio();
    qreal lDpi = QGuiApplication::primaryScreen()->physicalDotsPerInch()  * QGuiApplication::primaryScreen()->devicePixelRatio();

    pContext->setContextProperty(QStringLiteral("mmX"), xDpi / 25.4);
    pContext->setContextProperty(QStringLiteral("mmY"), yDpi / 25.4);
    pContext->setContextProperty(QStringLiteral("mm"),  lDpi / 25.4);

    pContext->setContextProperty(QStringLiteral("cmX"), xDpi * 10.0 / 25.4);
    pContext->setContextProperty(QStringLiteral("cmY"), yDpi * 10.0 / 25.4);
    pContext->setContextProperty(QStringLiteral("cm"),  lDpi * 10.0 / 25.4);

    QString lCategory = dpiCategory(lDpi);
    qreal lPixelRatio = dpiPixelRatio(lCategory);
    pContext->setContextProperty(QStringLiteral("dp"), lPixelRatio);
}

void ApplicationControl::start(const QString& pMainQmlPath, QQmlApplicationEngine* pEngine, int pServerPort)
{
    if (!pEngine)
        return;

    mMainQmlPath = pMainQmlPath;
    mEngine = pEngine;

    mEngine->rootContext()->setContextProperty("appControl", this);

    // DPI Management
    addDpiInfoToQmlContext(mEngine->rootContext());

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

    mQuickRootObject = mQuickComponent->create();
    if (!mQuickRootObject)
    {
        qDebug() << mQuickComponent->errorString();
    }

    // BUG: when there is only one folder, QVariant mistakes it for a simple QString
    QSettings settings;
    QVariant folderList = settings.value("folderList");
    QStringList folderListAsList = folderList.value<QStringList>();
    setFolderList(folderListAsList);

    // BUG: bindings are not resolved at initialization
    QString currentFolder = settings.value("currentFolder").value<QString>();
    if (!currentFolder.isEmpty())
        setCurrentFolder(currentFolder);
    QString currentFile = settings.value("currentFile").value<QString>();
    if (!currentFile.isEmpty())
        setCurrentFile(currentFile);
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

void ApplicationControl::openFileExternally(QString pPath)
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

//    QString lCommandArg = QString(pPath).replace("file:///", "");// lDstPathFields.join("/");


    //QProcess::execute("cmd /c" + quoted("start %1").arg(lCommandArg));
//    QProcess::execute("start", {lCommandArg});
    qDebug() << "Opening external file: " << QUrl::fromLocalFile(pPath);
    QDesktopServices::openUrl(QUrl::fromLocalFile(pPath));
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

void ApplicationControl::addToFolderList(QString pFolderPath)
{
    if (!pFolderPath.startsWith("file:///"))
        pFolderPath = "file:///" + pFolderPath;

    if (m_folderList.contains(pFolderPath))
        return;

    m_folderList.append(pFolderPath);
    m_folderModel->addFolder(pFolderPath);

    emit folderListChanged(m_folderList);
}

void ApplicationControl::removeFromFolderList(QString pFolderPath)
{
    if (!pFolderPath.startsWith("file:///"))
        pFolderPath = "file:///" + pFolderPath;

    if (!m_folderList.contains(pFolderPath))
        return;

    m_folderList.removeAll(pFolderPath);
    m_folderModel->removeFolder(pFolderPath);

    emit folderListChanged(m_folderList);
}

bool ApplicationControl::isInFolderList(QString pFolderPath)
{
    return m_folderList.contains(pFolderPath) ||
            m_folderList.contains("file:///" + pFolderPath);
}

bool ApplicationControl::isAlreadyWatched(QString pFolderPath)
{
    return m_folderModel->containsDir(pFolderPath);
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
    if (!mServerControl.isAvailable() ||
         mServerControl.activeClients() == 0)
        return;

    qDebug() << "sendFolderToClients" << QThread::currentThread();
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
    if (!mServerControl.isAvailable() ||
         mServerControl.activeClients() == 0)
        return;

    qDebug() << "sendFileToClients" << QThread::currentThread();
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
    if (!mServerControl.isAvailable() ||
         mServerControl.activeClients() == 0)
        return;

    qDebug() << "sendDataMessage" << QThread::currentThread();
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
    if (!mServerControl.isAvailable() ||
         mServerControl.activeClients() == 0)
        return;

    if (mFutureWatcher.isRunning())
        return;

    assert(folder == currentFolder());

    qDebug() << "sendZippedFolderToClients" << QThread::currentThread();
    mFuture = QtConcurrent::run<QByteArray>(zipFolder, folder, newFolderChangeMessage());
    mFutureWatcher.setFuture(mFuture);
}

void ApplicationControl::sendFolderChangeMessage()
{
    if (!mServerControl.isAvailable() ||
         mServerControl.activeClients() == 0)
        return;

    qDebug() << "sendFolderChangeMessage" << QThread::currentThread();
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
//    mFileWatcher.addPath(pPath); // BUG: sometimes file watcher remove paths once a signal has been emitted
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

//    mFileWatcher.addPath(pPath); // BUG: sometimes file watcher remove paths once a signal has been emitted
//    qDebug() << "Still watching directories ---------------------------";
//    qDebug() << mFileWatcher.directories();
//    qDebug() << "------------------------------------------------------";

//    emit directoryChanged(pPath);

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

void ApplicationControl::setFolderList(QStringList folderList)
{
    if (m_folderList == folderList)
        return;

    m_folderModel->clear();
    for (auto& folder: folderList)
    {
        addToFolderList(folder);
    }

    emit folderListChanged(m_folderList);
}


void ApplicationControl::onZippedFolderReadyToSend()
{
    if (mFuture.result().isNull())
        return;
    qDebug() << "onZippedFolderReadyToSend" << QThread::currentThread();
    mServerControl.sendByteArrayToClients(mFuture.result());
}

void ApplicationControl::onNeedToReloadQml()
{
    QMutexLocker lock(&mMutex);
    qDebug() << "needToReloadQml received" << QThread::currentThread();

    // refresh visual elements
    requestClearQmlComponentCache();
    emit this->reloadRequest();

    // notify clients
    sendFolderToClients("");
}

void ApplicationControl::onNeedToReloadAssets()
{
    QMutexLocker lock(&mMutex);
//    qDebug() << "needToReloadAssets received in " << QThread::currentThread() << "from object" << worker << "that is in " << worker->thread();

    // refresh visual elements
    requestClearQmlComponentCache();
    emit this->reloadRequest();

    // notify clienst
    sendZippedFolderToClients(m_currentFolder);
}


#if 0
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
#endif

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

QObject *ApplicationControl::quickRootObject() const
{
    return mQuickRootObject;
}

bool ApplicationControl::printToA4(QUrl pImage, double pSizeCm)
{
    QString filePath = pImage.toString();
    filePath = filePath.contains("file:///") ? filePath.remove("file:///") :
                                               filePath;
    QFileInfo fileInfo(filePath);

    if (!fileInfo.exists())
        return false;

    QPrinter printer;
    printer.setPageSize(QPrinter::A4);
    QRectF paperRectPx = printer.paperRect(QPrinter::DevicePixel);
    QRectF paperRectMm = printer.paperRect(QPrinter::Millimeter);
    double fPxToMM = paperRectMm.width() / paperRectPx.width();
    int imgWidthPx = 10.0 * pSizeCm / fPxToMM;

    QImage img(fileInfo.absoluteFilePath());
    img = img.scaledToWidth(imgWidthPx);

    QPrintDialog *dlg = new QPrintDialog(&printer,0);
    if(dlg->exec() == QDialog::Accepted)
    {
        QPainter painter(&printer);


        //painter.setCompositionMode(QPainter::CompositionMode_SourceIn);
        painter.drawImage(QPoint(0,0),img);
        printer.setFullPage(true);
        painter.end();
    }

    return true;
}

bool ApplicationControl::addToPrintQueue(QUrl pImage, double pSizeCm, QString pLabel)
{
    PrintEntry p;
    p.url = pImage;
    p.sizeCm = QSizeF(pSizeCm, pSizeCm);
    p.label = pLabel;

    printEntries.append(p);
    return true;
}

bool ApplicationControl::removeFromPrintQueue(QUrl pImage)
{
    for (int i = 0; i < printEntries.length(); ++i)
    {
        if (printEntries.at(i).url == pImage)
        {
            printEntries.removeAt(i);
            return true;
        }
    }
    return false;
}

bool ApplicationControl::printAllFromPrintQueue(bool pdf)
{
    QPrinter printer;
    printer.setPageSize(QPrinter::A4);

    QString pathToOpenAfterExport;

    QRectF paperRectPx = printer.paperRect(QPrinter::DevicePixel);
    QRectF paperRectMm = printer.paperRect(QPrinter::Millimeter);
    double fPxToMM = paperRectMm.width() / paperRectPx.width();
//    int imgWidthPx = 10.0 * pSizeCm / fPxToMM;

//    QImage img(fileInfo.absoluteFilePath());
//    img = img.scaledToWidth(imgWidthPx);

    if (pdf)
    {
        printer.setOutputFormat(QPrinter::PdfFormat);
//        printer.setResolution(QPrinter::HighResolution);

        QString fileName = QFileDialog::getSaveFileName(nullptr, "Export PDF", QString(), "*.pdf");
        if (QFileInfo(fileName).suffix().isEmpty()) { fileName.append(".pdf"); }

        QFile file(fileName);
        if (!file.remove())
        {
            qDebug() << "Could not remove file: " << fileName;
            return false;
        }

        printer.setOutputFileName(fileName);
        pathToOpenAfterExport = fileName;
    }
    else
    {
        QPrintDialog *dlg = new QPrintDialog(&printer, nullptr);
        if (dlg->exec() != QDialog::Accepted)
            return false;
    }

    QPainter painter(&printer);
    QPoint drawPos(0,0);


    int pages = 0;
    for (auto&& printEntry: printEntries)
    {
        QString filePath = printEntry.url.toString();
        filePath = filePath.contains("file:///") ? filePath.remove("file:///") :
                                                   filePath;

        // Get file
        QFileInfo fileInfo(filePath);
        if (!fileInfo.exists())
        {
            qDebug() << "file does not exist " << filePath;
            continue;
        }

        // Resize
        QImage img(filePath);
        int imgWidth = (10.0 * printEntry.sizeCm.width()) / fPxToMM;
        img = img.scaledToWidth(imgWidth);

        // If it fits, print
        int nextContentWidth = img.width() + (printEntry.label.isEmpty() ? 0 : 2.0 * painter.fontMetrics().boundingRect(printEntry.label).width());
        int nextContentHeight = img.height() + (printEntry.label.isEmpty() ? 0 : 2.0 * painter.fontMetrics().height());

//        int remainingWidth =  paperRectPx.width() - drawPos.x();
//        if (nextContentWidth > remainingWidth)
//        {
//            // newline
//            drawPos.setX(0);
//            drawPos.setY(nextContentHeight);
//        }

        int remainingHeight = paperRectPx.height() - drawPos.y();
        if (nextContentHeight > remainingHeight)
        {
            printer.newPage();
            pages++;
            drawPos.setX(0);
            drawPos.setY(0);
        }

        painter.drawImage(drawPos, img);
//        int yBeforeImgDraw = drawPos.y();
        drawPos.setY(drawPos.y() + img.height() + painter.fontMetrics().height());

        if (!printEntry.label.isEmpty()) {
            painter.drawText(drawPos, printEntry.label + " " + QString::number(printEntry.sizeCm.width()) + "cm");
            drawPos.setY(drawPos.y() + painter.fontMetrics().height());
        }
//        drawPos.setX(drawPos.x() + nextContentWidth);
//        drawPos.setY(yBeforeImgDraw);

    }

    printer.setFullPage(true);
    painter.end();

    if (!pathToOpenAfterExport.isEmpty())
    {
        QDesktopServices::openUrl(QUrl(pathToOpenAfterExport));
    }

    return true;
}

void ApplicationControl::clearPrintQueue()
{
    printEntries.clear();
}

void ApplicationControl::setCurrentFileAndFolder(QString folder, QString file)
{
    bool emitFolder = false;
    bool emitFile = false;

    if (folder != m_currentFolder)
    {
        m_currentFolder = folder;
        emitFolder = true;
    }
    if (file != m_currentFile)
    {
        m_currentFile = file;
        emitFile = true;
    }

    // Folder takes priority
    if (emitFolder)
    {
        emit currentFolderChanged(m_currentFolder);
        emit reloadRequest();
    }
    /*else*/ if (emitFile)
        emit currentFileChanged(m_currentFile);
}

QStringList ApplicationControl::folderList() const
{
    return m_folderList;
}

void FileSystemWatcher::doWork()
{
    qDebug() << "\ndowork starts";

    forever
    {
        mMutex.lock();
        if (mNeedRefresh)
        {
            listFiles(mWatchedDirectory);
            mNeedRefresh = false;
        }
        mMutex.unlock();

//        auto before = QDateTime::currentMSecsSinceEpoch();
//        qDebug() << "starting work in " << mWatchedDirectory;
//        if (QThread::currentThread()->isInterruptionRequested())
//        {
//            qDebug() << "interruption request received.";
//            return;
//        }

        bool qmlJsModified = false;
        bool assetsModified = false;

        for (auto&& qmlJsFile: mQmlJsFiles)
        {
            QFileInfo newFileInfo(qmlJsFile.absoluteFilePath());
            if (mFileTimes[qmlJsFile.absoluteFilePath()] < newFileInfo.lastModified())
            {
                qmlJsModified = true;
                mFileTimes[qmlJsFile.absoluteFilePath()] = newFileInfo.lastModified();
            }
        }
        for (auto&& assetFile: mAssets)
        {
            QFileInfo newFileInfo(assetFile.absoluteFilePath());
            if (mFileTimes[assetFile.absoluteFilePath()] < newFileInfo.lastModified())
            {
                assetsModified = true;
                mFileTimes[assetFile.absoluteFilePath()] = newFileInfo.lastModified();
            }
        }

        if (assetsModified)
        {
            emit this->needToReloadAssets();
        }
        else if (qmlJsModified)
        {
            emit this->needToReloadQml();
        }

//        auto after = QDateTime::currentMSecsSinceEpoch();
//        qDebug() << "finished work in " << mWatchedDirectory << "elapsed:" << (after - before) << "ms";

        QThread::msleep(16);
    }
}

void FileSystemWatcher::setWatchedDirectory(const QString &pDirectory)
{
    QMutexLocker lock(&mMutex);

    if (mWatchedDirectory == pDirectory)
        return;

    mWatchedDirectory = pDirectory;
    mNeedRefresh = true;
}

void FileSystemWatcher::listFiles(QString path)
{
    QString actualPath = path;
    actualPath.remove("file:///");

    if (actualPath.isEmpty() || actualPath == "/" || !QDir(actualPath).exists())
        return;

    mQmlJsFiles.clear();
    mAssets.clear();

    QStringList nameFilters;
    nameFilters << "*";

    QStringList result;

    QDirIterator it(actualPath, nameFilters, QDir::NoFilter, QDirIterator::Subdirectories);
    while (it.hasNext())
    {
        it.next();
        QFileInfo fi = it.fileInfo();
        QString ext = fi.suffix().toLower();

        if (ext == "qmlc")
        {
            continue;
        }
        else if (ext == "qml" || ext == "js")
        {
            mQmlJsFiles << fi;
        }
        else
        {
            mAssets << fi;
        }
        // Store the filetime
        mFileTimes[fi.absoluteFilePath()] = fi.lastModified();
    }
}
