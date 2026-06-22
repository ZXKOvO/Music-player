#pragma once
#include <QObject>
#include <QTimer>
#include <QThread>
#include <QtQml/qqmlregistration.h>
#include "audio_decoder.h"
#include "sdl_audio_output.h"
#include "ring_buffer.h"
#include "lyrics_parser.h"
#include "lyrics_fetcher.h"

// 播放控制器：协调 AudioDecoder + RingBuffer + SDLAudioOutput，
// 暴露 Q_PROPERTY / Q_INVOKABLE 给 QML 调用
class PlayerController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(double position READ position NOTIFY positionChanged)
    Q_PROPERTY(float volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorOccurred)
    Q_PROPERTY(LyricsParser* lyrics READ lyrics CONSTANT)
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
    LyricsParser* lyrics() const { return lyrics_; }

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

    // 从文件路径解析歌手和歌名
    static void parseFileName(const QString &filePath, QString &title, QString &artist);

    AudioDecoder decoder_;
    RingBuffer ringBuf_{176400 * 2};
    SDLAudioOutput audioOutput_;

    QThread *decodeThread_ = nullptr;
    std::atomic<bool> decoding_{false};

    QTimer posTimer_;
    QTimer seekTimer_;
    double pendingSeekPos_ = -1;
    double duration_ = 0.0;
    double position_ = 0.0;
    bool playing_ = false;
    bool muted_ = false;
    float volumeBeforeMute_ = 1.0f;
    QString title_;
    QString artist_;
    QString error_;
    LyricsParser *lyrics_;
    LyricsFetcher *lyricsFetcher_;
    QString currentAudioPath_;
    qint64 startPts_ = 0;
};
