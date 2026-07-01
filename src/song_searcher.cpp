#include "song_searcher.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QUrlQuery>
#include <QNetworkRequest>
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
