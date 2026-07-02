#include "search_result_model.h"

SearchResultModel::SearchResultModel(QObject *parent)
    : QAbstractListModel(parent)
{}

// 设置搜索结果，重置模型并通知视图更新
void SearchResultModel::setResults(const QList<SearchResult> &results)
{
    beginResetModel();
    results_ = results;
    endResetModel();
    emit countChanged();
}

// 清空结果
void SearchResultModel::clear()
{
    beginResetModel();
    results_.clear();
    endResetModel();
    emit countChanged();
}

int SearchResultModel::count() const
{
    return results_.size();
}

int SearchResultModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return results_.size();
}

// 根据角色返回对应的数据
QVariant SearchResultModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= results_.size()) return {};

    const SearchResult &r = results_[index.row()];
    switch (role) {
    case SongIdRole:    return r.songId;
    case NameRole:      return r.name;
    case ArtistRole:    return r.artist;
    case AlbumRole:     return r.album;
    case DurationRole:  return r.duration;
    case CoverUrlRole:  return r.coverUrl;
    default:            return {};
    }
}

// 注册QML可用的角色名称
QHash<int, QByteArray> SearchResultModel::roleNames() const
{
    return {
        {SongIdRole,    "songId"},
        {NameRole,      "name"},
        {ArtistRole,    "artist"},
        {AlbumRole,     "album"},
        {DurationRole,  "duration"},
        {CoverUrlRole,  "coverUrl"}
    };
}

int SearchResultModel::songId(int row) const
{
    if (row < 0 || row >= results_.size()) return -1;
    return results_[row].songId;
}

QString SearchResultModel::songName(int row) const
{
    if (row < 0 || row >= results_.size()) return {};
    return results_[row].name;
}

QString SearchResultModel::songArtist(int row) const
{
    if (row < 0 || row >= results_.size()) return {};
    return results_[row].artist;
}

QString SearchResultModel::songAlbum(int row) const
{
    if (row < 0 || row >= results_.size()) return {};
    return results_[row].album;
}

int SearchResultModel::songDuration(int row) const
{
    if (row < 0 || row >= results_.size()) return 0;
    return results_[row].duration;
}
