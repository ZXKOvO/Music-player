#pragma once
#include <QString>
#include <vector>

extern "C" {
#include <libavfilter/avfilter.h>
#include <libavfilter/buffersrc.h>
#include <libavfilter/buffersink.h>
#include <libavutil/opt.h>
#include <libavutil/channel_layout.h>
#include <libavutil/samplefmt.h>
}

// 基于 FFmpeg atempo 滤镜的变速不变调处理
// 运行在解码线程，非音频回调线程
class SpeedSwitch
{
public:
    SpeedSwitch();
    ~SpeedSwitch();

    // 初始化滤镜图，指定采样率和声道数
    bool init(int sampleRate, int channels);

    // 释放滤镜图，重置为 1.0 倍速
    void close();

    // 设置目标倍速 (0.5 ~ 2.0)，自动重建 atempo 滤镜链
    void setSpeed(double speed);

    // 输入 PCM ，返回输出样本数
    int process(const float *input, int inputSamples, float *outputBuf, int outputBufSize);

    // 发送 NULL 帧清空滤镜内部缓冲，返回剩余样本数
    int flush(float *outputBuf, int outputBufSize);

    double speed() const { return curSpeed_; }

private:
    // 重建 atempo 滤镜图
    bool buildFilter(double speed);
    // 从滤镜输出端读取帧并转换为 interleaved float 格式
    int drainOutput(float *outputBuf, int outputBufSize);

    AVFilterGraph *graph_ = nullptr;
    AVFilterContext *srcCtx_ = nullptr;  //音频缓冲输入端
    AVFilterContext *sinkCtx_ = nullptr; //音频缓冲接收端
    int sampleRate_ = 0;
    int channels_ = 0;
    double curSpeed_ = 1.0;
    bool ready_ = false;
};
