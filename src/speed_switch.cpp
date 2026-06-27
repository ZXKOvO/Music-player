#include "speed_switch.h"
#include <cstring>
#include <cmath>
#include <algorithm>
#include <QDebug>

SpeedSwitch::SpeedSwitch() {}

SpeedSwitch::~SpeedSwitch()
{
    close();
}

void SpeedSwitch::close()
{
    if (graph_) {
        avfilter_graph_free(&graph_);
        graph_ = nullptr;
    }
    srcCtx_ = nullptr;
    sinkCtx_ = nullptr;
    curSpeed_ = 1.0;
    ready_ = false;
}

bool SpeedSwitch::init(int sampleRate, int channels)
{
    close();
    sampleRate_ = sampleRate;
    channels_ = channels;
    return buildFilter(1.0);
}

// 构建 abuffer → atempo → abuffersink 滤镜图
// atempo 原生范围 0.5~2.0，超过 2.0 时链式串联多个滤镜
bool SpeedSwitch::buildFilter(double speed)
{
    if (graph_) avfilter_graph_free(&graph_);
    graph_ = avfilter_graph_alloc();
    if (!graph_) return false;

    std::string filterDesc;
    double remaining = speed;

    if (remaining > 2.0) {
        while (remaining > 2.001) {
            if (!filterDesc.empty()) filterDesc += ",";
            filterDesc += "atempo=2.0";
            remaining /= 2.0;
        }
        if (remaining > 1.001) {
            if (!filterDesc.empty()) filterDesc += ",";
            char buf[32];
            snprintf(buf, sizeof(buf), "atempo=%.6f", remaining);
            filterDesc += buf;
        }
    } else {
        char buf[32];
        snprintf(buf, sizeof(buf), "atempo=%.6f", remaining);
        filterDesc = buf;
    }

    const AVFilter *src = avfilter_get_by_name("abuffer");
    const AVFilter *sink = avfilter_get_by_name("abuffersink");
    if (!src || !sink) {
        qWarning() << "SpeedSwitch: cannot find filters";
        return false;
    }

    AVChannelLayout layout;
    av_channel_layout_default(&layout, channels_);

    char srcArgs[512];
    snprintf(srcArgs,
             sizeof(srcArgs),
             "sample_rate=%d:sample_fmt=flt:channel_layout=0x%llx",
             sampleRate_,
             (unsigned long long) layout.u.mask);

    int err = avfilter_graph_create_filter(&srcCtx_, src, "src", srcArgs, nullptr, graph_);
    if (err < 0) {
        qWarning() << "SpeedSwitch: create abuffer failed" << err;
        return false;
    }

    err = avfilter_graph_create_filter(&sinkCtx_, sink, "sink", nullptr, nullptr, graph_);
    if (err < 0) {
        qWarning() << "SpeedSwitch: create abuffersink failed" << err;
        return false;
    }

    // 强制 sink 输出 packed float32，避免 atempo 输出 planar 导致数据错位
    AVSampleFormat sampleFmts[] = {AV_SAMPLE_FMT_FLT, AV_SAMPLE_FMT_NONE};
    av_opt_set_int_list(sinkCtx_, "sample_fmts", (const int *) sampleFmts, AV_SAMPLE_FMT_NONE, AV_OPT_SEARCH_CHILDREN);

    AVFilterInOut *outputs = avfilter_inout_alloc();
    AVFilterInOut *inputs = avfilter_inout_alloc();
    outputs->name = av_strdup("in");
    outputs->filter_ctx = srcCtx_;
    outputs->pad_idx = 0;
    outputs->next = nullptr;

    inputs->name = av_strdup("out");
    inputs->filter_ctx = sinkCtx_;
    inputs->pad_idx = 0;
    inputs->next = nullptr;

    char *desc = av_strdup(filterDesc.c_str());
    err = avfilter_graph_parse_ptr(graph_, desc, &inputs, &outputs, nullptr);
    av_free(desc);
    avfilter_inout_free(&inputs);
    avfilter_inout_free(&outputs);

    if (err < 0) {
        qWarning() << "SpeedSwitch: parse failed" << err;
        return false;
    }

    err = avfilter_graph_config(graph_, nullptr);
    if (err < 0) {
        qWarning() << "SpeedSwitch: config failed" << err;
        return false;
    }

    curSpeed_ = speed;
    ready_ = true;
    return true;
}

void SpeedSwitch::setSpeed(double speed)
{
    speed = std::clamp(speed, 0.5, 2.0);
    if (std::abs(speed - curSpeed_) > 0.001) { buildFilter(speed); }
}

// 将 PCM 送入 atempo 滤镜并取出拉伸后的输出
// 返回输出缓冲中的 float 样本数
int SpeedSwitch::process(const float *input, int inputSamples, float *outputBuf, int outputBufSize)
{
    if (!ready_) return 0;
    if (inputSamples <= 0) return 0;

    int channels = channels_;
    int totalOut = 0;
    int feedWindow = inputSamples;

    AVFrame *inFrame = av_frame_alloc();

    for (int pos = 0; pos < inputSamples;) {
        int chunk = std::min(feedWindow, inputSamples - pos);
        chunk = (chunk / channels) * channels;
        if (chunk <= 0) break;

        av_frame_unref(inFrame);
        inFrame->format = AV_SAMPLE_FMT_FLT;
        inFrame->nb_samples = chunk / channels;
        av_channel_layout_default(&inFrame->ch_layout, channels);
        inFrame->sample_rate = sampleRate_;

        if (av_frame_get_buffer(inFrame, 0) < 0) break;
        std::memcpy(inFrame->data[0], input + pos, chunk * sizeof(float));
        pos += chunk;

        int ret = av_buffersrc_add_frame_flags(srcCtx_, inFrame, AV_BUFFERSRC_FLAG_KEEP_REF);
        av_frame_unref(inFrame);
        if (ret < 0) break;

        // 取出所有可用的输出帧
        while (true) {
            AVFrame *outFrame = av_frame_alloc();
            ret = av_buffersink_get_frame(sinkCtx_, outFrame);
            if (ret < 0) {
                av_frame_free(&outFrame);
                break;
            }

            int outSamples;
            if (outFrame->format == AV_SAMPLE_FMT_FLTP) {
                int frames = outFrame->nb_samples;
                outSamples = frames * channels;
                if (totalOut + outSamples <= outputBufSize) {
                    float *dst = outputBuf + totalOut;
                    for (int ch = 0; ch < channels; ++ch) {
                        const float *src = (const float *) outFrame->extended_data[ch];
                        for (int s = 0; s < frames; ++s) {
                            dst[s * channels + ch] = src[s];
                        }
                    }
                    totalOut += outSamples;
                }
            } else {
                outSamples = outFrame->nb_samples * channels;
                if (totalOut + outSamples <= outputBufSize) {
                    std::memcpy(outputBuf + totalOut, outFrame->data[0], outSamples * sizeof(float));
                    totalOut += outSamples;
                }
            }
            av_frame_free(&outFrame);
        }
    }

    av_frame_free(&inFrame);
    return totalOut;
}

// 发送 NULL 帧通知滤镜结束，取完缓冲中剩余的拉伸数据
int SpeedSwitch::flush(float *outputBuf, int outputBufSize)
{
    if (!ready_) return 0;

    int ret = av_buffersrc_add_frame_flags(srcCtx_, nullptr, 0);
    if (ret < 0) return 0;

    int channels = channels_;
    int totalOut = 0;

    while (true) {
        AVFrame *outFrame = av_frame_alloc();
        ret = av_buffersink_get_frame(sinkCtx_, outFrame);
        if (ret < 0) {
            av_frame_free(&outFrame);
            break;
        }

        int outSamples;
        if (outFrame->format == AV_SAMPLE_FMT_FLTP) {
            int frames = outFrame->nb_samples;
            outSamples = frames * channels;
            if (totalOut + outSamples <= outputBufSize) {
                float *dst = outputBuf + totalOut;
                for (int ch = 0; ch < channels; ++ch) {
                    const float *src = (const float *) outFrame->extended_data[ch];
                    for (int s = 0; s < frames; ++s) {
                        dst[s * channels + ch] = src[s];
                    }
                }
                totalOut += outSamples;
            }
        } else {
            outSamples = outFrame->nb_samples * channels;
            if (totalOut + outSamples <= outputBufSize) {
                std::memcpy(outputBuf + totalOut, outFrame->data[0], outSamples * sizeof(float));
                totalOut += outSamples;
            }
        }
        av_frame_free(&outFrame);
    }

    return totalOut;
}
