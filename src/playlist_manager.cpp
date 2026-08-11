#include "playlist_manager.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>
#include <QStandardPaths>
#include <QUrl>
#include <utility>

// 规范化歌曲路径：去除 file:// 前缀、解析符号链接与 ..
// 避免同一文件因路径形式不同被重复添加
static QString normalizeSongPath(const QString &filePath)
{
    QString p = filePath.trimmed();
    if (p.startsWith("file://", Qt::CaseInsensitive)) {
        p = QUrl(p).toLocalFile();
    }
    QFileInfo info(p);
    const QString canonical = info.canonicalFilePath(); // 解析符号链接与 ..
    if (!canonical.isEmpty()) return canonical;
    p = info.absoluteFilePath();
#ifdef Q_OS_WIN
    p = p.toLower();
#endif
    return p;
}

PlaylistManager::PlaylistManager(QObject *parent)
    : QAbstractListModel(parent)
{
    // 启动时从 JSON 文件加载已保存的歌单数据
    loadFromFile();
}

// 创建新歌单
void PlaylistManager::createPlaylist(const QString &name)
{
    beginInsertRows({}, static_cast<int>(playlists_.size()), static_cast<int>(playlists_.size()));
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
    if (currentPlaylistIndex_ == index) { emit currentPlaylistIndexChanged(); }
    saveToFile();
}

// 向指定歌单添加歌曲，按规范化路径自动去重，返回是否成功
// 如果是在线缓存歌曲（music cache），自动复制到 playlist/songs/ 永久保存
bool PlaylistManager::addSongToPlaylist(int playlistIndex, const QString &filePath)
{
    if (playlistIndex < 0 || playlistIndex >= playlists_.size()) return false;

    // 规范化路径后判重，避免 file:// 前缀、符号链接等路径形式不同导致重复添加
    QString normalized = normalizeSongPath(filePath);
    if (containsSong(playlistIndex, normalized)) return false;

    QString permanentPath = normalized;
    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/music cache";
    if (normalized.startsWith(cacheDir)) {
        QString songsDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/playlist/songs";
        QDir().mkpath(songsDir);
        QString fileName = QFileInfo(normalized).fileName();
        permanentPath = songsDir + "/" + fileName;
        // 检查永久路径是否已在歌单中
        if (containsSong(playlistIndex, permanentPath)) return false;
        if (!QFile::exists(permanentPath)) { QFile::copy(normalized, permanentPath); }
    }

    Song s;
    s.filePath = permanentPath;
    s.title = QFileInfo(permanentPath).completeBaseName();
    playlists_[playlistIndex].songs.append(s);
    QModelIndex idx = createIndex(playlistIndex, 0);
    emit dataChanged(idx, idx, {SongCountRole});
    emit songsChanged();
    saveToFile();
    return true;
}

bool PlaylistManager::addSongToCurrentPlaylist(const QString &filePath)
{
    return addSongToPlaylist(currentPlaylistIndex_, filePath);
}

// 修改歌单内歌曲标题：只更新歌单 JSON 中的显示标题，不修改音频文件本身
// 新的标题为空时回退为文件名，便于用户清空输入框还原
bool PlaylistManager::setSongTitle(int playlistIndex, int songIndex, const QString &newTitle)
{
    if (playlistIndex < 0 || playlistIndex >= playlists_.size()) return false;
    auto &songs = playlists_[playlistIndex].songs;
    if (songIndex < 0 || songIndex >= songs.size()) return false;
    QString title = newTitle.trimmed();
    if (title.isEmpty()) { title = QFileInfo(songs[songIndex].filePath).completeBaseName(); }
    if (songs[songIndex].title == title) return false;
    songs[songIndex].title = title;
    emit songsChanged();
    saveToFile();
    return true;
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
    return static_cast<int>(playlists_[index].songs.size());
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
    const QString needle = normalizeSongPath(filePath);
    for (const auto &s : std::as_const(playlists_[playlistIndex].songs)) {
        if (normalizeSongPath(s.filePath) == needle) return true;
    }
    return false;
}

bool PlaylistManager::containsSongByTitle(int playlistIndex, const QString &title) const
{
    if (playlistIndex < 0 || playlistIndex >= playlists_.size()) return false;
    for (const auto &s : std::as_const(playlists_[playlistIndex].songs)) {
        if (s.title == title) return true;
    }
    return false;
}

int PlaylistManager::count() const
{
    return static_cast<int>(playlists_.size());
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
    return static_cast<int>(playlists_.size());
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
    return {{NameRole, "name"}, {SongCountRole, "songCount"}};
}

// 歌单持久化文件路径：项目目录下 playlist/playlists.json
QString PlaylistManager::savePath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/playlist/playlists.json";
}

void PlaylistManager::saveToFile()
{
    QJsonArray playlistsArray;
    for (const auto &pl : std::as_const(playlists_)) {
        QJsonObject plObj;
        plObj["name"] = pl.name;
        QJsonArray songsArray;
        for (const auto &song : pl.songs) {
            QJsonObject songObj;
            songObj["filePath"] = song.filePath;
            songObj["title"] = song.title;
            songsArray.append(songObj);
        }
        plObj["songs"] = songsArray;
        playlistsArray.append(plObj);
    }
    QJsonObject root;
    root["playlists"] = playlistsArray;
    QJsonDocument doc(root);
    QString path = savePath();
    QFileInfo(path).absoluteDir().mkpath(".");
    QFile file(path);
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) { file.write(doc.toJson(QJsonDocument::Indented)); }
}

void PlaylistManager::loadFromFile()
{
    QFile file(savePath());
    if (!file.exists() || !file.open(QIODevice::ReadOnly)) return;
    QByteArray data = file.readAll();
    file.close();
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) return;
    QJsonObject root = doc.object();
    QJsonArray playlistsArray = root["playlists"].toArray();
    beginResetModel();
    playlists_.clear();
    for (const auto &plVal : std::as_const(playlistsArray)) {
        QJsonObject plObj = plVal.toObject();
        UserPlaylist pl;
        pl.name = plObj["name"].toString();
        QJsonArray songsArray = plObj["songs"].toArray();
        // 跳过历史重复项（如 file:// 前缀与纯路径同时存在），并统一为规范化路径
        QSet<QString> seen;
        for (const auto &songVal : std::as_const(songsArray)) {
            QJsonObject songObj = songVal.toObject();
            Song s;
            const QString normalized = normalizeSongPath(songObj["filePath"].toString());
            if (seen.contains(normalized)) continue;
            seen.insert(normalized);
            s.filePath = normalized;
            s.title = songObj["title"].toString();
            pl.songs.append(s);
        }
        playlists_.append(pl);
    }
    endResetModel();
    if (!playlists_.isEmpty()) { emit countChanged(); }
}
