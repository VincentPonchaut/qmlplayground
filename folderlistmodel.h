#ifndef FOLDERLISTMODEL_H
#define FOLDERLISTMODEL_H

#include <QAbstractListModel>
#include <QDirIterator>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QObject>
#include <QTimer>
#include <QVariant>

class FolderListModel: public QAbstractListModel
{
    Q_OBJECT

// QAbstractItemModel interface
public:
    explicit FolderListModel(QObject *parent = nullptr);

    enum Roles
    {
        NameRole = Qt::UserRole + 1,
        PathRole,
        IsDirRole,
        EntriesRole
    };
    Q_ENUM(Roles)

    QHash<int,QByteArray> roleNames() const override;

    virtual int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    virtual QVariant data(const QModelIndex &index, int role) const override;

    void setPath(QString path);
    const QFileInfo& root() const;

signals:
    void updateNeeded();

private:
    void loadEntries();

    QFileInfo mRoot;
    QString mPath;
    QFileSystemWatcher mWatcher;
    QTimer mChangeNotifier;
    QVector<QFileInfo> mEntries;
    QVector<FolderListModel*> mFolderListModels;
};


#endif // FOLDERLISTMODEL_H
