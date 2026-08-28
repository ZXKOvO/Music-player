#include "cover_image_provider.h"
#include <QPainter>
#include <QPainterPath>
#include <QUrl>
#include <utility>

namespace {
// 文件封面缓存上限，超过后整体清空（桌面应用歌单数量级远小于此）
constexpr int kMaxFileCovers = 512;
}

CoverImageProvider::CoverImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{}

// 将图片中心裁剪为正方形并切成圆形
// 先按目标尺寸用高质量滤波缩小，再绘制圆形：输出透明背景，由 QML 端圆形
// dimgray 背景衬底，避免方形罩子和 GPU 缩放带 alpha 图产生的边缘伪影
static QImage makeCircular(const QImage &src, const QSize &target)
{
    QImage img = src;
    if (target.isValid() && target.width() > 0) {
        img = img.scaled(target, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
        img = img.copy((img.width() - target.width()) / 2,
                       (img.height() - target.height()) / 2,
                       target.width(), target.height());
    }
    const int side = qMin(img.width(), img.height());

    QImage out(side, side, QImage::Format_ARGB32_Premultiplied);
    out.fill(Qt::transparent);
    QPainter p(&out);
    p.setRenderHint(QPainter::Antialiasing);
    QPainterPath path;
    path.addEllipse(0, 0, side, side);
    p.setClipPath(path);
    p.drawImage(0, 0, img);
    return out;
}

QImage CoverImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    QMutexLocker lock(&mutex_);

    // 文件封面：id 形如 "file/<URL编码路径>?<版本号>"
    if (id.startsWith("file/")) {
        const QString rawPath = id.mid(5);
        const int queryPos = rawPath.indexOf('?');
        const QString path = QUrl::fromPercentEncoding(
            (queryPos >= 0 ? rawPath.left(queryPos) : rawPath).toUtf8());
        QImage img = fileCoverImages_.value(path);
        if (img.isNull()) {
            const QByteArray data = fileCovers_.value(path);
            if (!data.isEmpty()) {
                img.loadFromData(data);
                fileCoverImages_.insert(path, img);
            }
        }
        if (img.isNull()) {
            if (size) *size = QSize(0, 0);
            return QImage();
        }
        if (requestedSize.isValid()) {
            img = img.scaled(requestedSize, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
            img = img.copy((img.width() - requestedSize.width()) / 2,
                           (img.height() - requestedSize.height()) / 2,
                           requestedSize.width(), requestedSize.height());
        }
        if (size) *size = img.size();
        return img;
    }

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

    // id 为 "circle" 时返回裁剪成圆形的封面（底部控制栏使用）
    if (id == "circle") {
        QImage img = makeCircular(cachedImage_, requestedSize);
        if (size) *size = img.size();
        return img;
    }

    QImage img = cachedImage_;
    if (requestedSize.isValid()) {
        img = img.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }

    if (size) *size = img.size();
    return img;
}

void CoverImageProvider::setCoverData(const QByteArray &data)
{
    QMutexLocker lock(&mutex_);
    coverData_ = data;
    dirty_ = true;
}

void CoverImageProvider::setFileCover(const QString &filePath, const QByteArray &data)
{
    QMutexLocker lock(&mutex_);
    if (data.isEmpty() || filePath.isEmpty()) return;
    if (fileCovers_.size() >= kMaxFileCovers) {
        fileCovers_.clear();
        fileCoverImages_.clear();
    }
    fileCovers_.insert(filePath, data);
    fileCoverImages_.remove(filePath); // 已有旧图片缓存时强制下次重新解码
}

bool CoverImageProvider::hasFileCover(const QString &filePath) const
{
    QMutexLocker lock(&mutex_);
    return fileCovers_.contains(filePath) || fileCoverImages_.contains(filePath);
}

void CoverImageProvider::clear()
{
    QMutexLocker lock(&mutex_);
    coverData_.clear();
    cachedImage_ = QImage();
    dirty_ = true;
}
