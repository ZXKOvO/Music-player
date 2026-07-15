#include "player_controller.h"
#include "cover_image_provider.h"
#include <QFileInfo>
#include <QUrl>
#include <QDebug>
#include <SDL2/SDL.h>
#include <QDateTime>
#include <QQmlEngine>
#include <QQmlContext>
#include <QDir>
#include <QQuickWindow>

PlayerController::PlayerController(QObject *parent)
    : QObject(parent)
    , lyrics_(new LyricsParser(this))
    , lyricsFetcher_(new LyricsFetcher(this))
{
    // 进度轮询定时器：每 200ms 更新一次播放位置
    posTimer_.setInterval(200);
    connect(&posTimer_, &QTimer::timeout, this, &PlayerController::onUpdatePosition);

    // seek 防抖定时器：拖动进度条后延迟 150ms 再执行实际 seek
    seekTimer_.setSingleShot(true);
    seekTimer_.setInterval(150);
    connect(&seekTimer_, &QTimer::timeout, this, &PlayerController::doSeek);

    // 在线歌词获取成功：解析 YRC/LRC 格式并替换本地歌词
    connect(lyricsFetcher_, &LyricsFetcher::lyricsReady, this, [this](const QString &lrc) {
        qDebug() << "Online lyrics received, size=" << lrc.size();
        lyrics_->loadFromString(lrc);
        qDebug() << "Online lyrics loaded, lines=" << lyrics_->lineCount();
    });
    // 在线歌词未找到：保留本地 LRC 歌词
    connect(lyricsFetcher_, &LyricsFetcher::lyricsNotFound, this, [this]() {
        qDebug() << "LyricsFetcher: no lyrics found online, keeping local LRC";
    });
    connect(lyricsFetcher_, &LyricsFetcher::errorOccurred, this, [](const QString &msg) {
        qDebug() << "LyricsFetcher error:" << msg;
    });

    // SDL 音频子系统全局初始化（只执行一次）
    static bool sdlInited = false;
    if (!sdlInited) {
        SDL_Init(SDL_INIT_AUDIO);
        sdlInited = true;
    }

    // 从 QSettings 恢复上次保存的音量和桌面歌词设置
    float savedVol = settings_.value("volume", 1.0f).toFloat();
    audioOutput_.setVolume(savedVol);
    showDesktopLyrics_ = settings_.value("showDesktopLyrics", false).toBool();
}

// 析构时停止解码线程、关闭音频设备和 SDL，并清空缓存
PlayerController::~PlayerController()
{
    stopDecoding();
    audioOutput_.close();

    // 清空在线歌曲缓存目录
    QString cacheDir = QString(PROJECT_SOURCE_DIR) + "/music cache";
    QDir dir(cacheDir);
    if (dir.exists()) {
        dir.removeRecursively();
        qDebug() << "Music cache cleared:" << cacheDir;
    }
}

// 播放指定文件路径，支持 file:/// URL 或本地路径
void PlayerController::playFile(const QString &filePath)
{
    qDebug() << "playFile:" << filePath;

    // 先停止当前播放
    if (playing_ || decoder_.isOpen()) { stop(); }

    // 切换歌曲时重置倍速为 1.0
    playbackSpeed_ = 1.0;
    decodeSpeed_.store(1.0);
    emit playbackSpeedChanged();

    // 将 file:/// URL 转为本地路径，处理中文等特殊字符
    QString localPath = filePath;
    if (localPath.startsWith("file://")) { localPath = QUrl(filePath).toLocalFile(); }

    // 打开解码器
    if (!decoder_.open(localPath)) {
        error_ = QStringLiteral("Cannot open: %1").arg(localPath);
        emit errorOccurred(error_);
        qWarning() << error_;
        return;
    }
    error_.clear();
    qDebug() << "Opened:" << localPath << "duration=" << decoder_.duration() << "rate=" << decoder_.format().sampleRate
             << "ch=" << decoder_.format().channels;

    duration_ = decoder_.duration();
    emit durationChanged();

    parseFileName(localPath, title_, artist_);
    emit titleChanged();
    emit artistChanged();

    // 提取封面图片，通过 ImageProvider 直接传递给 QML（无临时文件）
    QByteArray coverBytes = decoder_.coverData();
    if (!coverBytes.isEmpty()) {
        coverProvider_.setCoverData(coverBytes);
        hasCover_ = true;
    } else {
        coverProvider_.clear();
        hasCover_ = false;
    }
    emit hasCoverChanged();

    // 加载本地歌词，然后用网易云 API 获取匹配的歌词替换
    lyrics_->setFilePath(localPath);
    lyricsFetcher_->fetchLyrics(title_, artist_, duration_);

    // 每次播放新文件都必须重新打开 SDL 设备（确保音频规格匹配）
    audioOutput_.close();
    ringBuf_.clear();
    if (!audioOutput_.open(ringBuf_, decoder_.format().sampleRate, decoder_.format().channels)) {
        error_ = QStringLiteral("Cannot open audio device");
        emit errorOccurred(error_);
        qWarning() << error_;
        decoder_.close();
        return;
    }

    // 恢复全局音量（SDL 重新打开后可能重置）
    audioOutput_.setVolume(settings_.value("volume", 1.0f).toFloat());

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
void PlayerController::togglePlay()
{
    if (!decoder_.isOpen()) return;
    if (playing_) {
        audioOutput_.pause();
        playing_ = false;
        posTimer_.stop();
    } else {
        audioOutput_.play();
        playing_ = true;
        startPts_ = QDateTime::currentMSecsSinceEpoch() - static_cast<qint64>(position_ / playbackSpeed_ * 1000);
        posTimer_.start();
    }
    emit playingChanged();
}

// 停止播放，重置状态
void PlayerController::stop()
{
    seekTimer_.stop();
    pendingSeekPos_ = -1;
    stopDecoding();
    audioOutput_.close(); // 关闭 SDL 设备，下次 playFile 重新打开
    ringBuf_.clear();
    decoder_.close();
    posTimer_.stop();
    playing_ = false;
    position_ = 0.0;
    duration_ = 0.0;
    title_.clear();
    coverProvider_.clear();
    hasCover_ = false;
    lyrics_->clear();
    emit playingChanged();
    emit positionChanged();
    emit durationChanged();
    emit titleChanged();
    emit hasCoverChanged();
}

// seek 防抖：记录位置并延迟执行
void PlayerController::seek(double pos)
{
    if (!decoder_.isOpen()) return;

    pendingSeekPos_ = pos;
    position_ = pos;
    startPts_ = QDateTime::currentMSecsSinceEpoch() - static_cast<qint64>(pos / playbackSpeed_ * 1000);
    emit positionChanged();

    seekTimer_.start();
}

// 实际执行 seek
void PlayerController::doSeek()
{
    if (pendingSeekPos_ < 0 || !decoder_.isOpen()) return;

    double pos = pendingSeekPos_;
    pendingSeekPos_ = -1;

    bool wasPlaying = playing_;
    if (wasPlaying) {
        audioOutput_.pause();
        posTimer_.stop();
    }

    stopDecoding();

    decoder_.seek(pos);

    startDecoding();

    position_ = pos;
    startPts_ = QDateTime::currentMSecsSinceEpoch() - static_cast<qint64>(pos / playbackSpeed_ * 1000);

    if (wasPlaying) {
        audioOutput_.play();
        posTimer_.start();
    }

    emit positionChanged();
}

float PlayerController::volume() const
{
    return audioOutput_.volume();
}

void PlayerController::setVolume(float vol)
{
    audioOutput_.setVolume(vol);
    settings_.setValue("volume", vol);
    emit volumeChanged();
}

void PlayerController::setMuted(bool muted)
{
    if (muted_ == muted) return;
    muted_ = muted;
    if (muted_) {
        volumeBeforeMute_ = audioOutput_.volume();
        audioOutput_.setVolume(0.0f);
    } else {
        audioOutput_.setVolume(volumeBeforeMute_);
    }
    emit mutedChanged();
}

void PlayerController::toggleMute()
{
    setMuted(!muted_);
}

void PlayerController::setShowDesktopLyrics(bool show)
{
    if (showDesktopLyrics_ == show) return;
    showDesktopLyrics_ = show;
    settings_.setValue("showDesktopLyrics", show);
    emit showDesktopLyricsChanged();
}

// 启动窗口系统拖动（用于桌面歌词窗口拖拽移动）
void PlayerController::startWindowSystemMove(QObject *window)
{
    if (auto *qw = qobject_cast<QQuickWindow *>(window)) qw->startSystemMove();
}

void PlayerController::setPlaybackSpeed(double speed)
{
    speed = std::clamp(speed, 0.5, 2.0);
    if (qFuzzyCompare(playbackSpeed_, speed)) return;

    playbackSpeed_ = speed;
    decodeSpeed_.store(speed);

    // 倍速变化后重新校准计时起点
    if (playing_) { startPts_ = QDateTime::currentMSecsSinceEpoch() - static_cast<qint64>(position_ / speed * 1000); }

    emit playbackSpeedChanged();
    qDebug() << "Playback speed set to:" << speed;
}

// 将封面图片提供器注册到 QML 引擎，QML 通过 "image://cover/current" 访问
void PlayerController::registerCoverProvider()
{
    if (auto *ctx = QQmlEngine::contextForObject(this)) { ctx->engine()->addImageProvider("cover", &coverProvider_); }
}

// 定时轮询进度：经过时间 × 倍速 = 实际播放位置
void PlayerController::onUpdatePosition()
{
    if (!playing_) return;
    double elapsed = static_cast<double>(QDateTime::currentMSecsSinceEpoch() - startPts_) / 1000.0;
    position_ = qMin(elapsed * playbackSpeed_, duration_);
    emit positionChanged();

    // 播放完毕检测
    if (position_ >= duration_ && duration_ > 0 && ringBuf_.isEof() && ringBuf_.readable() == 0) {
        stop();
        emit playbackFinished();
    }
}

// 启动解码线程：循环从 decoder 读取 PCM → SpeedSwitch（变速不变调）→ RingBuffer → SDL 播放
void PlayerController::startDecoding()
{
    // 在解码线程初始化 SpeedSwitch（FFmpeg atempo 滤镜）
    const auto &fmt = decoder_.format();
    speedSwitch_.init(fmt.sampleRate, fmt.channels);
    speedSwitch_.setSpeed(decodeSpeed_.load());
    ringBuf_.clear();

    decoding_.store(true);
    decodeThread_ = QThread::create([this]() {
        uint8_t buf[65536];
        uint8_t stretchBuf[262144]; // 0.5x 时输出最多约 2 倍输入

        while (decoding_.load()) {
            int n = decoder_.readPCM(buf, sizeof(buf));
            if (n <= 0) {
                // 文件结束，清空滤镜缓冲后标记 eof
                flushFilterToRingBuf();
                ringBuf_.setEof(true);
                break;
            }

            double targetSpeed = decodeSpeed_.load();
            if (std::abs(targetSpeed - speedSwitch_.speed()) > 0.001) {
                // 倍速已变：flush 旧滤镜，重建新滤镜
                flushFilterToRingBuf();
                speedSwitch_.setSpeed(targetSpeed);
            }

            if (std::abs(targetSpeed - 1.0) < 0.005) {
                // 1.0x 正常速度：跳过变速处理，直接写入环形缓冲区
                size_t offset = 0;
                while (offset < static_cast<size_t>(n) && decoding_.load()) {
                    size_t w = ringBuf_.write(buf + offset, static_cast<size_t>(n) - offset);
                    if (w == 0) break;
                    offset += w;
                }
                continue;
            }

            // 非 1.0x 变速：经 FFmpeg atempo 滤镜拉伸后写入环形缓冲区
            int inSamples = n / static_cast<int>(sizeof(float));
            int outSamples = speedSwitch_.process(reinterpret_cast<const float *>(buf),
                                                  inSamples,
                                                  reinterpret_cast<float *>(stretchBuf),
                                                  sizeof(stretchBuf) / static_cast<int>(sizeof(float)));

            if (outSamples > 0) {
                size_t toWrite = static_cast<size_t>(outSamples) * sizeof(float);
                size_t offset = 0;
                while (offset < toWrite && decoding_.load()) {
                    size_t w = ringBuf_.write(stretchBuf + offset, toWrite - offset);
                    if (w == 0) break;
                    offset += w;
                }
            }
        }
    });
    decodeThread_->start();
}

// 刷新滤镜缓冲并写入 RingBuffer
void PlayerController::flushFilterToRingBuf()
{
    float flushBuf[65536];
    int flushed = speedSwitch_.flush(flushBuf, 65536);
    if (flushed > 0) {
        size_t toWrite = static_cast<size_t>(flushed) * sizeof(float);
        size_t offset = 0;
        while (offset < toWrite && decoding_.load()) {
            size_t w = ringBuf_.write(reinterpret_cast<uint8_t *>(flushBuf) + offset, toWrite - offset);
            if (w == 0) break;
            offset += w;
        }
    }
}

// 停止解码线程
void PlayerController::stopDecoding()
{
    decoding_.store(false);
    ringBuf_.setEof(true); // 唤醒阻塞的写入线程
    if (decodeThread_) {
        if (!decodeThread_->wait(5000)) {
            qWarning() << "Decode thread did not stop within 5s, terminating...";
            decodeThread_->terminate();
            decodeThread_->wait(3000);
        }
        delete decodeThread_;
        decodeThread_ = nullptr;
    }
    // 线程停止后再 clear，防止旧线程再次 setEof
    ringBuf_.clear();
}

// 从文件名解析歌手和歌名，支持 "歌手 - 歌名" 格式
void PlayerController::parseFileName(const QString &filePath, QString &title, QString &artist)
{
    QString baseName = QFileInfo(filePath).completeBaseName();
    int sep = static_cast<int>(baseName.indexOf(" - "));
    if (sep > 0) {
        artist = baseName.left(sep).trimmed();
        title = baseName.mid(sep + 3).trimmed();
    } else {
        artist.clear();
        title = baseName.trimmed();
    }
}
