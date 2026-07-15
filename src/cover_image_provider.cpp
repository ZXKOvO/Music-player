#include "cover_image_provider.h"

CoverImageProvider::CoverImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{}

QImage CoverImageProvider::requestImage(const QString &, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(requestedSize)
    QMutexLocker lock(&mutex_);

    if (coverData_.isEmpty()) {
        if (size) *size = QSize(0, 0);
        return QImage();
    }

    // 仅在数据变更时重新解码，避免重复 loadFromData
    if (dirty_) {
        cachedImage_.loadFromData(coverData_);
        dirty_ = false;
    }

    if (cachedImage_.isNull()) {
        if (size) *size = QSize(0, 0);
        return QImage();
    }

    if (requestedSize.isValid()) {
        return cachedImage_.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }

    if (size) *size = cachedImage_.size();
    return cachedImage_;
}

void CoverImageProvider::setCoverData(const QByteArray &data)
{
    QMutexLocker lock(&mutex_);
    coverData_ = data;
    dirty_ = true;
}

void CoverImageProvider::clear()
{
    QMutexLocker lock(&mutex_);
    coverData_.clear();
    cachedImage_ = QImage();
    dirty_ = true;
}
