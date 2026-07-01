#include "song_searcher.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QUrlQuery>
#include <QNetworkRequest>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QRegularExpression>
#include <QDebug>

SongSearcher::SongSearcher(QObject *parent)
    : QObject(parent)
    , netMgr_(new QNetworkAccessManager(this))
    , model_(new SearchResultModel(this))
{}

void SongSearcher::search(const QString &keyword)
{
    if (keyword.trimmed().isEmpty()) return;

    int reqId = ++searchRequestId_;

    if (!searching_) {
        searching_ = true;
        emit searchingChanged();
    }

    model_->clear();
    errorMessage_.clear();
    emit errorMessageChanged();

    QUrl url("https://music.163.com/api/search/get");
    QUrlQuery params;
    params.addQueryItem("s", keyword.trimmed());
    params.addQueryItem("type", "1");
    params.addQueryItem("limit", "30");
    params.addQueryItem("offset", "0");
    url.setQuery(params);

    QNetworkRequest req(url);
    req.setRawHeader("Referer", "https://music.163.com/");
    req.setRawHeader("Content-Type", "application/x-www-form-urlencoded");

    QNetworkReply *reply = netMgr_->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, reqId]() {
        reply->deleteLater();

        if (reqId != searchRequestId_) return;

        if (reply->error() != QNetworkReply::NoError) {
            errorMessage_ = reply->errorString();
            emit errorMessageChanged();
            searching_ = false;
            emit searchingChanged();
            return;
        }

        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject root = doc.object();
        QJsonArray songs = root.value("result").toObject().value("songs").toArray();

        QList<SearchResult> results;
        for (const auto &s : songs) {
            QJsonObject song = s.toObject();
            SearchResult r;
            r.songId = song.value("id").toInt();
            r.name = song.value("name").toString();
            r.album = song.value("album").toObject().value("name").toString();
            r.duration = song.value("duration").toInt() / 1000;
            r.coverUrl = song.value("album").toObject().value("picUrl").toString();

            QJsonArray artists = song.value("artists").toArray();
            QStringList artistNames;
            for (const auto &a : artists) {
                artistNames.append(a.toObject().value("name").toString());
            }
            r.artist = artistNames.join(", ");

            results.append(r);
        }

        model_->setResults(results);
        searching_ = false;
        emit searchingChanged();

        if (results.isEmpty()) {
            errorMessage_ = "未找到相关歌曲";
            emit errorMessageChanged();
        }
    });
}

void SongSearcher::getSongUrl(int songId, const QString &songName, const QString &artist)
{
    QUrl songUrl(QString("http://music.163.com/song/media/outer/url?id=%1.mp3").arg(songId));

    QNetworkRequest req(songUrl);
    req.setRawHeader("Referer", "https://music.163.com/");

    QNetworkReply *reply = netMgr_->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, songId, songName, artist]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "SongSearcher: download failed for" << songName << reply->errorString();
            emit songUrlFailed(songName, reply->errorString());
            return;
        }

        QByteArray data = reply->readAll();
        if (data.size() < 1024) {
            qWarning() << "SongSearcher: response too small for" << songName << "size=" << data.size();
            emit songUrlFailed(songName, "File too small (VIP or unavailable)");
            return;
        }

        QString contentType = reply->header(QNetworkRequest::ContentTypeHeader).toString();
        if (contentType.contains("text/html", Qt::CaseInsensitive)) {
            qWarning() << "SongSearcher: got HTML instead of audio for" << songName;
            emit songUrlFailed(songName, "VIP or region-locked");
            return;
        }

        QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/online_songs";
        QDir().mkpath(cacheDir);

        QString fileName = QString("%1_%2.mp3").arg(songId).arg(songName);
        fileName.replace(QRegularExpression("[\\\\/:*?\"<>|]"), "_");
        QString filePath = cacheDir + "/" + fileName;

        QFile file(filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            qWarning() << "SongSearcher: cannot write" << filePath;
            emit songUrlFailed(songName, "Cannot write file");
            return;
        }

        file.write(data);
        file.close();

        qDebug() << "SongSearcher: downloaded" << songName << "to" << filePath << "size=" << data.size();
        emit songUrlReady(filePath, songName, artist);
    });
}
