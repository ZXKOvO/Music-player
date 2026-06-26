#pragma once
#include <SDL2/SDL_audio.h>
#include <atomic>
#include <vector>
#include "ring_buffer.h"

// SDL2 音频输出：从 RingBuffer 读取 PCM 数据并播放
// 不处理变速，变速由解码线程中的 SpeedSwitch 完成
class SDLAudioOutput
{
public:
    SDLAudioOutput();
    ~SDLAudioOutput();

    bool open(RingBuffer &ringBuf, int sampleRate, int channels);
    void close();

    void play();
    void pause();
    void stop();

    void setVolume(float vol);
    float volume() const;

    bool isPlaying() const { return playing_.load(); }
    bool isOpen() const { return devId_ > 0; }

private:
    static void audioCallback(void *userdata, uint8_t *stream, int len);

    SDL_AudioDeviceID devId_ = 0;
    SDL_AudioSpec spec_{};
    RingBuffer *ringBuf_ = nullptr;
    std::atomic<float> volume_{1.0f};
    std::atomic<bool> playing_{false};
};
