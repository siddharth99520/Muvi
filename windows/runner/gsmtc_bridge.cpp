// gsmtc_bridge.cpp
// Phase 2 – GSMTC media-session polling via C++/WinRT
//
// C++/WinRT requires exceptions; the /EHsc flag is already set by
// apply_standard_settings. The _HAS_EXCEPTIONS=0 macro only disables
// certain STL features (e.g. std::vector::at) and does NOT prevent the
// C++ exception mechanism used by winrt::hresult_error from working.
#include "gsmtc_bridge.h"

// ── C++/WinRT ─────────────────────────────────────────────────────────────
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Media.Control.h>
#include <winrt/Windows.Storage.Streams.h>

#pragma comment(lib, "WindowsApp.lib")

#include <chrono>

using namespace winrt;
using namespace Windows::Media::Control;
using namespace Windows::Storage::Streams;
using namespace Windows::Foundation;

// ─────────────────────────────────────────────────────────────────────────────
// Construction / destruction
// ─────────────────────────────────────────────────────────────────────────────

GsmtcBridge::GsmtcBridge(flutter::BinaryMessenger* messenger)
    : messenger_(messenger) {
  // ── muvi/media  (native → Dart) ───────────────────────────────────────────
  media_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger_, "muvi/media",
          &flutter::StandardMethodCodec::GetInstance());

  // ── muvi/controls  (Dart → native) ───────────────────────────────────────
  control_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger_, "muvi/controls",
          &flutter::StandardMethodCodec::GetInstance());

  control_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const auto& method = call.method_name();

        if (method == "checkConnection") {
          // Phase 2 is live — confirm connection
          result->Success(flutter::EncodableValue(true));
          return;
        }

        // Forward playback commands to GSMTC on a fire-and-forget thread
        // so we don't block the platform thread.
        std::string cmd = method;  // copy into lambda
        int64_t seek_ms = 0;
        
        if (cmd == "seek") {
          const auto* args = call.arguments();
          if (args) {
            if (std::holds_alternative<int32_t>(*args)) {
              seek_ms = std::get<int32_t>(*args);
            } else if (std::holds_alternative<int64_t>(*args)) {
              seek_ms = std::get<int64_t>(*args);
            } else if (std::holds_alternative<double>(*args)) {
              seek_ms = static_cast<int64_t>(std::get<double>(*args));
            }
          }
        }

        std::thread([cmd, seek_ms]() {
          try {
            winrt::init_apartment(winrt::apartment_type::multi_threaded);
            auto manager =
                GlobalSystemMediaTransportControlsSessionManager::RequestAsync()
                    .get();
            auto session = manager.GetCurrentSession();
            if (!session) { winrt::uninit_apartment(); return; }

            if (cmd == "play")
              session.TryPlayAsync().get();
            else if (cmd == "pause")
              session.TryPauseAsync().get();
            else if (cmd == "next")
              session.TrySkipNextAsync().get();
            else if (cmd == "previous")
              session.TrySkipPreviousAsync().get();
            else if (cmd == "seek" && seek_ms >= 0) {
              int64_t ticks = seek_ms * 10000LL;
              session.TryChangePlaybackPositionAsync(ticks).get();
            }

            winrt::uninit_apartment();
          } catch (...) {}
        }).detach();

        result->Success();
      });
}

GsmtcBridge::~GsmtcBridge() {
  Stop();
}

// ─────────────────────────────────────────────────────────────────────────────
// Start / Stop
// ─────────────────────────────────────────────────────────────────────────────

void GsmtcBridge::Start() {
  running_ = true;
  poll_thread_ = std::thread(&GsmtcBridge::PollLoop, this);
}

void GsmtcBridge::Stop() {
  running_ = false;
  if (poll_thread_.joinable()) poll_thread_.join();
}

// ─────────────────────────────────────────────────────────────────────────────
// DrainPending — called from the platform thread (WM_TIMER)
// ─────────────────────────────────────────────────────────────────────────────

void GsmtcBridge::DrainPending() {
  std::optional<PendingMediaInfo> info;
  {
    std::lock_guard<std::mutex> lk(pending_mutex_);
    if (!pending_.has_value()) return;
    info = std::move(pending_);
    pending_.reset();
  }

  if (!info.has_value()) return;

  flutter::EncodableMap args;
  args[flutter::EncodableValue("title")]  = flutter::EncodableValue(info->title);
  args[flutter::EncodableValue("artist")] = flutter::EncodableValue(info->artist);
  args[flutter::EncodableValue("album")]  = flutter::EncodableValue(info->album);
  args[flutter::EncodableValue("durationMs")] = flutter::EncodableValue(info->duration_ms);
  args[flutter::EncodableValue("positionMs")] = flutter::EncodableValue(info->position_ms);

  if (!info->art_bytes.empty()) {
    args[flutter::EncodableValue("albumArt")] =
        flutter::EncodableValue(info->art_bytes);
  }

  media_channel_->InvokeMethod(
      "onMediaChanged",
      std::make_unique<flutter::EncodableValue>(args));
}

// ─────────────────────────────────────────────────────────────────────────────
// PollLoop — runs on a dedicated background thread
// ─────────────────────────────────────────────────────────────────────────────

void GsmtcBridge::PollLoop() {
  try {
    winrt::init_apartment(winrt::apartment_type::multi_threaded);
  } catch (...) {
    return;
  }

  while (running_) {
    try {
      auto manager =
          GlobalSystemMediaTransportControlsSessionManager::RequestAsync()
              .get();
      auto session = manager.GetCurrentSession();

      if (session) {
        auto props = session.TryGetMediaPropertiesAsync().get();
        if (props) {
          std::string title  = winrt::to_string(props.Title());
          std::string artist = winrt::to_string(props.Artist());
          std::string album  = winrt::to_string(props.AlbumTitle());

          if (title != last_title_) {
            last_title_ = title;

            PendingMediaInfo info;
            info.title  = title;
            info.artist = artist;
            info.album  = album;

            // ── Timeline properties ─────────────────────────────
            try {
              auto timeline = session.GetTimelineProperties();
              if (timeline) {
                info.duration_ms = timeline.EndTime().count() / 10000LL;
                info.position_ms = timeline.Position().count() / 10000LL;
              }
            } catch (...) {}

            // ── Album art thumbnail ─────────────────────────────
            auto thumbnail = props.Thumbnail();
            if (thumbnail) {
              try {
                auto stream = thumbnail.OpenReadAsync().get();
                auto sz     = static_cast<uint32_t>(stream.Size());

                if (sz > 0 && sz < 8u * 1024 * 1024) {  // sanity: max 8 MB
                  DataReader reader{stream};
                  reader.LoadAsync(sz).get();
                  info.art_bytes.resize(sz);
                  reader.ReadBytes(info.art_bytes);
                }
              } catch (...) {
                // Art not available — proceed without it
              }
            }

            std::lock_guard<std::mutex> lk(pending_mutex_);
            pending_ = std::move(info);
          }
        }
      }
    } catch (...) {
      // GSMTC may not be available or session may have ended — ignore
    }

    // Poll every 2 seconds
    for (int i = 0; i < 20 && running_; ++i)
      std::this_thread::sleep_for(std::chrono::milliseconds(100));
  }

  try { winrt::uninit_apartment(); } catch (...) {}
}
