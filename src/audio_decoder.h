#pragma once
#include <QString>
#include <QByteArray>
#include <atomic>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>
#include <libavutil/opt.h>
}

// 统一的输出音频格式描述
struct AudioFormat
{
    int sampleRate = 44100;
    int channels = 2;
    AVSampleFormat sampleFormat = AV_SAMPLE_FMT_FLT; // 32-bit float
};

// FFmpeg 音频解码器：打开文件 → 解码 → 重采样为统一格式（FLT32/44100Hz/双声道）
class AudioDecoder
{
public:
    AudioDecoder();  // 默认构造
    ~AudioDecoder(); // 析构时自动释放 FFmpeg 资源

    // 打开音频文件，初始化解码器和重采样器，成功返回 true
    bool open(const QString &filePath);
    // 释放所有 FFmpeg 资源，恢复初始状态
    void close();

    // 将解码+重采样后的 PCM 数据写入 buffer，返回写入字节数，0 表示 EOF
    int readPCM(uint8_t *buffer, int bufferSize);

    // 跳转到指定位置（秒），seek 完成后解码器从新位置继续读取
    bool seek(double positionSec);
    // 获取音频时长（秒）
    double duration() const;

    // 获取统一输出格式
    const AudioFormat &format() const { return outputFormat_; }
    // 文件是否已打开
    bool isOpen() const { return fmtCtx_ != nullptr; }

    // 提取音频文件内嵌的封面图片数据（JPEG/PNG），无封面返回空 QByteArray
    QByteArray coverData() const;

private:
    // 创建并初始化重采样器，将源格式转换为目标统一格式
    bool initResampler();

    AVFormatContext *fmtCtx_ = nullptr;  // 封装上下文
    AVCodecContext *codecCtx_ = nullptr; // 解码器上下文
    SwrContext *swrCtx_ = nullptr;       // 重采样上下文
    int streamIdx_ = -1;                 // 音频流索引

    AudioFormat outputFormat_; // 统一输出格式
    double duration_ = 0.0;
    QString filePath_; // 保存文件路径，供 coverData 读取封面

    std::atomic<bool> seeking_{false}; // seek 进行中标志，防止 readPCM 竞争
};
