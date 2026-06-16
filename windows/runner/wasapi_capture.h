// wasapi_capture.h
// Phase 2 – WASAPI loopback capture + real-time FFT → 32 log-spaced bands
// Runs a dedicated background thread; the platform thread drains pending
// band data at ~20 Hz via DrainPending(), which calls the EventChannel sink.
#pragma once

#include <windows.h>
#include <mmdeviceapi.h>
#include <audioclient.h>
#include <wrl/client.h>

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler.h>
#include <flutter/encodable_value.h>
#include <flutter/binary_messenger.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <thread>
#include <atomic>
#include <mutex>
#include <vector>
#include <array>
#include <complex>

static constexpr int kFFTSize   = 1024;  // FFT window (power of 2)
static constexpr int kBandCount = 32;    // output bands

// StreamHandler that stores the EventSink given to it by Flutter.
class AudioStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink;

 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnListenInternal(
      const flutter::EncodableValue* /*args*/,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& s)
      override {
    sink = std::move(s);
    return nullptr;
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnCancelInternal(const flutter::EncodableValue* /*args*/) override {
    sink = nullptr;
    return nullptr;
  }
};

class WasapiCapture {
 public:
  explicit WasapiCapture(flutter::BinaryMessenger* messenger);
  ~WasapiCapture();

  void Start();
  void Stop();

  /// Called from the platform thread (WM_TIMER) to push the latest bands
  /// to the Flutter EventChannel sink.
  void DrainPending();

 private:
  void CaptureLoop();
  void ProcessFrames(const BYTE* buffer, UINT32 frames,
                     UINT32 channels, UINT32 sample_rate, bool silent);
  void ComputeAndStoreBands(UINT32 sample_rate);

  static void FFT(std::vector<std::complex<float>>& data);

  flutter::BinaryMessenger* messenger_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  AudioStreamHandler* stream_handler_ = nullptr;  // owned by event_channel_

  std::thread capture_thread_;
  std::atomic<bool> running_{false};

  // Shared between capture thread (writer) and platform thread (reader).
  std::mutex bands_mutex_;
  std::array<double, kBandCount> latest_bands_{};
  bool has_new_bands_ = false;

  // Sample accumulation buffer (capture thread only).
  std::vector<float> sample_buf_;

  // Running peak for normalization (capture thread only).
  float peak_ = 1.0e-6f;
};
