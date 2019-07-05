#include "folderlistmodel.h"

#include <QDebug>

FolderListModel::FolderListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    mChangeNotifier.setInterval(100);
    mChangeNotifier.setSingleShot(true);

    connect(&mChangeNotifier, &QTimer::timeout, [=]()
    {
        // TODO: fire reload
        qDebug() << "model changed";
        loadEntries();
    });

    connect(&mWatcher, &QFileSystemWatcher::directoryChanged, [=](QString dirName)
    {
        // TODO: find index from directory name
        // To avoid reloading the full model
        mChangeNotifier.start();
    });
    connect(&mWatcher, &QFileSystemWatcher::fileChanged, [=](QString fileName)
    {
        // TODO: find index from file name
        // To avoid reloading the full model
        mChangeNotifier.start();
    });
}

QHash<int, QByteArray> FolderListModel::roleNames() const
{
    QHash<int, QByteArray> result;
    result.insert(NameRole, "name");
    result.insert(PathRole, "path");
    result.insert(IsDirRole, "isDir");
    result.insert(EntriesRole, "entries");
    return result;
}

int FolderListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return mEntries.length();
}

QVariant FolderListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= mEntries.size() || index.row() < 0)
        return QVariant();

    const QFileInfo& ref = mEntries.at(index.row());
    assert(ref.exists());

    switch (role)
    {
    case NameRole:
    {
        return QVariant(ref.fileName());
    }
    case PathRole:
    {
        return QVariant(ref.filePath());
    }
    case IsDirRole:
    {
        return QVariant(ref.isDir());
    }
    case EntriesRole:
    {
        for (auto& flm: mFolderListModels)
        {
            if (flm->root() == ref)
            {
                return QVariant::fromValue(flm);
            }
        }
    }
    }

    return QVariant();
}

void FolderListModel::setPath(QString path)
{
    path = path.remove("file:///");
    assert(QDir().exists(path));

    if (!mPath.isNull() && !mPath.isEmpty())
    {
        mWatcher.removePath(mPath);
        mWatcher.removePaths(mWatcher.directories());
    }
    mPath = path;
    mRoot = QFileInfo(mPath);
    if (!mPath.isNull() && !mPath.isEmpty())
        mWatcher.addPath(path);

    loadEntries();
}

void FolderListModel::loadEntries()
{
    mEntries.clear();
    QDirIterator dirit(mPath,
                       QStringList() << "*.qml",
                       QDir::NoFilter,
                       QDirIterator::Subdirectories);

    mEntries.reserve(50);

    // Prepare a list of directories
    QSet<QString> directories;
    while (dirit.hasNext())
    {
        dirit.next();
//        qDebug() << dirit.fileInfo();
        directories.insert(dirit.fileInfo().absolutePath());
    }

    // Insert the directories in entries
    mFolderListModels.clear();
    for (auto directory: directories)
    {
        QFileInfo dir(directory);
        assert(dir.isDir());

        if (dir.path() == mPath)
        {
            mEntries.append(dir);
            mWatcher.addPath(dir.absoluteFilePath());

            FolderListModel* flm = new FolderListModel(this);
            flm->setPath(directory);
            connect(flm, &FolderListModel::dataChanged,
            [=](const QModelIndex &topLeft, const QModelIndex &bottomRight, const QVector<int> &roles)
            {
                for (auto& entry: mEntries)
                {
                    if (entry == flm->root())
                    {
                        emit this->dataChanged(index(mEntries.indexOf(entry)), index(rowCount()));
                    }
                }
            });

            mFolderListModels.append(flm);
        }
    }

    // Files
    QDirIterator it(mPath,
                    QStringList() << "*.qml",
                    QDir::NoFilter,
//                    QDirIterator::Subdirectories
                    QDirIterator::FollowSymlinks
                    );

    while (it.hasNext())
    {
        it.next();

        mEntries.append(it.fileInfo());
        mWatcher.addPath(it.filePath());
    }

    emit dataChanged(index(0,0),
                     index(rowCount() - 1, 0));
}

const QFileInfo &FolderListModel::root() const
{
    return mRoot;
}
