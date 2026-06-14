#include "playlist_model.h"
#include <QFileInfo>

PlaylistModel::PlaylistModel(QObject *parent)
    : QAbstractListModel(parent) {}

// 添加单个文件路径，自动提取文件名作为标题
void PlaylistModel::addFile(const QString &filePath) {
    beginInsertRows({}, songs_.size(), songs_.size());
    Song s;
    s.filePath = filePath;
    s.title    = QFileInfo(filePath).completeBaseName();
    songs_.append(s);
    endInsertRows();
    emit countChanged();
}

// 批量添加文件路径
void PlaylistModel::addFiles(const QStringList &filePaths) {
    for (const auto &fp : filePaths) {
        addFile(fp);
    }
}

// 移除指定行
void PlaylistModel::remove(int row) {
    if (row < 0 || row >= songs_.size()) return;
    beginRemoveRows({}, row, row);
    songs_.removeAt(row);
    endRemoveRows();
    emit countChanged();
}

// 清空列表
void PlaylistModel::clear() {
    if (songs_.isEmpty()) return;
    beginResetModel();
    songs_.clear();
    endResetModel();
    emit countChanged();
}

// 获取指定行的文件路径
QString PlaylistModel::filePath(int row) const {
    if (row < 0 || row >= songs_.size()) return {};
    return songs_[row].filePath;
}

int PlaylistModel::count() const {
    return songs_.size();
}

int PlaylistModel::rowCount(const QModelIndex &parent) const {
    if (parent.isValid()) return 0;
    return songs_.size();
}

// 根据 role 返回歌曲数据
QVariant PlaylistModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= songs_.size()) return {};
    const auto &s = songs_[index.row()];
    switch (role) {
    case FilePathRole: return s.filePath;
    case TitleRole:    return s.title;
    case ArtistRole:   return s.artist;
    case AlbumRole:    return s.album;
    case DurationRole: return s.durationMs;
    default: return {};
    }
}

// 注册 QML 可用的 role 名称
QHash<int, QByteArray> PlaylistModel::roleNames() const {
    return {
        {FilePathRole, "filePath"},
        {TitleRole,    "title"},
        {ArtistRole,   "artist"},
        {AlbumRole,    "album"},
        {DurationRole, "durationMs"},
    };
}
