#pragma once
#include <QQuickImageProvider>
#include <QImage>
#include <QMutex>

// 内存级封面图片提供器：QML 通过 "image://cover/current" 获取当前歌曲封面
// 配合 PlayerController 使用，切换歌曲时更新数据，无需临时文件
class CoverImageProvider : public QQuickImageProvider
{
public:
    CoverImageProvider();

    // QML 请求图片回调，支持 requestedSize 缩放
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
    // 更新封面原始字节（JPEG/PNG）
    void setCoverData(const QByteArray &data);
    // 清除封面
    void clear();

private:
    QByteArray coverData_; // 原始图片数据
    QImage cachedImage_;   // 解码缓存，避免重复解码
    bool dirty_ = true;    // 数据变更标记
    QMutex mutex_;         // 线程安全（QML 渲染线程与主线程并发访问）
};
