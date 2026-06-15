// wasapi_capture.cpp
// Phase 2 – WASAPI loopback + Cooley-Tukey FFT → 32 perceptual bands
#include "wasapi_capture.h"

#include <initguid.h>
#include <mmdeviceapi.h>
#include <audioclient.h>
#include <functiondiscoverykeys_devpkey.h>

#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "mmdevapi.lib")

#include <cmath>
#include <algorithm>
#include <numeric>
#include <cassert>

using Microsoft::WRL::ComPtr;

// ─────────────────────────────────────────────────────────────────────────────
// Construction / destruction
// ─────────────────────────────────────────────────────────────────────────────

WasapiCapture::WasapiCapture(flutter::BinaryMessenger* messenger)
    : messenger_(messenger) {
  auto handler = std::make_unique<AudioStreamHandler>();
  stream_handler_ = handler.get();

  event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger_, "muvi/audio_visualizer",
          &flutter::StandardMethodCodec::GetInstance());

  event_channel_->SetStreamHandler(std::move(handler));
}

WasapiCapture::~WasapiCapture() {
  Stop();
}

// ─────────────────────────────────────────────────────────────────────────────
// Start / Stop
// ─────────────────────────────────────────────────────────────────────────────

void WasapiCapture::Start() {
  running_ = true;
  capture_thread_ = std::thread(&WasapiCapture::CaptureLoop, this);
}

void WasapiCapture::Stop() {
  running_ = false;
  if (capture_thread_.joinable()) capture_thread_.join();
}

// ─────────────────────────────────────────────────────────────────────────────
// DrainPending — called from the platform thread via WM_TIMER
// ─────────────────────────────────────────────────────────────────────────────

void WasapiCapture::DrainPending() {
  if (!stream_handler_ || !stream_handler_->sink) return;

  std::array<double, kBandCount> bands{};
  {
    std::lock_guard<std::mutex> lk(bands_mutex_);
    if (!has_new_bands_) return;
    bands = latest_bands_;
    has_new_bands_ = false;
  }

  // Build EncodableList of doubles and push to Dart
  flutter::EncodableList list;
  list.reserve(kBandCount);
  for (double v : bands) list.emplace_back(v);

  stream_handler_->sink->Success(flutter::EncodableValue(list));
}

// ─────────────────────────────────────────────────────────────────────────────
// Background capture loop
// ─────────────────────────────────────────────────────────────────────────────

void WasapiCapture::CaptureLoop() {
  // COM must be initialised on every thread that uses COM/WASAPI
  HRESULT hr = ::CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  bool com_init = SUCCEEDED(hr);

  do {
    if (FAILED(hr)) break;

    // ── Device enumerator ──────────────────────────────────────────
    ComPtr<IMMDeviceEnumerator> enumerator;
    hr = ::CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr,
                            CLSCTX_ALL, IID_PPV_ARGS(&enumerator));
    if (FAILED(hr)) break;

    // ── Default render (speaker/headphone) endpoint ───────────────
    ComPtr<IMMDevice> device;
    hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
    if (FAILED(hr)) break;

    // ── Activate audio client ─────────────────────────────────────
    ComPtr<IAudioClient> audio_client;
    hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr,
                          reinterpret_cast<void**>(audio_client.GetAddressOf()));
    if (FAILED(hr)) break;

    // ── Query mix format ──────────────────────────────────────────
    WAVEFORMATEX* pwfx = nullptr;
    hr = audio_client->GetMixFormat(&pwfx);
    if (FAILED(hr)) break;

    UINT32 sample_rate = pwfx->nSamplesPerSec;
    UINT32 channels    = pwfx->nChannels;

    // ── Initialise in loopback shared mode (100 ms buffer) ───────
    hr = audio_client->Initialize(
        AUDCLNT_SHAREMODE_SHARED,
        AUDCLNT_STREAMFLAGS_LOOPBACK,
        1'000'000,   // 100 ms in 100-ns units
        0,
        pwfx,
        nullptr);

    ::CoTaskMemFree(pwfx);
    pwfx = nullptr;

    if (FAILED(hr)) break;

    // ── Get capture client ────────────────────────────────────────
    ComPtr<IAudioCaptureClient> capture_client;
    hr = audio_client->GetService(IID_PPV_ARGS(&capture_client));
    if (FAILED(hr)) break;

    hr = audio_client->Start();
    if (FAILED(hr)) break;

    sample_buf_.clear();
    sample_buf_.reserve(kFFTSize * 2);

    // ── Capture loop ──────────────────────────────────────────────
    while (running_) {
      UINT32 packet_size = 0;
      hr = capture_client->GetNextPacketSize(&packet_size);
      if (FAILED(hr)) break;

      while (packet_size > 0 && running_) {
        BYTE*  data   = nullptr;
        UINT32 frames = 0;
        DWORD  flags  = 0;
        hr = capture_client->GetBuffer(&data, &frames, &flags, nullptr, nullptr);
        if (FAILED(hr)) break;

        bool silent = (flags & AUDCLNT_BUFFERFLAGS_SILENT) != 0;
        ProcessFrames(data, frames, channels, sample_rate, silent);

        capture_client->ReleaseBuffer(frames);
        capture_client->GetNextPacketSize(&packet_size);
      }

      ::Sleep(10);  // poll ~100 times/sec; FFT fires whenever buffer fills
    }

    audio_client->Stop();

  } while(false);

  if (com_init) ::CoUninitialize();
}

// ─────────────────────────────────────────────────────────────────────────────
// ProcessFrames — mix down to mono float, accumulate, trigger FFT when full
// ─────────────────────────────────────────────────────────────────────────────

void WasapiCapture::ProcessFrames(const BYTE* buffer, UINT32 frames,
                                   UINT32 channels, UINT32 sample_rate,
                                   bool silent) {
  const float* src = reinterpret_cast<const float*>(buffer);

  for (UINT32 f = 0; f < frames; ++f) {
    float mono = 0.0f;
    if (silent) {
      mono = 0.0f;
    } else {
      for (UINT32 c = 0; c < channels; ++c)
        mono += src[f * channels + c];
      mono /= static_cast<float>(channels);
    }
    sample_buf_.push_back(mono);

    if (static_cast<int>(sample_buf_.size()) >= kFFTSize) {
      ComputeAndStoreBands(sample_rate);
      // 50 % overlap: keep second half
      std::copy(sample_buf_.begin() + kFFTSize / 2, sample_buf_.end(),
                sample_buf_.begin());
      sample_buf_.resize(sample_buf_.size() - kFFTSize / 2);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cooley–Tukey iterative radix-2 FFT (in-place, DIF)
// ─────────────────────────────────────────────────────────────────────────────

void WasapiCapture::FFT(std::vector<std::complex<float>>& data) {
  int n = static_cast<int>(data.size());

  // Bit-reversal permutation
  for (int i = 1, j = 0; i < n; ++i) {
    int bit = n >> 1;
    for (; j & bit; bit >>= 1) j ^= bit;
    j ^= bit;
    if (i < j) std::swap(data[i], data[j]);
  }

  // Butterfly stages
  for (int len = 2; len <= n; len <<= 1) {
    float ang = -2.0f * 3.14159265358979f / static_cast<float>(len);
    std::complex<float> wlen(std::cos(ang), std::sin(ang));
    for (int i = 0; i < n; i += len) {
      std::complex<float> w(1.0f, 0.0f);
      for (int j = 0; j < len / 2; ++j) {
        std::complex<float> u = data[i + j];
        std::complex<float> v = data[i + j + len / 2] * w;
        data[i + j]           = u + v;
        data[i + j + len / 2] = u - v;
        w *= wlen;
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ComputeAndStoreBands
// ─────────────────────────────────────────────────────────────────────────────

void WasapiCapture::ComputeAndStoreBands(UINT32 sample_rate) {
  // ── Hann window + build complex input ────────────────────────
  std::vector<std::complex<float>> cdata(kFFTSize);
  for (int i = 0; i < kFFTSize; ++i) {
    float hann = 0.5f * (1.0f - std::cos(2.0f * 3.14159265f * i / (kFFTSize - 1)));
    cdata[i] = {sample_buf_[i] * hann, 0.0f};
  }

  FFT(cdata);

  // ── Magnitude spectrum (first half only) ─────────────────────
  int half = kFFTSize / 2;
  std::vector<float> mag(half);
  for (int i = 0; i < half; ++i)
    mag[i] = std::abs(cdata[i]);

  // ── Map to 32 log-spaced bands (20 Hz – 20 kHz) ──────────────
  float freq_per_bin = static_cast<float>(sample_rate) / kFFTSize;
  float log_min = std::log10f(20.0f);
  float log_max = std::log10f(20000.0f);

  std::array<double, kBandCount> bands{};
  for (int b = 0; b < kBandCount; ++b) {
    float f_lo = std::pow(10.0f, log_min + (log_max - log_min) * b       / kBandCount);
    float f_hi = std::pow(10.0f, log_min + (log_max - log_min) * (b + 1) / kBandCount);

    int bin_lo = std::max(1,    static_cast<int>(f_lo / freq_per_bin));
    int bin_hi = std::min(half - 1, static_cast<int>(f_hi / freq_per_bin));

    if (bin_lo > bin_hi) bin_hi = bin_lo;

    float sum = 0.0f;
    for (int k = bin_lo; k <= bin_hi; ++k) sum += mag[k];
    bands[b] = static_cast<double>(sum / (bin_hi - bin_lo + 1));
  }

  // ── Peak normalization with slow decay ────────────────────────
  float cur_max = 0.0f;
  for (auto& v : bands) cur_max = std::max(cur_max, static_cast<float>(v));
  peak_ = std::max(peak_ * 0.998f, std::max(cur_max, 1.0e-6f));

  for (auto& v : bands) {
    v = static_cast<double>(v) / peak_;
    v = std::sqrt(v);   // mild sqrt compression → more visual punch
    v = std::min(1.0,   std::max(0.0, v));
  }

  // ── Store for DrainPending ────────────────────────────────────
  {
    std::lock_guard<std::mutex> lk(bands_mutex_);
    latest_bands_  = bands;
    has_new_bands_ = true;
  }
}
