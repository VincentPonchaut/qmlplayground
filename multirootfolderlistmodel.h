#ifndef MULTIROOTFOLDERLISTMODEL_H
#define MULTIROOTFOLDERLISTMODEL_H

#include <QAbstractListModel>
#include <QObject>
#include <QVector>

#include "folderlistmodel.h"
#include "macros.h"

class FsProxyModel;

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
    FsProxyModel *_findFolderListModel(QString folderPath);

    void _appendFolderListModel(FsProxyModel* flm);
    void _removeFolderListModel(FsProxyModel* flm);

    void _notify();

// -------------------------------------------------------
// Members
// -------------------------------------------------------
private:
//    QVector<FolderListModelProxy*> mFolderListModels;
    QVector<FsProxyModel*> mFolderListModels;
};

// ---------------------------------------------------------------
// Fs
// ---------------------------------------------------------------

class FsEntry: public QObject
{
    Q_OBJECT

    PROPERTY(QString, path, setPath)
    PROPERTY(QString, name, setName)
    PROPERTY(FsEntry*, parent, setParent)
    PROPERTY(bool, expandable, setExpandable)
    PROPERTY(bool, expanded, setExpanded)

public:
    FsEntry();
    FsEntry(const FsEntry& other);
    FsEntry(const QFileInfo& fileInfo, FsEntry* parent = nullptr);

    virtual ~FsEntry(){}

    int row() const;

    QVector<FsEntry*> children;
};

Q_DECLARE_METATYPE(FsEntry);

class FsEntryModel: public QAbstractItemModel
{
    Q_OBJECT

public:
    explicit FsEntryModel(QObject* parent = nullptr);

    enum Roles
    {
        NameRole = Qt::UserRole + 1,
        PathRole,
        IsExpandableRole,
        IsExpandedRole,
        IsHiddenRole,
        ChildrenRole,
        ChildrenCountRole,
        EntryRole
    };
    Q_ENUM(Roles)

    QHash<int,QByteArray> roleNames() const override
    {
        QHash<int, QByteArray> result;
        result.insert(FsEntryModel::NameRole, "name");
        result.insert(FsEntryModel::PathRole, "path");
        result.insert(FsEntryModel::IsExpandableRole, "isExpandable");
        result.insert(FsEntryModel::IsExpandedRole, "isExpanded");
        result.insert(FsEntryModel::IsHiddenRole, "isHidden");
        result.insert(FsEntryModel::ChildrenRole, "children");
        result.insert(FsEntryModel::ChildrenCountRole, "childrenCount");
        result.insert(FsEntryModel::EntryRole, "entry");
        return result;
    }
    Q_INVOKABLE int roleFromString(QString roleName);

    // QAbstractItemModel interface
    virtual QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
    virtual QModelIndex parent(const QModelIndex &child) const override;
    virtual int rowCount(const QModelIndex &parent= QModelIndex()) const override;
    virtual int columnCount(const QModelIndex &parent= QModelIndex()) const override;
    virtual QVariant data(const QModelIndex &index, int role) const override;

    QString path() const;
    void setPath(const QString &path);

    bool containsDir(const QString& path);

    FsEntry* root() const;

protected:
    void loadEntries();

private:
    FsEntry* rootItem = nullptr;
    QString mPath;
};

class FsProxyModel: public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)
public:
    FsProxyModel(QObject* parent = nullptr);
    virtual ~FsProxyModel() override;

    QString path() const;
    void setPath(const QString &path);

    QString filterText() const;
    void setFilterText(QString filterText);

    bool containsDir(const QString& path);
    FsEntry* root() const;
    Q_INVOKABLE int roleFromString(QString roleName);

signals:
    void filterTextChanged(QString filterText);

protected:
    // QSortFilterProxyModel interface
    virtual bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;

private:
    QString m_filterText;

};

#endif // MULTIROOTFOLDERLISTMODEL_H
