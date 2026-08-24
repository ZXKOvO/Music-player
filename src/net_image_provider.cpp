#include "net_image_provider.h"

NetImageProvider::NetImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{}

// QML 请求图片回调，支持 requestedSize 缩放
QImage NetImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    QString cleanId = id;
    int qPos = cleanId.indexOf('?');
    if (qPos >= 0) cleanId = cleanId.left(qPos);

    bool ok = false;
    int songId = cleanId.toInt(&ok);

    QMutexLocker lock(&mutex_);
    if (!ok || !imageCache_.contains(songId)) {
        if (size) *size = QSize(0, 0);
        return QImage();
    }

    QImage img = imageCache_.value(songId);
    if (size) *size = img.size();
    if (requestedSize.isValid() && !img.isNull()) {
        img = img.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    return img;
}

// 写入封面数据，同时保存原始字节和解码后图片
void NetImageProvider::setCoverData(int songId, const QByteArray &data)
{
    QMutexLocker lock(&mutex_);
    cache_.insert(songId, data);
    QImage img;
    img.loadFromData(data);
    imageCache_.insert(songId, img);
}

// 指定歌曲封面是否已缓存
bool NetImageProvider::hasCover(int songId) const
{
    QMutexLocker lock(&mutex_);
    return imageCache_.contains(songId);
}

// 获取指定歌曲封面的原始字节数据
QByteArray NetImageProvider::getRawCoverData(int songId) const
{
    QMutexLocker lock(&mutex_);
    return cache_.value(songId);
}
