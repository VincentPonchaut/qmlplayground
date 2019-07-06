#ifndef MULTIROOTFOLDERLISTMODEL_H
#define MULTIROOTFOLDERLISTMODEL_H

#include <QAbstractListModel>
#include <QObject>
#include <QVector>

#include "folderlistmodel.h"

class MultiRootFolderListModel : public QAbstractListModel
{
    Q_OBJECT

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

signals:
    void updateNeeded();

// -------------------------------------------------------
// QAbstractItemModel interface
// -------------------------------------------------------
public:
    virtual int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    virtual QVariant data(const QModelIndex &index, int role) const override;

protected:
//    virtual bool insertRows(int row, int count, const QModelIndex &parent) override;


// -------------------------------------------------------
// Private methods
// -------------------------------------------------------
private:
    FolderListModel* _findFolderListModel(QString folderPath);

    void _appendFolderListModel(FolderListModel* flm);
    void _removeFolderListModel(FolderListModel* flm);


// -------------------------------------------------------
// Members
// -------------------------------------------------------
private:
    QVector<FolderListModel*> mFolderListModels;
};

#endif // MULTIROOTFOLDERLISTMODEL_H
