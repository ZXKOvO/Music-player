#pragma once
#include <QAbstractListModel>
#include <QList>
#include <QString>
#include <QtQml/qqmlregistration.h>

// 搜索结果数据结构
struct SearchResult
{
    int songId;       // 网易云歌曲ID
    QString name;     // 歌曲名
    QString artist;   // 艺术家（多个用逗号分隔）
    QString album;    // 专辑名
    int duration;     // 时长（秒）
    QString coverUrl; // 专辑封面URL
};

// 搜索结果数据模型：供QML ListView显示搜索结果
class SearchResultModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int count READ count NOTIFY countChanged)  // 结果数量

public:
    // 数据角色枚举，供QML delegate访问
    enum Roles {
        SongIdRole = Qt::UserRole + 1,  // 歌曲ID
        NameRole,                        // 歌曲名
        ArtistRole,                      // 艺术家
        AlbumRole,                       // 专辑
        DurationRole,                    // 时长
        CoverUrlRole                     // 封面URL
    };

    explicit SearchResultModel(QObject *parent = nullptr);

    // 设置搜索结果
    void setResults(const QList<SearchResult> &results);
    // 清空结果
    void clear();

    int count() const;
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // 便捷访问方法，供QML调用
    Q_INVOKABLE int songId(int row) const;
    Q_INVOKABLE QString songName(int row) const;
    Q_INVOKABLE QString songArtist(int row) const;
    Q_INVOKABLE QString songAlbum(int row) const;
    Q_INVOKABLE int songDuration(int row) const;

signals:
    void countChanged();

private:
    QList<SearchResult> results_;  // 搜索结果列表
};
