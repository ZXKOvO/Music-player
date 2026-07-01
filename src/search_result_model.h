#pragma once
#include <QAbstractListModel>
#include <QList>
#include <QString>
#include <QtQml/qqmlregistration.h>

struct SearchResult
{
    int songId;
    QString name;
    QString artist;
    QString album;
    int duration; // seconds
    QString coverUrl;
};

class SearchResultModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        SongIdRole = Qt::UserRole + 1,
        NameRole,
        ArtistRole,
        AlbumRole,
        DurationRole,
        CoverUrlRole
    };

    explicit SearchResultModel(QObject *parent = nullptr);

    void setResults(const QList<SearchResult> &results);
    void clear();

    int count() const;
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE int songId(int row) const;
    Q_INVOKABLE QString songName(int row) const;
    Q_INVOKABLE QString songArtist(int row) const;
    Q_INVOKABLE QString songAlbum(int row) const;
    Q_INVOKABLE int songDuration(int row) const;

signals:
    void countChanged();

private:
    QList<SearchResult> results_;
};
