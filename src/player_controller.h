#pragma once
#include <QObject>
#include <QTimer>
#include <QThread>
#include "audio_decoder.h"
#include "sdl_audio_output.h"
#include "ring_buffer.h"

// 播放控制器：协调 AudioDecoder + RingBuffer + SDLAudioOutput，
// 暴露 Q_PROPERTY / Q_INVOKABLE 给 QML 调用
class PlayerController : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(double position READ position NOTIFY positionChanged)
    Q_PROPERTY(float volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorOccurred)
public:
    explicit PlayerController(QObject *parent = nullptr);
    ~PlayerController();

    // 播放指定文件路径（支持 file:/// URL 或本地路径）
    Q_INVOKABLE void playFile(const QString &filePath);
    // 播放/暂停切换
    Q_INVOKABLE void togglePlay();
    // 停止播放
    Q_INVOKABLE void stop();
    // 跳转到指定秒数位置
    Q_INVOKABLE void seek(double pos);
    // 静音切换
    Q_INVOKABLE void toggleMute();

    bool playing() const { return playing_; }
    double duration() const { return duration_; }
    double position() const { return position_; }
    float volume() const;
    // 设置音量 (0.0 ~ 1.0)
    Q_INVOKABLE void setVolume(float vol);
    bool muted() const { return muted_; }
    Q_INVOKABLE void setMuted(bool muted);
    QString title() const { return title_; }
    QString error() const { return error_; }

signals:
    void playingChanged();
    void durationChanged();
    void positionChanged();
    void volumeChanged();
    void mutedChanged();
    void titleChanged();
    void errorOccurred(const QString &msg);
    // 当前曲目播放完毕
    void playbackFinished();

private slots:
    // 定时更新播放进度
    void onUpdatePosition();
    // seek 防抖
    void doSeek();

private:
    // 启动解码线程
    void startDecoding();
    // 停止解码线程
    void stopDecoding();
    // 从文件路径提取歌曲标题
    static QString extractTitle(const QString &filePath);

    AudioDecoder decoder_;
    RingBuffer ringBuf_{176400 * 2}; // 约 2 秒 PCM (44100*2*4=352800 bytes/sec)
    SDLAudioOutput audioOutput_;

    QThread *decodeThread_ = nullptr;
    std::atomic<bool> decoding_{false};

    QTimer posTimer_;          // 进度轮询定时器
    QTimer seekTimer_;          // seek 防抖
    double pendingSeekPos_ = -1; // 待 seek 位置（秒）
    double duration_  = 0.0;
    double position_  = 0.0;
    bool playing_    = false;
    bool muted_      = false;
    float volumeBeforeMute_ = 1.0f;
    QString title_;
    QString error_;
    qint64 startPts_ = 0;     // 播放起始时间（ms），用于估算进度
};
