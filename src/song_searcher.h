#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QString>
#include <QList>
#include <QSet>
#include <QtQml/qqmlregistration.h>
#include "search_result_model.h"

// 在线歌曲搜索器：调用网易云音乐API搜索歌曲，过滤可播放歌曲，下载歌曲到本地
class SongSearcher : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(SearchResultModel *model READ model CONSTANT)                                     // 搜索结果模型
    Q_PROPERTY(bool searching READ searching NOTIFY searchingChanged)                            // 是否正在搜索
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)                // 错误信息
    Q_PROPERTY(bool pendingPlay READ pendingPlay WRITE setPendingPlay NOTIFY pendingPlayChanged) // 播放/添加模式

public:
    explicit SongSearcher(QObject *parent = nullptr);

    SearchResultModel *model() const { return model_; }
    bool searching() const { return searching_; }
    QString errorMessage() const { return errorMessage_; }
    bool pendingPlay() const { return pendingPlay_; }
    void setPendingPlay(bool pending)
    {
        pendingPlay_ = pending;
        emit pendingPlayChanged();
    }

    // 搜索歌曲
    Q_INVOKABLE void search(const QString &keyword);
    // 获取歌曲下载链接并保存到本地缓存
    Q_INVOKABLE void getSongUrl(int songId, const QString &songName, const QString &artist);

signals:
    void searchingChanged();
    void errorMessageChanged();
    void pendingPlayChanged();
    // 歌曲下载完成，返回本地文件路径
    void songUrlReady(const QString &filePath, const QString &songName, const QString &artist);
    // 歌曲下载失败
    void songUrlFailed(const QString &songName, const QString &reason);

private:
    // 过滤可播放歌曲：通过API批量查询歌曲播放状态
    void filterPlayable(const QList<SearchResult> &candidates, int requestId);
    // 获取歌曲详情（含封面URL）
    void fetchSongDetails(QList<SearchResult> results, int requestId);
    // 批量下载封面图片
    void downloadCovers(const QList<SearchResult> &results, int requestId);

    QNetworkAccessManager *netMgr_;       // 网络管理器
    SearchResultModel *model_;            // 搜索结果数据模型
    bool searching_ = false;              // 搜索状态标志
    QString errorMessage_;                // 错误信息
    bool pendingPlay_ = false;            // 播放/添加模式标志
    int searchRequestId_ = 0;             // 请求ID，用于防止旧请求干扰
};
