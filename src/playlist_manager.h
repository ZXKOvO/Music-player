#pragma once
#include <QAbstractListModel>
#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QString>
#include <QtQml/qqmlregistration.h>
#include "playlist_model.h"

// 用户歌单数据结构
struct UserPlaylist
{
    QString name;
    QList<Song> songs;
};

// 歌单管理器：管理多个命名歌单，支持增删改查，数据持久化到 JSON 文件
class PlaylistManager : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int currentPlaylistIndex READ currentPlaylistIndex WRITE setCurrentPlaylistIndex NOTIFY
                   currentPlaylistIndexChanged)
    Q_PROPERTY(QString currentPlaylistName READ currentPlaylistName NOTIFY currentPlaylistIndexChanged)

public:
    enum Roles { NameRole = Qt::UserRole + 1, SongCountRole };

    explicit PlaylistManager(QObject *parent = nullptr);

    Q_INVOKABLE void createPlaylist(const QString &name);                           // 创建歌单
    Q_INVOKABLE void deletePlaylist(int index);                                     // 删除歌单
    Q_INVOKABLE void renamePlaylist(int index, const QString &newName);             // 重命名歌单
    Q_INVOKABLE bool addSongToPlaylist(int playlistIndex, const QString &filePath); // 向指定歌单添加歌曲，返回是否成功
    Q_INVOKABLE bool addSongToCurrentPlaylist(const QString &filePath);             // 向当前歌单添加歌曲，返回是否成功
    Q_INVOKABLE void removeSongFromCurrentPlaylist(int songIndex);                  // 从当前歌单移除歌曲
    Q_INVOKABLE QString playlistName(int index) const;
    Q_INVOKABLE int playlistSongCount(int index) const;
    Q_INVOKABLE QString songFilePath(int playlistIndex, int songIndex) const;
    Q_INVOKABLE QString songTitle(int playlistIndex, int songIndex) const;
    Q_INVOKABLE bool containsSong(int playlistIndex, const QString &filePath) const; // 判断歌单是否包含某歌曲（按文件路径）
    Q_INVOKABLE bool containsSongByTitle(int playlistIndex, const QString &title) const; // 判断歌单是否包含某歌曲（按歌名）

    int count() const;
    int currentPlaylistIndex() const;
    void setCurrentPlaylistIndex(int index);
    QString currentPlaylistName() const;

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

signals:
    void countChanged();
    void currentPlaylistIndexChanged();
    void songsChanged(); // 歌单内歌曲变化时发射，通知 QML 刷新数量显示

private:
    void saveToFile();   // 保存所有歌单到 JSON 文件
    void loadFromFile(); // 从 JSON 文件加载歌单
    QString savePath() const;

    QList<UserPlaylist> playlists_;
    int currentPlaylistIndex_ = -1;
};
