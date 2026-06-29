#include "sdl_audio_output.h"
#include <cstring>
#include <algorithm>

SDLAudioOutput::SDLAudioOutput() {}

SDLAudioOutput::~SDLAudioOutput()
{
    close();
}

bool SDLAudioOutput::open(RingBuffer &ringBuf, int sampleRate, int channels)
{
    ringBuf_ = &ringBuf;

    SDL_AudioSpec want{};
    want.freq = sampleRate;
    want.format = AUDIO_F32;
    want.channels = static_cast<Uint8>(channels);
    want.samples = 4096;
    want.callback = audioCallback;
    want.userdata = this;

    devId_ = SDL_OpenAudioDevice(nullptr, 0, &want, &spec_, 0);
    if (devId_ <= 0) {
        ringBuf_ = nullptr;
        return false;
    }
    return true;
}

void SDLAudioOutput::close()
{
    if (devId_ > 0) {
        SDL_CloseAudioDevice(devId_);
        devId_ = 0;
    }
    ringBuf_ = nullptr;
}

void SDLAudioOutput::play()
{
    if (devId_ > 0) {
        SDL_PauseAudioDevice(devId_, 0);
        playing_.store(true);
    }
}

void SDLAudioOutput::pause()
{
    if (devId_ > 0) {
        SDL_PauseAudioDevice(devId_, 1);
        playing_.store(false);
    }
}

void SDLAudioOutput::setVolume(float vol)
{
    volume_.store(vol < 0.f ? 0.f : (vol > 1.f ? 1.f : vol));
}

float SDLAudioOutput::volume() const
{
    return volume_.load();
}

void SDLAudioOutput::audioCallback(void *userdata, uint8_t *stream, int len)
{
    auto *self = static_cast<SDLAudioOutput *>(userdata);
    SDL_memset(stream, 0, len);
    if (!self->ringBuf_) return;

    self->ringBuf_->read(stream, static_cast<size_t>(len));

    float vol = self->volume_.load();
    if (vol < 1.0f) {
        auto *s = reinterpret_cast<float *>(stream);
        size_t count = static_cast<size_t>(len) / sizeof(float);
        for (size_t i = 0; i < count; ++i)
            s[i] *= vol;
    }
}
