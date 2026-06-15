#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <memory>

#include "win32_window.h"
#include "gsmtc_bridge.h"
#include "wasapi_capture.h"

// Timer ID used to drain pending native data onto the platform thread (~20 Hz)
static constexpr UINT_PTR kDrainTimerId = 0xDEAD;
static constexpr UINT     kDrainIntervalMs = 50;  // 20 Hz

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Phase 2 — native bridges
  std::unique_ptr<GsmtcBridge>   gsmtc_bridge_;
  std::unique_ptr<WasapiCapture> wasapi_capture_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
