#pragma once
#include <QAbstractListModel>
#include <QStringList>
#include <QHash>

// 歌曲数据项
struct Song {
    QString filePath;
    QString title;
    QString artist;
    QString album;
    qint64  durationMs = 0; // 毫秒
};

// 播放列表模型：QAbstractListModel，供 QML ListView 显示歌曲列表
class PlaylistModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
public:
    enum Roles {
        FilePathRole = Qt::UserRole + 1,
        TitleRole,
        ArtistRole,
        AlbumRole,
        DurationRole
    };

    explicit PlaylistModel(QObject *parent = nullptr);

    // 添加单个文件路径到列表
    Q_INVOKABLE void addFile(const QString &filePath);
    // 添加多个文件路径
    Q_INVOKABLE void addFiles(const QStringList &filePaths);
    // 移除指定行
    Q_INVOKABLE void remove(int row);
    // 清空列表
    Q_INVOKABLE void clear();

    // 获取指定行的文件路径
    Q_INVOKABLE QString filePath(int row) const;
    // 当前列表中的歌曲数量
    int count() const;

    // QAbstractListModel 接口
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

signals:
    void countChanged();

private:
    QList<Song> songs_;
};
