#include "multirootfolderlistmodel.h"

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

    FolderListModel* flm = new FolderListModel(this);
    connect(flm, &FolderListModel::updateNeeded, this, &MultiRootFolderListModel::updateNeeded);
    connect(flm, &FolderListModel::dataChanged, [=]()
    {
        // TODO: only emit for relevant index (mFolderListModels.indexOf(flm)
        emit this->dataChanged(index(0), index(rowCount() - 1));
    });
    flm->setPath(folderPath);

    _appendFolderListModel(flm);
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


    const FolderListModel* flm = mFolderListModels.at(index.row());
    const QFileInfo& ref = flm->root();

    switch (role)
    {
    case FolderListModel::NameRole:
    {
        return QVariant(ref.fileName());
    }
    case FolderListModel::PathRole:
    {
        return QVariant(ref.absoluteFilePath());
    }
    case FolderListModel::IsDirRole:
    {
        return QVariant(ref.isDir());
    }
    case FolderListModel::EntriesRole:
    {
        return QVariant::fromValue(mFolderListModels.at(index.row()));
    }
    }

    return QVariant();
}

FolderListModel *MultiRootFolderListModel::_findFolderListModel(QString folderPath)
{
    if (folderPath.startsWith("file:///"))
        folderPath.remove("file:///");

    for (auto* flm: mFolderListModels)
    {
        if (flm->root().absoluteFilePath() == folderPath)
        {
            return flm;
        }
    }
    return nullptr;
}

void MultiRootFolderListModel::_appendFolderListModel(FolderListModel *flm)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    mFolderListModels.append(flm);
    endInsertRows();
}

void MultiRootFolderListModel::_removeFolderListModel(FolderListModel *flm)
{
    int index = mFolderListModels.indexOf(flm);
    if (index == -1)
        return;

    beginRemoveRows(QModelIndex(), index, index);
    mFolderListModels.removeAt(index);
    endRemoveRows();
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
