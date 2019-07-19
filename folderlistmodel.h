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
    virtual ~FolderListModel() override;

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

    bool containsDir(QString pFolderPath);
    bool fuzzyLookUp(FolderListModel *root, QString filterText) const;

signals:
    void updateNeeded();

protected:
    virtual bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;

private:
    bool _containsDir(FolderListModel *flm, QString pFolderPath);

    FolderListModel* mFolderListModel = nullptr;
};

#endif // FOLDERLISTMODEL_H
