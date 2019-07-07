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
//        emit this->updateNeeded();
        qDebug() << "rowcount is now " << rowCount();
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

FolderListModel::FolderListModel(const FolderListModel &other)
{
    mChangeNotifier.setInterval(100);
    mChangeNotifier.setSingleShot(true);

    connect(&mChangeNotifier, &QTimer::timeout, [=]()
    {
        // TODO: fire reload
        qDebug() << "model changed";
        loadEntries();
//        emit this->updateNeeded();
        qDebug() << "rowcount is now " << rowCount();
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

    setPath(other.mPath);
}

FolderListModel::~FolderListModel()
{

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
            bool ok = mWatcher.addPath(dir.absoluteFilePath());
            assert(ok);

            auto flm = new FolderListModelProxy(this);
            flm->setPath(directory);

            assert(mProxy);
            bool connexionsOk = true;

            connexionsOk &= (bool) connect(mProxy, &FolderListModelProxy::filterTextChanged,
                                           flm, &FolderListModelProxy::setFilterText);

            connexionsOk &= (bool) connect(flm, &FolderListModelProxy::dataChanged,
            [=](const QModelIndex &topLeft, const QModelIndex &bottomRight, const QVector<int> &roles)
            {
                Q_UNUSED(topLeft)
                Q_UNUSED(bottomRight)
                Q_UNUSED(roles)

                for (auto& entry: mEntries)
                {
                    if (entry == flm->root())
                    {
                        emit this->dataChanged(index(mEntries.indexOf(entry)), index(rowCount()));
                    }
                }
            });
            assert(connexionsOk);

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

FolderListModelProxy *FolderListModel::proxy() const
{
    return mProxy;
}

void FolderListModel::setProxy(FolderListModelProxy *proxy)
{
    mProxy = proxy;
}

const QFileInfo &FolderListModel::root() const
{
    return mRoot;
}

FolderListModelProxy::FolderListModelProxy(QObject *parent)
    : QSortFilterProxyModel (parent)
{
    connect(this, &FolderListModelProxy::filterTextChanged, [=]()
    {
        invalidateFilter();
    });
}

FolderListModel *FolderListModelProxy::folderListModel() const
{
    return mFolderListModel;
}

void FolderListModelProxy::setFolderListModel(FolderListModel *folderListModel)
{
    mFolderListModel = folderListModel;

    if (mFolderListModel)
    {
        // Forward the signals
        connect(mFolderListModel, &FolderListModel::updateNeeded, this, &FolderListModelProxy::updateNeeded);

        // Set as source model
        setSourceModel(mFolderListModel);
    }
}

void FolderListModelProxy::setPath(QString path)
{
    // Create a new folder list model
    if (mFolderListModel)
        mFolderListModel->deleteLater();

    auto flm = new FolderListModel();
    flm->setProxy(this);
    flm->setPath(path);

    setFolderListModel(flm);
}

const QFileInfo &FolderListModelProxy::root() const
{
    return mFolderListModel->root();
}

inline bool fastSearch(QString searchString, QString contentString, bool caseSensitive = false)
{
    if (!caseSensitive)
    {
        searchString = searchString.toLower();
        contentString = contentString.toLower();
    }
    return contentString.contains(searchString);
}

bool FolderListModelProxy::containsDir(QString pFolderPath)
{
    return _containsDir(mFolderListModel, pFolderPath);
}

bool FolderListModelProxy::_containsDir(FolderListModel *flm, QString pFolderPath)
{
    for (int i = 0; i < flm->rowCount(); ++i)
    {
        QModelIndex index = flm->index(i);

        bool isDir = flm->data(index, FolderListModel::IsDirRole).toBool();
        if (isDir)
        {
            QString path = flm->data(index, FolderListModel::PathRole).toString();
            if (fastSearch(pFolderPath, path))
                return true;

            FolderListModelProxy* ffp = flm->data(index, FolderListModel::EntriesRole).value<FolderListModelProxy*>();
            FolderListModel* ff = qobject_cast<FolderListModel*>(ffp->sourceModel());
            if (_containsDir(ff, pFolderPath))
                return true;
        }
    }
    return false;
}

inline bool fuzzy_match(const char* pattern, const char* str)
{
    while (*pattern != '\0' && *str != '\0')
    {
        if (tolower(*pattern) == tolower(*str))
            ++pattern;
        ++str;
    }

    return (*pattern == '\0');
}

inline bool fuzzySearch(QString needle, QString haystack, bool caseSensitive = false)
{
    if (!caseSensitive)
    {
        needle = needle.toLower();
        haystack = haystack.toLower();
    }

    bool allFound = true;
    for (auto&& n : needle.split(" "))
    {
        allFound &= haystack.contains(n);
    }

    return allFound;
}

bool FolderListModelProxy::fuzzyLookUp(FolderListModel* root, QString filterText) const
{
    for (int i = 0; i < root->rowCount(); ++i)
    {
        QModelIndex index = root->index(i);

        QString name = root->data(index, FolderListModel::NameRole).toString();
        if (fuzzySearch(filterText, name))
            return true;

        bool isDir = root->data(index, FolderListModel::IsDirRole).toBool();
        if (isDir)
        {
//            FolderListModel* ff = root->data(index, FolderListModel::EntriesRole).value<FolderListModel*>();
            FolderListModelProxy* ffp = root->data(index, FolderListModel::EntriesRole).value<FolderListModelProxy*>();
            FolderListModel* ff = qobject_cast<FolderListModel*>(ffp->sourceModel());
            if (fuzzyLookUp(ff, filterText))
                return true;
        }
    }
    return false;
}

bool FolderListModelProxy::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    // If there is no filter, accept all rows
    if (m_filterText.isEmpty())
        return true;

    // Retrieve underlying data
    QModelIndex sourceIndex = mFolderListModel->index(source_row, 0, source_parent);
    if (!sourceIndex.isValid())
        return false;

    // if path itself contains the text, accept the row
    QString entryName = mFolderListModel->root().absoluteFilePath();
    QString name = mFolderListModel->data(sourceIndex, FolderListModel::NameRole).toString();
    if (fuzzySearch(m_filterText, name))
        return true;

    bool isDir = mFolderListModel->data(sourceIndex, FolderListModel::IsDirRole).toBool();
    if (isDir)
    {
        FolderListModelProxy* ffp = mFolderListModel->data(sourceIndex, FolderListModel::EntriesRole).value<FolderListModelProxy*>();
        FolderListModel* ff = qobject_cast<FolderListModel*>(ffp->sourceModel());
        if (fuzzyLookUp(ff, m_filterText))
            return true;
    }

    return false;
}
