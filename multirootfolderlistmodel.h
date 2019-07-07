#ifndef MULTIROOTFOLDERLISTMODEL_H
#define MULTIROOTFOLDERLISTMODEL_H

#include <QAbstractListModel>
#include <QObject>
#include <QVector>

#include "folderlistmodel.h"
#include "macros.h"

class MultiRootFolderListModel : public QAbstractListModel
{
    Q_OBJECT

    PROPERTY(QString, filterText, setFilterText)

public:
    explicit MultiRootFolderListModel(QObject* parent = nullptr);

    QHash<int,QByteArray> roleNames() const override
    {
        QHash<int, QByteArray> result;
        result.insert(FolderListModel::NameRole, "name");
        result.insert(FolderListModel::PathRole, "path");
        result.insert(FolderListModel::IsDirRole, "isDir");
        result.insert(FolderListModel::EntriesRole, "entries");
        return result;
    }

    //
    void addFolder(QString folderPath);
    void removeFolder(QString folderPath);
    void clear();

    bool containsDir(QString pFolderPath);

signals:
    void updateNeeded();

// -------------------------------------------------------
// QAbstractItemModel interface
// -------------------------------------------------------
public:
    virtual int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    virtual QVariant data(const QModelIndex &index, int role) const override;

// -------------------------------------------------------
// Private methods
// -------------------------------------------------------
private:
    FolderListModelProxy *_findFolderListModel(QString folderPath);

    void _appendFolderListModel(FolderListModelProxy* flm);
    void _removeFolderListModel(FolderListModelProxy* flm);

    void _notify();

// -------------------------------------------------------
// Members
// -------------------------------------------------------
private:
    QVector<FolderListModelProxy*> mFolderListModels;
};

#endif // MULTIROOTFOLDERLISTMODEL_H
