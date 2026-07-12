#include "lyrics_fetcher.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QUrlQuery>
#include <QNetworkRequest>
#include <QCoreApplication>
#include <QFile>
#include <QDir>
#include <utility>
#include <QDateTime>
#include <QtMath>
#include <QDebug>

static void log(const QString &msg)
{
    QString path = QCoreApplication::applicationDirPath() + "/musicplayer_lyrics.log";
    QFile f(path);
    if (f.open(QIODevice::Append | QIODevice::Text)) {
        f.write(QDateTime::currentDateTime().toString("hh:mm:ss.zzz").toUtf8());
        f.write(" ");
        f.write(msg.toUtf8());
        f.write("\n");
    }
}

LyricsFetcher::LyricsFetcher(QObject *parent)
    : QObject(parent)
    , netMgr_(new QNetworkAccessManager(this))
{}

void LyricsFetcher::fetchLyrics(const QString &title, const QString &artist, double audioDurationSec)
{
    int id = ++requestId_;
    QString query = title;
    if (!artist.isEmpty()) query += " " + artist;

    log("=== fetchLyrics start: title=" + title + " artist=" + artist + " dur=" + QString::number(audioDurationSec)
        + " reqId=" + QString::number(id));

    QUrl url("https://music.163.com/api/search/get");
    QUrlQuery params;
    params.addQueryItem("s", query);
    params.addQueryItem("type", "1");
    params.addQueryItem("limit", "10");
    params.addQueryItem("offset", "0");
    url.setQuery(params);

    log("Search URL: " + url.toString());

    QNetworkRequest req(url);
    req.setRawHeader("Referer", "https://music.163.com/");
    req.setRawHeader("Content-Type", "application/x-www-form-urlencoded");

    QNetworkReply *reply = netMgr_->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, title, artist, audioDurationSec, id]() {
        log("Search reply received, error=" + QString::number(reply->error()));
        onSearchFinished(reply, title, artist, audioDurationSec, id);
    });
}

void LyricsFetcher::onSearchFinished(QNetworkReply *reply,
                                     const QString &title,
                                     const QString &,
                                     double audioDurationSec,
                                     int requestId)
{
    reply->deleteLater();

    if (requestId != requestId_.load()) {
        log("Search discarded (stale request)");
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        log("Search FAILED: " + reply->errorString());
        emit errorOccurred(reply->errorString());
        return;
    }

    QByteArray data = reply->readAll();
    log("Search response size=" + QString::number(data.size()));

    QJsonDocument doc = QJsonDocument::fromJson(data);
    QJsonObject root = doc.object();
    QJsonArray songs = root.value("result").toObject().value("songs").toArray();

    log("Found " + QString::number(songs.size()) + " songs");

    if (songs.isEmpty()) {
        log("No results for: " + title);
        emit lyricsNotFound();
        return;
    }

    int bestId = -1;
    QString bestName;
    double bestDiff = 1e9;

    for (const auto &s : std::as_const(songs)) {
        QJsonObject song = s.toObject();
        QString songName = song.value("name").toString();
        int id = song.value("id").toInt();
        double songDurationSec = song.value("duration").toInt() / 1000.0;

        log("  Candidate: " + songName + " id=" + QString::number(id) + " dur=" + QString::number(songDurationSec)
            + "s");

        if (songName == title) {
            if (audioDurationSec > 0) {
                double diff = qAbs(songDurationSec - audioDurationSec);
                if (diff < bestDiff) {
                    bestDiff = diff;
                    bestId = id;
                    bestName = songName;
                }
            } else if (bestId == -1) {
                bestId = id;
                bestName = songName;
            }
        }
    }

    if (bestId == -1 && audioDurationSec > 0) {
        bestDiff = 1e9;
        for (const auto &s : std::as_const(songs)) {
            QJsonObject song = s.toObject();
            QString songName = song.value("name").toString();
            int id = song.value("id").toInt();
            double songDurationSec = song.value("duration").toInt() / 1000.0;
            double diff = qAbs(songDurationSec - audioDurationSec);
            if (diff < bestDiff) {
                bestDiff = diff;
                bestId = id;
                bestName = songName;
            }
        }
    }

    if (bestId == -1) {
        QJsonObject first = songs.first().toObject();
        bestId = first.value("id").toInt();
        bestName = first.value("name").toString();
    }

    log("Selected: " + bestName + " id=" + QString::number(bestId));
    fetchLyricById(bestId, bestName, requestId);
}

// 根据歌曲 ID 获取歌词
// 优先获取逐字歌词(YRC)，fallback 到逐行歌词(LRC)
// YRC 格式示例: [10140,3720]去(10140,120)到(10260,300)每(10560,150)
//   - [startMs,durationMs] = 行级时间
//   - 字(startMs,durationMs) = 字级时间
void LyricsFetcher::fetchLyricById(int songId, const QString &songName, int requestId)
{
    QUrl url("https://music.163.com/api/song/lyric");
    QUrlQuery params;
    params.addQueryItem("id", QString::number(songId));
    params.addQueryItem("lv", "1");  // 请求逐行歌词
    params.addQueryItem("yrc", "1"); // 请求逐字歌词
    url.setQuery(params);

    log("Fetching lyric: " + url.toString());

    QNetworkRequest req(url);
    req.setRawHeader("Referer", "https://music.163.com/");

    QNetworkReply *reply = netMgr_->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, songName, requestId]() {
        reply->deleteLater();

        if (requestId != requestId_.load()) {
            log("Lyric fetch discarded (stale request)");
            return;
        }

        if (reply->error() != QNetworkReply::NoError) {
            log("Lyric fetch FAILED: " + reply->errorString());
            emit errorOccurred(reply->errorString());
            return;
        }

        QByteArray data = reply->readAll();
        log("Lyric response size=" + QString::number(data.size()));

        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject root = doc.object();

        // 优先取逐字歌词（yrc 字段）
        QString yrc = root.value("yrc").toObject().value("lyric").toString();
        if (!yrc.isEmpty()) {
            log("Got YRC (逐字) for " + songName + " size=" + QString::number(yrc.size()));
            log("First 200 chars: " + yrc.left(200));
            emit lyricsReady(yrc);
            return;
        }

        // fallback 到逐行歌词（lrc 字段）
        QString lrc = root.value("lrc").toObject().value("lyric").toString();
        if (lrc.isEmpty()) {
            log("No lyrics content for: " + songName);
            emit lyricsNotFound();
            return;
        }

        log("Got LRC (逐行) for " + songName + " size=" + QString::number(lrc.size()));
        log("First 100 chars: " + lrc.left(100));
        emit lyricsReady(lrc);
    });
}
