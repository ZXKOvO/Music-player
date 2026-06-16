#pragma once
#include <SDL2/SDL_audio.h>
#include <atomic>
#include "ring_buffer.h"

// SDL2 音频输出：从 RingBuffer 读取 PCM 数据并播放
class SDLAudioOutput
{
public:
    SDLAudioOutput();
    ~SDLAudioOutput();

    // 打开音频设备，关联环形缓冲区，成功返回 true
    bool open(RingBuffer &ringBuf, int sampleRate, int channels);
    // 关闭音频设备，释放 SDL 资源
    void close();

    // 开始播放（取消暂停）
    void play();
    // 暂停播放
    void pause();
    // 停止播放并清空设备缓冲
    void stop();

    // 设置音量 (0.0 ~ 1.0)，在回调中对 PCM 采样值乘系数
    void setVolume(float vol);
    float volume() const;

    bool isPlaying() const { return playing_.load(); }
    bool isOpen() const { return devId_ > 0; }

private:
    // SDL 音频回调，从 RingBuffer 读取数据并应用音量
    static void audioCallback(void *userdata, uint8_t *stream, int len);

    SDL_AudioDeviceID devId_ = 0;
    SDL_AudioSpec spec_{};
    RingBuffer *ringBuf_ = nullptr; // 不持有所有权
    std::atomic<float> volume_{1.0f};
    std::atomic<bool> playing_{false};
};
