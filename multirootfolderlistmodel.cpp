#include "multirootfolderlistmodel.h"

#include <QDebug>
#include <QQmlEngine>
#include <functional>

MultiRootFolderListModel::MultiRootFolderListModel(QObject *parent)
    : QAbstractListModel(parent)
{

}

void MultiRootFolderListModel::addFolder(QString folderPath)
{
    if (folderPath.startsWith("file:///"))
        folderPath.remove("file:///");

    if (!QDir().exists(folderPath))
        return;

    auto fsModel = new FsProxyModel(this);
    fsModel->setPath(folderPath);

    auto notify = [=](){
        qDebug() << "notify";
//        emit this->layoutChanged();
//        emit this->dataChanged(index(0), index(rowCount() - 1));
//        beginResetModel();
//        endResetModel();
    };

//    connect(fsModel, &FsProxyModel::dataChanged, notify);
    connect(fsModel, &FsProxyModel::layoutChanged, notify);
//    connect(fsModel, &FsProxyModel::sourceModelChanged, notify);
    connect(fsModel, &FsProxyModel::fileSystemChange, this, &MultiRootFolderListModel::updateNeeded);

    fsModel->setFilterText(m_filterText);
    connect(this, &MultiRootFolderListModel::filterTextChanged, fsModel, &FsProxyModel::setFilterText);
//    connect(fsModel, &FsProxyModel::filterTextChanged, [=](){
//        emit fsModel->layoutChanged();
//        emit this->layoutChanged();
//    });

    _appendFolderListModel(fsModel);
}

void MultiRootFolderListModel::removeFolder(QString folderPath)
{
    auto* flm = _findFolderListModel(folderPath);
    if (!flm)
        return;

    _removeFolderListModel(flm);
}

void MultiRootFolderListModel::clear()
{
    mFolderListModels.clear();
}

bool MultiRootFolderListModel::containsDir(QString pFolderPath)
{
    if (pFolderPath.startsWith("file:///"))
        pFolderPath.remove("file:///");

    for (auto& flmp: mFolderListModels)
    {
        if (pFolderPath.startsWith(flmp->root()->path(), Qt::CaseInsensitive))
            return true;
        /*
        if (flmp->containsDir(pFolderPath))
        {
            return true;
        }
        */
    }
    return false;
}

void MultiRootFolderListModel::expandAll()
{
    for (auto&& flm: mFolderListModels)
    {
        flm->expandAll();
    }
}

void MultiRootFolderListModel::collapseAll()
{
    for (auto&& flm: mFolderListModels)
    {
        flm->collapseAll();
    }
}

int MultiRootFolderListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return mFolderListModels.size();
}

template<typename T>
bool isValidIndex(const T& container, int index)
{
    return index >= 0 &&
           index < container.size();
}

QVariant MultiRootFolderListModel::data(const QModelIndex &index, int role) const
{
    if ((!index.isValid()) ||
        (!isValidIndex(mFolderListModels, index.row())))
        return QVariant();


    auto flm = mFolderListModels.at(index.row());
    const FsEntry* root = flm->root();

    switch (role)
    {
    case FolderListModel::NameRole:
    {
        return QVariant(root->name());
    }
    case FolderListModel::PathRole:
    {
        return QVariant(root->path());
    }
    case FolderListModel::IsDirRole:
    {
        return QVariant(root->expandable());
    }
    case FolderListModel::EntriesRole:
    {
        return QVariant::fromValue(flm);
    }
    }

    return QVariant();
}

FsProxyModel *MultiRootFolderListModel::_findFolderListModel(QString folderPath)
{
    if (folderPath.startsWith("file:///"))
        folderPath.remove("file:///");

    for (auto* flm: mFolderListModels)
    {
        if (flm->root()->path() == folderPath)
        {
            return flm;
        }
    }
    return nullptr;
}

void MultiRootFolderListModel::_appendFolderListModel(FsProxyModel *flm)
{
//    QModelIndex modelIndex = this->index(rowCount(), 0);
//    emit layoutAboutToBeChanged(QList<QPersistentModelIndex>() << modelIndex);

    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    mFolderListModels.append(flm);
    endInsertRows();

//    emit layoutChanged(QList<QPersistentModelIndex>() << modelIndex);

    // hack?
//    _notify();
}

void MultiRootFolderListModel::_removeFolderListModel(FsProxyModel *flm)
{
    int index = mFolderListModels.indexOf(flm);
    if (index == -1)
        return;

    QModelIndex modelIndex = this->index(index, 0);
    emit layoutAboutToBeChanged(QList<QPersistentModelIndex>() << modelIndex);

    beginRemoveRows(QModelIndex(), index, index);
    mFolderListModels.removeAt(index);
    endRemoveRows();

    emit layoutChanged(QList<QPersistentModelIndex>() << modelIndex);

    // hack?
//    _notify();
}

void MultiRootFolderListModel::_notify()
{
//    emit this->layoutChanged();
    emit this->dataChanged(index(0),
                           index(rowCount() - 1));
}


//bool MultiRootFolderListModel::insertRows(int row, int count, const QModelIndex &parent)
//{
//    if (row == rowCount())
//    {
//        // append
//    }
//    else if (row == 0)
//    {
//        // prepend
//    }
//    else
//    {
//        // insert
//    }
//}


// ---------------------------------------------------------------
// FsEntry
// ---------------------------------------------------------------

FsEntry::FsEntry()
{

}

FsEntry::FsEntry(const FsEntry &other)
{
    setName(other.name());
    setPath(other.path());
    setParent(other.parent());
    setExpanded(other.expanded());
    setExpandable(other.expandable());
    children = other.children;
}

FsEntry::FsEntry(const QFileInfo &fileInfo, FsEntry *parent)
    : QObject(parent)
{
    assert(fileInfo.exists());

    setPath(fileInfo.absoluteFilePath());
    setName(fileInfo.fileName());
    setExpandable(fileInfo.isDir() || fileInfo.isSymLink());
    setExpanded(expandable()); // TODO: read from settings
    setParent(parent);

    qDebug() << "Creating entry for " << path();

    if (this->expandable())
    {
        QDir dir(fileInfo.absoluteFilePath());
        QFileInfoList subdirs = dir.entryInfoList({"*.qml"}, QDir::Files | QDir::AllDirs | QDir::NoDotAndDotDot); // no filter on dirs
        // TODO QDirIterator::subdirectories

        for (auto& subdir: subdirs)
        {
            this->children.append(new FsEntry(subdir, this));
        }
    }
}

int FsEntry::row() const
{
    if (!parent())
        return 0;
    return parent()->children.indexOf(const_cast<FsEntry*>(this));
}


// ---------------------------------------------------------------
// FsEntryModel Utils
// ---------------------------------------------------------------

inline bool recursiveMatch(FsEntry* root, QString val, int role = FsEntryModel::PathRole)
{
    if (!root)
        return false;

    QString entryVal;
    if (role == FsEntryModel::PathRole)
    {
        entryVal = root->path();
    }
    else if (role == FsEntryModel::NameRole)
    {
        entryVal = root->name();
    }

    if (entryVal.contains(val, Qt::CaseInsensitive))
        return true;
    else
    {
        for (auto&& c: root->children)
        {
            if (recursiveMatch(c, val, role))
                return true;
        }
    }
    return false;
}
inline void recursiveCallback(FsEntry* root, const std::function<void(FsEntry*)>& callback)
{
    if (!root)
        return;

    callback(root);

    for (auto&& c: root->children)
    {
        recursiveCallback(c, callback);
    }
}
inline bool fuzzymatch(QString str, QString filter)
{
    bool allFound = true;
    for (auto&& s: filter.split(" "))
    {
        allFound &= str.contains(s, Qt::CaseInsensitive);
    }
    return allFound;
}

inline void recursiveAddToWatcher(const FsEntry* root, QFileSystemWatcher& watcher)
{
    watcher.addPath(root->path());
    for (const FsEntry* c: root->children)
    {
        recursiveAddToWatcher(c, watcher);
    }
}

inline void recursiveFetchLeaves(QVector<FsEntry*> &leaves, FsEntry* root)
{
    if (!root)
        return;

    for (auto child: root->children)
    {
        if (child->expandable())
            recursiveFetchLeaves(leaves, child);
        else
            leaves.append(child);
    }
}

inline void setActiveHierarchy(FsEntry* leaf, bool active)
{
    if (!leaf)
        return;

    leaf->setActive(active);

    if (!active)
        return;

    auto parent = leaf->parent();
    while (parent)
    {
        parent->setActive(true);
        parent = parent->parent();
    }
}

// ---------------------------------------------------------------
// FsEntryModel
// ---------------------------------------------------------------

FsEntryModel::FsEntryModel(QObject *parent)
    : QAbstractItemModel(parent)
{
    mChangeTimer.setSingleShot(true);
    mChangeTimer.setInterval(16);

    auto handleFileSystemChange = [=]()
    {
        qDebug() << "file system change";
        loadEntries();
        emit this->fileSystemChange();

        // TODO: find only the relevant indexes
//        emit this->dataChanged(index(0), index(rowCount()));
//        emit this->layoutChanged();
//        beginResetModel();
//        endResetModel();
    };
    auto startChangeTimer = [=]()
    {
        // If the timer is already running, it will be stopped and restarted.
        mChangeTimer.start();
    };
    connect(&mChangeTimer, &QTimer::timeout, handleFileSystemChange);

    connect(&mWatcher, &QFileSystemWatcher::directoryChanged, startChangeTimer);
    connect(&mWatcher, &QFileSystemWatcher::fileChanged, startChangeTimer);
}

int FsEntryModel::roleFromString(QString roleName)
{
    auto rn = roleNames();
    QHashIterator<int, QByteArray> it(rn);
    while (it.hasNext())
    {
        it.next();
        if (it.value() == roleName)
            return it.key();
    }
    return -1;
}

QModelIndex FsEntryModel::index(int row, int column, const QModelIndex &parent) const
{
    if (!hasIndex(row, column, parent))
        return QModelIndex();

    FsEntry* parentItem;

    if (!parent.isValid())
    {
        return createIndex(0, 0, rootItem);
    }
    else
    {
        parentItem = static_cast<FsEntry*>(parent.internalPointer());
    }

    FsEntry *childItem = parentItem->children.at(row);
    if (childItem)
        return createIndex(row, column, childItem);
    return QModelIndex();
}

QModelIndex FsEntryModel::parent(const QModelIndex &child) const
{
    if (!child.isValid())
        return QModelIndex();

    FsEntry *childItem = static_cast<FsEntry*>(child.internalPointer());
    FsEntry *parentItem = childItem->parent();

    if (!parentItem)
        return QModelIndex();

    if (parentItem == rootItem)
    {
//        return QModelIndex();
        return createIndex(0,0, rootItem);
    }

    return createIndex(parentItem->row(), 0, parentItem);
}

int FsEntryModel::rowCount(const QModelIndex &parent) const
{
    FsEntry* parentItem;

    if (!parent.isValid())
    {
        parentItem = rootItem;
        return 1; // rootItem
    }
    else
    {
        parentItem = static_cast<FsEntry*>(parent.internalPointer());
    }

    return parentItem->children.size();
}

int FsEntryModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return 1;
}

QVariant FsEntryModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    FsEntry* fs = static_cast<FsEntry*>(index.internalPointer());
    if (!fs)
        return QVariant();

    switch (role)
    {
    case NameRole:
    {
        return fs->name();
    }
    case PathRole:
    {
        return fs->path();
    }
    case IsExpandableRole:
    {
        return fs->expandable();
    }
    case IsExpandedRole:
    {
        return fs->expanded();
    }
    case ChildrenRole:
    {
//        return QVariant::fromValue(fs->children);
        QVariantList list;
        for (auto&& c: fs->children)
            list.append(QVariant::fromValue(c));
        return list;
        //return QVariantList(fs->children);
    }
    case ChildrenCountRole:
    {
        return fs->children.length();
    }
    case EntryRole:
    {
//        QVariant v = QVariant::fromValue(fs);
        QQmlEngine::setObjectOwnership(fs, QQmlEngine::CppOwnership);
        return QVariant::fromValue(fs);
    }
    }

    return QVariant();
}

QString FsEntryModel::path() const
{
    return mPath;
}

void FsEntryModel::setPath(const QString &path)
{
    mPath = path;
    if (!mPath.isEmpty())
        loadEntries();
}

bool FsEntryModel::containsDir(const QString &path)
{
    if (path.isEmpty())
        return false;

    for (auto&& dir: mWatcher.directories())
    {
        if (dir.contains(path, Qt::CaseInsensitive))
            return true;
    }
    return false;
//    if (path.isEmpty() || !rootItem)
//        return false;

//    return recursiveMatch(rootItem, path, FsEntryModel::PathRole);
}

void FsEntryModel::expandAll()
{
    recursiveCallback(rootItem,
    [](FsEntry* entry) {
        if (entry->expandable())
            entry->setExpanded(true);
    });
}

void FsEntryModel::collapseAll()
{
    recursiveCallback(rootItem,
    [](FsEntry* entry) {
        if (entry->expandable())
            entry->setExpanded(false);
    });
}

void FsEntryModel::loadEntries()
{
    if (!mWatcher.directories().empty())
        mWatcher.removePaths(mWatcher.directories());
    if (!mWatcher.files().empty())
        mWatcher.removePaths(mWatcher.files());

    _loadEntries();

    recursiveAddToWatcher(rootItem, mWatcher);
}

void FsEntryModel::_loadEntries()
{
    beginResetModel();

    if (rootItem)
        rootItem->deleteLater();

    QFileInfo rootInfo(mPath);
    assert(rootInfo.exists());

    rootItem = new FsEntry(rootInfo);
    endResetModel();
}

FsEntry *FsEntryModel::root() const
{
    return rootItem;
}

// ---------------------------------------------------------------
// FsProxyModel
// ---------------------------------------------------------------

FsProxyModel::FsProxyModel(QObject *parent)
    : QSortFilterProxyModel (parent)
{
    setRecursiveFilteringEnabled(true);
}

FsProxyModel::~FsProxyModel(){}

QString FsProxyModel::path() const
{
    auto fsModel = qobject_cast<FsEntryModel*>(sourceModel());
    assert(fsModel);

    return fsModel->path();
}

void FsProxyModel::setPath(const QString &path)
{
    auto fsModel = qobject_cast<FsEntryModel*>(sourceModel());
    if (fsModel)
    {
        fsModel->setPath(path);
    }
    else
    {
        fsModel = new FsEntryModel(this);
        fsModel->setPath(path);

        connect(fsModel, &FsEntryModel::fileSystemChange, this, &FsProxyModel::fileSystemChange);
        connect(fsModel, &FsEntryModel::dataChanged, this, [=](){ fetchLeaves(); });

        /*
        connect(fsModel, &FsEntryModel::modelReset, [=]()
        {
            beginResetModel();
            invalidateFilter();
            endResetModel();

            emit this->dataChanged(index(0,0), index(rowCount(),0));
            emit this->layoutChanged();
        });
        */

        setSourceModel(fsModel);
        fetchLeaves();
    }
}

QString FsProxyModel::filterText() const
{
    return m_filterText;
}

void FsProxyModel::setFilterText(QString filterText)
{
    if (m_filterText == filterText)
        return;

    m_filterText = filterText;

//    beginResetModel();
//    layoutAboutToBeChanged();
//    invalidateFilter();
//    layoutChanged();
//    endResetModel();

//    recursiveCallback(root(), [&filterText](FsEntry* entry)
//    {
//        bool active = fuzzymatch(entry->name(), filterText);
//        entry->setActive();
////       entry->setActive(entry->name().contains(filterText(), Qt::CaseInsensitive));
//    });
    recursiveCallback(root(), [](FsEntry* entry) { entry->setActive(false); });
    for (auto entry: mLeaves)
    {
        bool active = fuzzymatch(entry->name(), filterText);
        setActiveHierarchy(entry, active);
    }

    emit filterTextChanged(m_filterText);
}

bool FsProxyModel::containsDir(const QString &path)
{
    auto fsModel = qobject_cast<FsEntryModel*>(sourceModel());
    return fsModel->containsDir(path);
}

FsEntry *FsProxyModel::root() const
{
    auto fsModel = qobject_cast<FsEntryModel*>(sourceModel());
    return fsModel->root();
}

int FsProxyModel::roleFromString(QString roleName)
{
    auto fsModel = qobject_cast<FsEntryModel*>(sourceModel());
    return fsModel->roleFromString(roleName);
}

void FsProxyModel::expandAll()
{
    auto fsModel = qobject_cast<FsEntryModel*>(sourceModel());
    fsModel->expandAll();
}

void FsProxyModel::collapseAll()
{
    auto fsModel = qobject_cast<FsEntryModel*>(sourceModel());
    fsModel->collapseAll();
}

void FsProxyModel::fetchLeaves()
{
    mLeaves.clear();
//    mLeaves.reserve(200);
    recursiveFetchLeaves(mLeaves, root());
}

//bool FsProxyModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
//{
//    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
//    if (!index.isValid())
//        return false;

//    FsEntry* entry = static_cast<FsEntry*>(index.internalPointer());
//    if (!entry)
//        return false;

//    if (entry->expandable())
//        return false;

//    return fuzzymatch(entry->name(), m_filterText);
//}
