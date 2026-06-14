#include "sdl_audio_output.h"
#include <cstring>

SDLAudioOutput::SDLAudioOutput() {}

// 析构时关闭音频设备并退出 SDL 音频子系统
SDLAudioOutput::~SDLAudioOutput() { close(); }

bool SDLAudioOutput::open(RingBuffer &ringBuf, int sampleRate, int channels) {
    ringBuf_ = &ringBuf;

    // 配置 SDL 音频规格：FLT32 / 44100Hz / 双声道，与解码器输出一致
    SDL_AudioSpec want;
    SDL_zero(want);
    want.freq     = sampleRate;
    want.format   = AUDIO_F32;
    want.channels = static_cast<Uint8>(channels);
    want.samples  = 4096;                 // 每次回调请求的采样数
    want.callback = audioCallback;
    want.userdata = this;

    devId_ = SDL_OpenAudioDevice(nullptr, 0, &want, &spec_, 0);
    if (devId_ <= 0) {
        ringBuf_ = nullptr;
        return false;
    }
    return true;
}

void SDLAudioOutput::close() {
    if (devId_ > 0) {
        SDL_CloseAudioDevice(devId_);
        devId_ = 0;
    }
    ringBuf_ = nullptr;
}

// 取消暂停，SDL 继续从回调中拉取数据
void SDLAudioOutput::play() {
    if (devId_ > 0) {
        SDL_PauseAudioDevice(devId_, 0);
        playing_.store(true);
    }
}

// 暂停 SDL 音频设备，回调不再被调用
void SDLAudioOutput::pause() {
    if (devId_ > 0) {
        SDL_PauseAudioDevice(devId_, 1);
        playing_.store(false);
    }
}

// 停止播放：暂停并清空设备内部缓冲
void SDLAudioOutput::stop() {
    if (devId_ > 0) {
        SDL_PauseAudioDevice(devId_, 1);
        SDL_ClearQueuedAudio(devId_);
        playing_.store(false);
    }
}

void SDLAudioOutput::setVolume(float vol) {
    volume_.store(vol < 0.f ? 0.f : (vol > 1.f ? 1.f : vol));
}

float SDLAudioOutput::volume() const {
    return volume_.load();
}

// SDL 音频回调：从 RingBuffer 读取 PCM 数据，不足时静音填充，然后应用音量
void SDLAudioOutput::audioCallback(void *userdata, uint8_t *stream, int len) {
    auto *self = static_cast<SDLAudioOutput *>(userdata);
    SDL_memset(stream, 0, len); // 先填充静音

    if (!self->ringBuf_) return;

    size_t got = self->ringBuf_->read(stream, static_cast<size_t>(len));
    // 不足部分保持静音（已 memset）

    // 应用音量：对 float32 采样值乘以 volume 系数
    float vol = self->volume_.load();
    if (vol < 1.0f && got > 0) {
        auto *samples = reinterpret_cast<float *>(stream);
        size_t count = got / sizeof(float);
        for (size_t i = 0; i < count; ++i) {
            samples[i] *= vol;
        }
    }
}
