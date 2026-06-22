#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QString>

class LyricsFetcher : public QObject
{
    Q_OBJECT
public:
    explicit LyricsFetcher(QObject *parent = nullptr);

    void fetchLyrics(const QString &title, const QString &artist = QString(), double audioDurationSec = 0);

signals:
    void lyricsReady(const QString &lrcContent);
    void lyricsNotFound();
    void errorOccurred(const QString &msg);

private:
    void onSearchFinished(QNetworkReply *reply, const QString &title, const QString &artist, double audioDurationSec);
    void fetchLyricById(int songId, const QString &songName);

    QNetworkAccessManager *netMgr_;
};
