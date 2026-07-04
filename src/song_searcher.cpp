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

// 搜索歌曲：调用网易云搜索API，返回候选歌曲列表
void SongSearcher::search(const QString &keyword)
{
    if (keyword.trimmed().isEmpty()) return;

    int reqId = ++searchRequestId_;  // 递增请求ID，用于标识当前请求

    if (!searching_) {
        searching_ = true;
        emit searchingChanged();
    }

    model_->clear();
    errorMessage_.clear();
    emit errorMessageChanged();

    // 构建搜索请求URL
    QUrl url("https://music.163.com/api/search/get");
    QUrlQuery params;
    params.addQueryItem("s", keyword.trimmed());  // 搜索关键词
    params.addQueryItem("type", "1");             // 类型1表示歌曲
    params.addQueryItem("limit", "30");           // 返回30条结果
    params.addQueryItem("offset", "0");           // 从第0条开始
    url.setQuery(params);

    QNetworkRequest req(url);
    req.setRawHeader("Referer", "https://music.163.com/");
    req.setRawHeader("Content-Type", "application/x-www-form-urlencoded");

    QNetworkReply *reply = netMgr_->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, reqId]() {
        reply->deleteLater();

        // 如果请求ID不匹配，说明是旧请求，直接丢弃
        if (reqId != searchRequestId_) return;

        if (reply->error() != QNetworkReply::NoError) {
            errorMessage_ = reply->errorString();
            emit errorMessageChanged();
            searching_ = false;
            emit searchingChanged();
            return;
        }

        // 解析搜索结果JSON
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject root = doc.object();
        QJsonArray songs = root.value("result").toObject().value("songs").toArray();

        // 提取歌曲信息，构建候选列表
        QList<SearchResult> candidates;
        for (const auto &s : songs) {
            QJsonObject song = s.toObject();
            SearchResult r;
            r.songId = song.value("id").toInt();
            r.name = song.value("name").toString();
            r.album = song.value("album").toObject().value("name").toString();
            r.duration = song.value("duration").toInt() / 1000;  // 毫秒转秒
            r.coverUrl = song.value("album").toObject().value("picUrl").toString();

            // 提取歌手名称，多个用逗号分隔
            QJsonArray artists = song.value("artists").toArray();
            QStringList artistNames;
            for (const auto &a : artists) {
                artistNames.append(a.toObject().value("name").toString());
            }
            r.artist = artistNames.join(", ");

            candidates.append(r);
        }

        qDebug() << "SongSearcher: got" << candidates.size() << "candidates, filtering playable...";

        // 过滤可播放歌曲
        filterPlayable(candidates, reqId);
    });
}

// 过滤可播放歌曲：批量查询歌曲播放状态，过滤VIP/无版权歌曲
void SongSearcher::filterPlayable(const QList<SearchResult> &candidates, int requestId)
{
    if (candidates.isEmpty()) {
        searching_ = false;
        emit searchingChanged();
        return;
    }

    // 构建歌曲ID列表，用于批量查询
    QStringList idStrs;
    for (const auto &r : candidates) {
        idStrs.append(QString::number(r.songId));
    }

    // 调用播放URL查询API
    QUrl url("https://music.163.com/api/song/enhance/player/url");
    QNetworkRequest req(url);
    req.setRawHeader("Referer", "https://music.163.com/");
    req.setRawHeader("Content-Type", "application/x-www-form-urlencoded");

    // POST请求体：ids=[id1,id2,...]&br=128000
    QByteArray body = "ids=[" + idStrs.join(",").toUtf8() + "]&br=128000";

    QNetworkReply *reply = netMgr_->post(req, body);
    connect(reply, &QNetworkReply::finished, this, [this, reply, candidates, requestId]() {
        reply->deleteLater();

        if (requestId != searchRequestId_) return;

        // 请求失败时，显示全部搜索结果（降级处理）
        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "SongSearcher: filter request failed:" << reply->errorString();
            model_->setResults(candidates);
            searching_ = false;
            emit searchingChanged();
            return;
        }

        // 解析播放URL查询结果
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonArray urlInfos = doc.object().value("data").toArray();

        // 构建可播放歌曲ID集合（code==200且url!=null表示可播放）
        QSet<int> playableIds;
        for (const auto &info : urlInfos) {
            QJsonObject obj = info.toObject();
            int id = obj.value("id").toInt();
            int code = obj.value("code").toInt();
            QJsonValue urlVal = obj.value("url");
            if (code == 200 && !urlVal.isNull() && !urlVal.isUndefined()) {
                playableIds.insert(id);
            }
        }

        // 只保留可播放的歌曲
        QList<SearchResult> filtered;
        for (const auto &r : candidates) {
            if (playableIds.contains(r.songId)) {
                filtered.append(r);
            }
        }

        qDebug() << "SongSearcher:" << filtered.size() << "of" << candidates.size() << "songs playable";

        // 如果没有可播放歌曲，显示提示信息
        if (filtered.isEmpty()) {
            errorMessage_ = QStringLiteral("未找到可播放的歌曲");
            emit errorMessageChanged();
        }

        model_->setResults(filtered);
        searching_ = false;
        emit searchingChanged();
    });
}

// 获取歌曲下载链接：下载MP3文件到本地缓存目录
void SongSearcher::getSongUrl(int songId, const QString &songName, const QString &artist)
{
    // 构建歌曲下载URL
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
        // 检查文件大小，太小可能是错误响应（如VIP限制）
        if (data.size() < 1024) {
            qWarning() << "SongSearcher: response too small for" << songName << "size=" << data.size();
            emit songUrlFailed(songName, "File too small (VIP or unavailable)");
            return;
        }

        // 检查Content-Type，如果是HTML说明不是音频文件
        QString contentType = reply->header(QNetworkRequest::ContentTypeHeader).toString();
        if (contentType.contains("text/html", Qt::CaseInsensitive)) {
            qWarning() << "SongSearcher: got HTML instead of audio for" << songName;
            emit songUrlFailed(songName, "VIP or region-locked");
            return;
        }

        // 创建缓存目录：项目文件夹下的 music cache 目录
        QString cacheDir = QString(PROJECT_SOURCE_DIR) + "/music cache";
        QDir().mkpath(cacheDir);

        // 生成文件名：{songId}_{songName}.mp3，替换非法字符
        QString fileName = QString("%1_%2.mp3").arg(songId).arg(songName);
        fileName.replace(QRegularExpression("[\\\\/:*?\"<>|]"), "_");
        QString filePath = cacheDir + "/" + fileName;

        // 写入文件
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
