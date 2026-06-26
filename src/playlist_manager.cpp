#include "playlist_manager.h"
#include <QFileInfo>

PlaylistManager::PlaylistManager(QObject *parent)
    : QAbstractListModel(parent)
{
}

// 创建新歌单
void PlaylistManager::createPlaylist(const QString &name)
{
    beginInsertRows({}, playlists_.size(), playlists_.size());
    UserPlaylist pl;
    pl.name = name;
    playlists_.append(pl);
    endInsertRows();
    emit countChanged();
    saveToFile();
}

// 删除歌单，同时修正 currentPlaylistIndex
void PlaylistManager::deletePlaylist(int index)
{
    if (index < 0 || index >= playlists_.size()) return;
    beginRemoveRows({}, index, index);
    playlists_.removeAt(index);
    endRemoveRows();
    if (currentPlaylistIndex_ == index) {
        currentPlaylistIndex_ = -1;
        emit currentPlaylistIndexChanged();
    } else if (currentPlaylistIndex_ > index) {
        currentPlaylistIndex_--;
        emit currentPlaylistIndexChanged();
    }
    emit countChanged();
    saveToFile();
}

void PlaylistManager::renamePlaylist(int index, const QString &newName)
{
    if (index < 0 || index >= playlists_.size()) return;
    playlists_[index].name = newName;
    QModelIndex idx = createIndex(index, 0);
    emit dataChanged(idx, idx, {NameRole});
    if (currentPlaylistIndex_ == index) {
        emit currentPlaylistIndexChanged();
    }
    saveToFile();
}

// 向指定歌单添加歌曲，自动去重，始终发射 songsChanged 保证数量同步
void PlaylistManager::addSongToPlaylist(int playlistIndex, const QString &filePath)
{
    if (playlistIndex < 0 || playlistIndex >= playlists_.size()) return;
    if (containsSong(playlistIndex, filePath)) return;
    Song s;
    s.filePath = filePath;
    s.title = QFileInfo(filePath).completeBaseName();
    playlists_[playlistIndex].songs.append(s);
    QModelIndex idx = createIndex(playlistIndex, 0);
    emit dataChanged(idx, idx, {SongCountRole});
    emit songsChanged();
    saveToFile();
}

void PlaylistManager::addSongToCurrentPlaylist(const QString &filePath)
{
    addSongToPlaylist(currentPlaylistIndex_, filePath);
}

// 从当前歌单移除指定歌曲
void PlaylistManager::removeSongFromCurrentPlaylist(int songIndex)
{
    if (currentPlaylistIndex_ < 0 || currentPlaylistIndex_ >= playlists_.size()) return;
    auto &songs = playlists_[currentPlaylistIndex_].songs;
    if (songIndex < 0 || songIndex >= songs.size()) return;
    songs.removeAt(songIndex);
    QModelIndex idx = createIndex(currentPlaylistIndex_, 0);
    emit dataChanged(idx, idx, {SongCountRole});
    emit songsChanged();
    saveToFile();
}

QString PlaylistManager::playlistName(int index) const
{
    if (index < 0 || index >= playlists_.size()) return {};
    return playlists_[index].name;
}

int PlaylistManager::playlistSongCount(int index) const
{
    if (index < 0 || index >= playlists_.size()) return 0;
    return playlists_[index].songs.size();
}

QString PlaylistManager::songFilePath(int playlistIndex, int songIndex) const
{
    if (playlistIndex < 0 || playlistIndex >= playlists_.size()) return {};
    const auto &songs = playlists_[playlistIndex].songs;
    if (songIndex < 0 || songIndex >= songs.size()) return {};
    return songs[songIndex].filePath;
}

QString PlaylistManager::songTitle(int playlistIndex, int songIndex) const
{
    if (playlistIndex < 0 || playlistIndex >= playlists_.size()) return {};
    const auto &songs = playlists_[playlistIndex].songs;
    if (songIndex < 0 || songIndex >= songs.size()) return {};
    return songs[songIndex].title;
}

bool PlaylistManager::containsSong(int playlistIndex, const QString &filePath) const
{
    if (playlistIndex < 0 || playlistIndex >= playlists_.size()) return false;
    for (const auto &s : playlists_[playlistIndex].songs) {
        if (s.filePath == filePath) return true;
    }
    return false;
}

int PlaylistManager::count() const
{
    return playlists_.size();
}

int PlaylistManager::currentPlaylistIndex() const
{
    return currentPlaylistIndex_;
}

void PlaylistManager::setCurrentPlaylistIndex(int index)
{
    if (currentPlaylistIndex_ == index) return;
    currentPlaylistIndex_ = index;
    emit currentPlaylistIndexChanged();
    emit songsChanged();
}

QString PlaylistManager::currentPlaylistName() const
{
    if (currentPlaylistIndex_ < 0 || currentPlaylistIndex_ >= playlists_.size()) return {};
    return playlists_[currentPlaylistIndex_].name;
}

int PlaylistManager::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return playlists_.size();
}

QVariant PlaylistManager::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= playlists_.size()) return {};
    const auto &pl = playlists_[index.row()];
    switch (role) {
    case NameRole:
        return pl.name;
    case SongCountRole:
        return pl.songs.size();
    default:
        return {};
    }
}

QHash<int, QByteArray> PlaylistManager::roleNames() const
{
    return {
        {NameRole, "name"},
        {SongCountRole, "songCount"}
    };
}

void PlaylistManager::saveToFile()
{
}

void PlaylistManager::loadFromFile()
{
}

QString PlaylistManager::savePath() const
{
    return {};
}
