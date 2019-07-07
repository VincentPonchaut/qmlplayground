#ifndef FOLDERLISTMODEL_H
#define FOLDERLISTMODEL_H

#include <QAbstractListModel>
#include <QDirIterator>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QObject>
#include <QSortFilterProxyModel>
#include <QTimer>
#include <QVariant>

#include "macros.h"

class FolderListModelProxy;

class FolderListModel: public QAbstractListModel
{
    Q_OBJECT

// QAbstractItemModel interface
public:
    explicit FolderListModel(QObject *parent = nullptr);
    FolderListModel(const FolderListModel& other);
    virtual ~FolderListModel();

    enum Roles
    {
        NameRole = Qt::UserRole + 1,
        PathRole,
        IsDirRole,
        EntriesRole
    };
    Q_ENUM(Roles)

    QHash<int,QByteArray> roleNames() const override;

    Q_INVOKABLE virtual int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    virtual QVariant data(const QModelIndex &index, int role) const override;

    void setPath(QString path);
    const QFileInfo& root() const;

    FolderListModelProxy *proxy() const;
    void setProxy(FolderListModelProxy *proxy);

signals:
    void updateNeeded();

private:
    void loadEntries();

    QFileInfo mRoot;
    QString mPath;
    QFileSystemWatcher mWatcher;
    QTimer mChangeNotifier;
    QVector<QFileInfo> mEntries;
    QVector<FolderListModelProxy*> mFolderListModels;
    FolderListModelProxy* mProxy = nullptr;
};

//This macro makes the type Type known to QMetaType as long as it provides
// 1. a public default constructor,
// 2. a public copy constructor
// 3. and a public destructor.
// It is needed to use the type Type as a custom type in QVariant.
Q_DECLARE_METATYPE(FolderListModel)

class FolderListModelProxy: public QSortFilterProxyModel
{
    Q_OBJECT

    PROPERTY(QString, filterText, setFilterText)

public:
    explicit FolderListModelProxy(QObject* parent = nullptr);

    FolderListModel *folderListModel() const;
    void setFolderListModel(FolderListModel *folderListModel);

    void setPath(QString path);
    const QFileInfo& root() const;

signals:
    void updateNeeded();

protected:
    virtual bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;

private:
    FolderListModel* mFolderListModel = nullptr;
};

#endif // FOLDERLISTMODEL_H
