#include "player_controller.h"
#include <QFileInfo>
#include <QUrl>
#include <QDebug>
#include <SDL2/SDL.h>

PlayerController::PlayerController(QObject *parent)
    : QObject(parent)
{
    posTimer_.setInterval(200); // 每 200ms 更新进度
    connect(&posTimer_, &QTimer::timeout, this, &PlayerController::onUpdatePosition);

    // 初始化 SDL 音频子系统（仅需一次）
    static bool sdlInited = false;
    if (!sdlInited) {
        SDL_Init(SDL_INIT_AUDIO);
        sdlInited = true;
    }
}

// 析构时停止解码线程、关闭音频设备和 SDL
PlayerController::~PlayerController() {
    stopDecoding();
    audioOutput_.close();
}

// 播放指定文件路径，支持 file:/// URL 或本地路径
void PlayerController::playFile(const QString &filePath) {
    qDebug() << "playFile:" << filePath;

    // 先停止当前播放
    if (playing_ || decoder_.isOpen()) {
        stop();
    }

    // 将 file:/// URL 转为本地路径，处理中文等特殊字符
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(filePath).toLocalFile();
    }

    // 打开解码器
    if (!decoder_.open(localPath)) {
        error_ = QStringLiteral("Cannot open: %1").arg(localPath);
        emit errorOccurred(error_);
        qWarning() << error_;
        return;
    }
    error_.clear();
    qDebug() << "Opened:" << localPath
             << "duration=" << decoder_.duration()
             << "rate=" << decoder_.format().sampleRate
             << "ch=" << decoder_.format().channels;

    duration_ = decoder_.duration();
    emit durationChanged();

    title_ = extractTitle(localPath);
    emit titleChanged();

    // 每次播放新文件都必须重新打开 SDL 设备（确保音频规格匹配）
    audioOutput_.close();
    ringBuf_.clear();
    if (!audioOutput_.open(ringBuf_,
            decoder_.format().sampleRate, decoder_.format().channels)) {
        error_ = QStringLiteral("Cannot open audio device");
        emit errorOccurred(error_);
        qWarning() << error_;
        decoder_.close();
        return;
    }

    // 启动解码线程并开始播放
    startDecoding();
    audioOutput_.play();
    playing_ = true;
    position_ = 0.0;
    startPts_ = QDateTime::currentMSecsSinceEpoch();
    posTimer_.start();
    emit playingChanged();
    emit positionChanged();
}

// 播放/暂停切换
void PlayerController::togglePlay() {
    if (!decoder_.isOpen()) return;
    if (playing_) {
        audioOutput_.pause();
        playing_ = false;
        posTimer_.stop();
    } else {
        audioOutput_.play();
        playing_ = true;
        startPts_ = QDateTime::currentMSecsSinceEpoch() - static_cast<qint64>(position_ * 1000);
        posTimer_.start();
    }
    emit playingChanged();
}

// 停止播放，重置状态
void PlayerController::stop() {
    stopDecoding();
    audioOutput_.close();  // 关闭 SDL 设备，下次 playFile 重新打开
    ringBuf_.clear();
    decoder_.close();
    posTimer_.stop();
    playing_ = false;
    position_ = 0.0;
    duration_ = 0.0;
    emit playingChanged();
    emit positionChanged();
    emit durationChanged();
}

// 跳转到指定位置
void PlayerController::seek(double pos) {
    if (!decoder_.isOpen()) return;
    decoder_.seek(pos);
    position_ = pos;
    startPts_ = QDateTime::currentMSecsSinceEpoch() - static_cast<qint64>(pos * 1000);
    emit positionChanged();
}

float PlayerController::volume() const {
    return audioOutput_.volume();
}

void PlayerController::setVolume(float vol) {
    audioOutput_.setVolume(vol);
    emit volumeChanged();
}

// 定时轮询进度：根据经过时间估算当前播放位置
void PlayerController::onUpdatePosition() {
    if (!playing_) return;
    double elapsed = (QDateTime::currentMSecsSinceEpoch() - startPts_) / 1000.0;
    position_ = qMin(elapsed, duration_);
    emit positionChanged();

    // 播放完毕检测
    if (position_ >= duration_ && duration_ > 0 && ringBuf_.isEof() && ringBuf_.readable() == 0) {
        stop();
        emit playbackFinished();
    }
}

// 启动解码线程：循环从 decoder 读取 PCM 写入 RingBuffer
void PlayerController::startDecoding() {
    decoding_.store(true);
    decodeThread_ = QThread::create([this]() {
        uint8_t buf[65536];
        while (decoding_.load()) {
            int n = decoder_.readPCM(buf, sizeof(buf));
            if (n <= 0) {
                ringBuf_.setEof(true);
                break;
            }
            // 写入环形缓冲区，满了则阻塞等待
            size_t offset = 0;
            while (offset < static_cast<size_t>(n) && decoding_.load()) {
                offset += ringBuf_.write(buf + offset, static_cast<size_t>(n) - offset);
            }
        }
    });
    decodeThread_->start();
}

// 停止解码线程
void PlayerController::stopDecoding() {
    decoding_.store(false);
    ringBuf_.setEof(true);   // 唤醒可能在阻塞等待空间的写入线程
    ringBuf_.clear();        // 清空数据，唤醒可能在阻塞等待数据的读取线程
    if (decodeThread_) {
        decodeThread_->wait(3000);
        delete decodeThread_;
        decodeThread_ = nullptr;
    }
}

// 从文件路径中提取不带扩展名的文件名作为标题
QString PlayerController::extractTitle(const QString &filePath) {
    return QFileInfo(filePath).completeBaseName();
}
