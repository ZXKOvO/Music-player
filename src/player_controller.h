#pragma once
#include <QObject>
#include <QTimer>
#include <QThread>
#include <QUrl>
#include <QSettings>
#include <QtQml/qqmlregistration.h>
#include "audio_decoder.h"
#include "sdl_audio_output.h"
#include "speed_switch.h"
#include "ring_buffer.h"
#include "lyrics_parser.h"
#include "lyrics_fetcher.h"
#include "cover_image_provider.h"

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
    Q_PROPERTY(QString artist READ artist NOTIFY artistChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorOccurred)
    Q_PROPERTY(LyricsParser *lyrics READ lyrics CONSTANT)
    Q_PROPERTY(double playbackSpeed READ playbackSpeed WRITE setPlaybackSpeed NOTIFY playbackSpeedChanged)
    Q_PROPERTY(bool hasCover READ hasCover NOTIFY hasCoverChanged)
    Q_PROPERTY(bool showDesktopLyrics READ showDesktopLyrics WRITE setShowDesktopLyrics NOTIFY showDesktopLyricsChanged)
public:
    explicit PlayerController(QObject *parent = nullptr);
    ~PlayerController();

    Q_INVOKABLE void playFile(const QString &filePath);
    // 播放文件并可指定标题/歌手覆盖文件名解析结果（空字符串则用文件名解析），供歌单播放用
    Q_INVOKABLE void playFileWithMeta(const QString &filePath, const QString &title, const QString &artist);
    Q_INVOKABLE void togglePlay();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void seek(double pos);
    Q_INVOKABLE void toggleMute();
    Q_INVOKABLE void setPlaybackSpeed(double speed);
    Q_INVOKABLE void setVolume(float vol);
    Q_INVOKABLE void setMuted(bool muted);
    Q_INVOKABLE void startWindowSystemMove(QObject *window);
    // 覆盖当前歌曲显示标题/歌手（歌单重命名后同步界面，不改音频文件）
    Q_INVOKABLE void setTitleArtistOverride(const QString &title, const QString &artist);
    // 设置在线歌曲封面（从网络图片缓存获取的原始字节数据）
    Q_INVOKABLE void setOnlineCover(const QByteArray &coverData);
    // 通过 songId 从网络图片缓存获取封面并设置
    Q_INVOKABLE void setOnlineCoverById(int songId);
    // 预提取指定文件的封面并缓存（歌单缩略图用），已缓存则直接返回
    Q_INVOKABLE void ensurePlaylistCover(const QString &filePath);

    // 注册封面图片提供器到 QML 引擎（由 Main.qml 在 onCompleted 中调用）
    Q_INVOKABLE void registerCoverProvider();

    bool showDesktopLyrics() const { return showDesktopLyrics_; }
    Q_INVOKABLE void setShowDesktopLyrics(bool show);

    bool playing() const { return playing_; }
    double duration() const { return duration_; }
    double position() const { return position_; }
    float volume() const;
    bool muted() const { return muted_; }
    QString title() const { return title_; }
    QString artist() const { return artist_; }
    QString error() const { return error_; }
    LyricsParser *lyrics() const { return lyrics_; }
    double playbackSpeed() const { return playbackSpeed_; }
    bool hasCover() const { return hasCover_; }

signals:
    void playingChanged();
    void durationChanged();
    void positionChanged();
    void volumeChanged();
    void mutedChanged();
    void titleChanged();
    void artistChanged();
    void hasCoverChanged();
    void errorOccurred(const QString &msg);
    void playbackFinished();
    void playbackSpeedChanged();
    void showDesktopLyricsChanged();

private slots:
    void onUpdatePosition();
    void doSeek();

private:
    void startDecoding();
    void stopDecoding();
    void flushFilterToRingBuf();
    static void parseFileName(const QString &filePath, QString &title, QString &artist);

    AudioDecoder decoder_;
    RingBuffer ringBuf_{176400 * 2};
    SDLAudioOutput audioOutput_;
    SpeedSwitch speedSwitch_;
    std::atomic<double> decodeSpeed_{1.0};

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
    bool hasCover_ = false;
    CoverImageProvider coverProvider_; // 封面提供器，playFile() 时写入数据，QML 通过 image:// 读取
    LyricsParser *lyrics_;
    LyricsFetcher *lyricsFetcher_;
    qint64 startPts_ = 0;
    double playbackSpeed_ = 1.0;
    bool showDesktopLyrics_ = false;
    QSettings settings_;
};
