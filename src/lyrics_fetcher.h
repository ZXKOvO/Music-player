#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QString>
#include <atomic>

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
    void onSearchFinished(QNetworkReply *reply,
                          const QString &title,
                          const QString &artist,
                          double audioDurationSec,
                          int requestId);
    void fetchLyricById(int songId, const QString &songName, int requestId);

    QNetworkAccessManager *netMgr_;
    std::atomic<int> requestId_{0};
};
