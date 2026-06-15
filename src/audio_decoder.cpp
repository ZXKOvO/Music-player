#include "audio_decoder.h"
#include <QDebug>

AudioDecoder::AudioDecoder() {}

// 析构时自动释放 FFmpeg 资源
AudioDecoder::~AudioDecoder() { close(); }

// 打开音频文件：探测流信息 → 查找音频流 → 打开解码器 → 初始化重采样器
bool AudioDecoder::open(const QString &filePath) {
    close();

    // 打开文件并探测流信息
    int ret = avformat_open_input(&fmtCtx_, filePath.toUtf8().constData(), nullptr, nullptr);
    if (ret < 0) {
        qWarning() << "Cannot open file:" << filePath;
        return false;
    }
    avformat_find_stream_info(fmtCtx_, nullptr);

    // 查找最佳音频流
    streamIdx_ = av_find_best_stream(fmtCtx_, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);
    if (streamIdx_ < 0) {
        qWarning() << "No audio stream found";
        close();
        return false;
    }

    // 查找解码器并打开
    const AVCodec *codec = avcodec_find_decoder(fmtCtx_->streams[streamIdx_]->codecpar->codec_id);
    codecCtx_ = avcodec_alloc_context3(codec);
    avcodec_parameters_to_context(codecCtx_, fmtCtx_->streams[streamIdx_]->codecpar);
    ret = avcodec_open2(codecCtx_, codec, nullptr);
    if (ret < 0) {
        qWarning() << "Cannot open codec";
        close();
        return false;
    }

    // 计算时长（秒）
    duration_ = fmtCtx_->streams[streamIdx_]->duration
                * av_q2d(fmtCtx_->streams[streamIdx_]->time_base);

    // 初始化重采样器，将任意输入格式转换为统一的 FLT32/44100Hz/双声道
    initResampler();
    return true;
}

// 创建重采样器：将源音频格式转换为目标统一格式（FLT32/44100Hz/双声道）
bool AudioDecoder::initResampler() {
    AVChannelLayout outLayout;
    av_channel_layout_default(&outLayout, outputFormat_.channels);

    // 配置重采样参数：源格式 → 目标统一格式
    int ret = swr_alloc_set_opts2(&swrCtx_,
        &outLayout, outputFormat_.sampleFormat, outputFormat_.sampleRate,
        &codecCtx_->ch_layout, codecCtx_->sample_fmt, codecCtx_->sample_rate,
        0, nullptr);
    if (ret < 0 || !swrCtx_) {
        qWarning() << "Cannot create resampler";
        return false;
    }
    swr_init(swrCtx_);
    return true;
}

// 释放所有 FFmpeg 资源并重置状态
void AudioDecoder::close() {
    // 按依赖逆序释放：重采样器 → 解码器 → 封装上下文
    if (swrCtx_)  { swr_free(&swrCtx_); swrCtx_ = nullptr; }
    if (codecCtx_) { avcodec_free_context(&codecCtx_); codecCtx_ = nullptr; }
    if (fmtCtx_)  { avformat_close_input(&fmtCtx_); fmtCtx_ = nullptr; }
    streamIdx_ = -1;
    duration_ = 0.0;
}

// 循环读取 packet → 解码 → 重采样，将 PCM 数据填入 buffer，返回总字节数
int AudioDecoder::readPCM(uint8_t *buffer, int bufferSize) {
    if (seeking_.load()) return 0;

    AVPacket *pkt = av_packet_alloc();
    AVFrame  *frame = av_frame_alloc();
    int totalRead = 0;

    // 每个采样占用的字节数 = 声道数 × float大小
    int bytesPerSample = outputFormat_.channels * sizeof(float);

    // 循环读取 packet → 解码 → 重采样，直到填满 buffer 或文件结束
    while (totalRead < bufferSize) {
        int ret = av_read_frame(fmtCtx_, pkt);
        if (ret < 0) {
            // EOF 或读取错误，返回已解码的数据量
            av_packet_free(&pkt);
            av_frame_free(&frame);
            return totalRead > 0 ? totalRead : 0;
        }

        // 跳过非音频包
        if (pkt->stream_index != streamIdx_) {
            av_packet_unref(pkt);
            continue;
        }

        // 将 packet 送入解码器
        ret = avcodec_send_packet(codecCtx_, pkt);
        av_packet_unref(pkt);

        // 从解码器中取回所有已解码的帧
        while (ret >= 0 && totalRead < bufferSize) {
            ret = avcodec_receive_frame(codecCtx_, frame);
            if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) break;
            if (ret < 0) break;

            // 剩余缓冲区空间能容纳的最大输出采样数
            int maxOutSamples = (bufferSize - totalRead) / bytesPerSample;
            if (maxOutSamples <= 0) {
                av_frame_unref(frame);
                break;
            }

            // 重采样并写入 buffer 对应偏移位置
            uint8_t *outBuf = buffer + totalRead;
            int outSamples = swr_convert(swrCtx_,
                &outBuf, maxOutSamples,
                (const uint8_t**)frame->extended_data, frame->nb_samples);

            if (outSamples > 0) {
                totalRead += outSamples * bytesPerSample;
            }
            av_frame_unref(frame);
        }
    }

    av_packet_free(&pkt);
    av_frame_free(&frame);
    return totalRead;
}

// 跳转到指定秒数位置，向最近关键帧对齐，并清空解码器缓存
bool AudioDecoder::seek(double positionSec) {
    if (!fmtCtx_) return false;
    seeking_.store(true);

    // 将秒转换为流内部时间戳，向最近的关键帧 seek
    int64_t ts = positionSec / av_q2d(fmtCtx_->streams[streamIdx_]->time_base);
    int ret = avformat_seek_file(fmtCtx_, streamIdx_, INT64_MIN, ts, INT64_MAX, AVSEEK_FLAG_BACKWARD);

    if (ret >= 0) {
        avcodec_flush_buffers(codecCtx_);
        if (swrCtx_) {
            uint8_t *flushBuf = nullptr;
            swr_convert(swrCtx_, &flushBuf, 0, nullptr, 0);
            swr_init(swrCtx_);
        }
    }

    seeking_.store(false);
    return ret >= 0;
}

// 返回音频时长（秒）
double AudioDecoder::duration() const {
    return duration_;
}
