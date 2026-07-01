#include "playlist_model.h"
#include <QFileInfo>

PlaylistModel::PlaylistModel(QObject *parent)
    : QAbstractListModel(parent)
{}

// 添加单个文件路径，自动提取文件名作为标题
void PlaylistModel::addFile(const QString &filePath)
{
    beginInsertRows({}, songs_.size(), songs_.size());
    Song s;
    s.filePath = filePath;
    s.title = QFileInfo(filePath).completeBaseName();
    songs_.append(s);
    endInsertRows();
    emit countChanged();
}

// 批量添加文件路径（自动跳过已存在的文件）
void PlaylistModel::addFiles(const QStringList &filePaths)
{
    for (const auto &fp : filePaths) {
        if (!contains(fp)) { addFile(fp); }
    }
}

// 移除指定行
void PlaylistModel::remove(int row)
{
    if (row < 0 || row >= songs_.size()) return;
    beginRemoveRows({}, row, row);
    songs_.removeAt(row);
    endRemoveRows();
    emit countChanged();
}

// 清空列表
void PlaylistModel::clear()
{
    if (songs_.isEmpty()) return;
    beginResetModel();
    songs_.clear();
    endResetModel();
    emit countChanged();
}

// 获取指定行的文件路径
QString PlaylistModel::filePath(int row) const
{
    if (row < 0 || row >= songs_.size()) return {};
    return songs_[row].filePath;
}

int PlaylistModel::count() const
{
    return songs_.size();
}

bool PlaylistModel::contains(const QString &filePath) const
{
    for (const auto &s : songs_) {
        if (s.filePath == filePath) return true;
    }
    return false;
}

int PlaylistModel::indexOf(const QString &filePath) const
{
    for (int i = 0; i < songs_.size(); ++i) {
        if (songs_[i].filePath == filePath) return i;
    }
    return -1;
}

// 设置播放模式
void PlaylistModel::setPlayMode(int mode)
{
    if (playMode_ == static_cast<PlayMode>(mode)) return;
    playMode_ = static_cast<PlayMode>(mode);
    emit playModeChanged();
}

// 切换到下一个播放模式
void PlaylistModel::nextPlayMode()
{
    int next = (static_cast<int>(playMode_) + 1) % 3;
    setPlayMode(next);
}

int PlaylistModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return songs_.size();
}

// 根据 role 返回歌曲数据
QVariant PlaylistModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= songs_.size()) return {};
    const auto &s = songs_[index.row()];
    switch (role) {
    case FilePathRole:
        return s.filePath;
    case TitleRole:
        return s.title;
    case ArtistRole:
        return s.artist;
    default:
        return {};
    }
}

// 注册 QML 可用的 role 名称
QHash<int, QByteArray> PlaylistModel::roleNames() const
{
    return {
        {FilePathRole, "filePath"},
        {TitleRole, "title"},
        {ArtistRole, "artist"},
    };
}
