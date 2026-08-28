#pragma once
#include <QQuickImageProvider>
#include <QImage>
#include <QHash>
#include <QMutex>
#include <QMutexLocker>

// 网络图片内存缓存提供器：QML 通过 "image://net/<songId>?v=N" 获取封面，
// 由 SongSearcher（主线程）下载后写入缓存，QML 渲染线程读取时加锁保证线程安全
class NetImageProvider : public QQuickImageProvider
{
public:
    NetImageProvider();

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
    // 写入封面数据（SongSearcher 主线程调用）
    void setCoverData(int songId, const QByteArray &data);
    // 指定歌曲封面是否已缓存
    bool hasCover(int songId) const;
    // 获取指定歌曲封面的原始字节数据
    QByteArray getRawCoverData(int songId) const;

    static void setInstance(NetImageProvider *inst) { s_instance = inst; }
    static NetImageProvider *instance() { return s_instance; }

private:
    QHash<int, QByteArray> cache_;     // 原始图片数据
    QHash<int, QImage> imageCache_;    // 解码后图片缓存
    mutable QMutex mutex_;             // 线程安全（QML 渲染线程与主线程并发访问）
    static inline NetImageProvider *s_instance = nullptr;
};
