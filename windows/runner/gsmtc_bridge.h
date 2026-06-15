// gsmtc_bridge.h
// Phase 2 – Windows GSMTC (Global System Media Transport Controls) bridge
// Polls the current media session every ~2 s on a background thread.
// When the track changes, marshals metadata + album-art bytes to the
// Flutter muvi/media MethodChannel via DrainPending() on the platform thread.
// Also handles inbound control calls on muvi/controls.
#pragma once

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/method_result.h>
#include <flutter/encodable_value.h>
#include <flutter/binary_messenger.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <thread>
#include <atomic>
#include <mutex>
#include <string>
#include <vector>
#include <optional>

struct PendingMediaInfo {
  std::string title;
  std::string artist;
  std::string album;
  std::vector<uint8_t> art_bytes;  // JPEG raw bytes; empty when no art
  int64_t duration_ms = 0;
  int64_t position_ms = 0;
};

class GsmtcBridge {
 public:
  explicit GsmtcBridge(flutter::BinaryMessenger* messenger);
  ~GsmtcBridge();

  void Start();
  void Stop();

  /// Call from the platform thread (WM_TIMER) to forward any queued
  /// media-info update to Flutter.
  void DrainPending();

 private:
  void PollLoop();

  flutter::BinaryMessenger* messenger_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> media_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> control_channel_;

  std::thread poll_thread_;
  std::atomic<bool> running_{false};

  std::mutex pending_mutex_;
  std::optional<PendingMediaInfo> pending_;
  std::string last_title_;  // used by poll thread to detect changes
};
