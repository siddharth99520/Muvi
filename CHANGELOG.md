# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-06-20

### Added
- **Live Lyrics Engine:** Dual-source lyrics engine powered by `lrclib.net` (time-synced LRC) with `genius.com` as a plain-text fallback.
- **Lyrics Panel UI:** Auto-scrolling, responsive lyrics panel with active-line highlighting, zoom scaling, and precise centering.
- **Tab Navigation:** Seamless toggle between the Live Spectrum visualizer and the Lyrics view inside the right panel.
- **Sync Recovery:** Manual scroll detection with a floating ↺ sync button to resume auto-tracking at any time.
- **Fullscreen Support:** F11 toggles true fullscreen via `window_manager`; layout and scroll math adapts dynamically.
- **Settings Dialog:** Persistent settings panel (bar count, color theme, opacity) backed by `shared_preferences`.
- **App Versioning:** Version string surfaced inside the Settings / About section via `package_info_plus`.
- **Image Caching:** Album art loaded and cached with `cached_network_image` for flicker-free transitions.
- **Color Extraction:** `palette_generator` derives dominant album colors for dynamic theme tinting.

### Changed
- Smooth zoom transitions and anti-jitter layout math for active lyrics lines.
- Fully overhauled the `ListView` scrolling algorithm to handle edge cases like fullscreen transitions and lazy rendering.
- `visualizer_panel.dart` refactored into a tab container (Spectrum ↔ Lyrics) rather than a single-purpose visualizer host.

## [1.0.0] - Initial Release

### Added
- Windows media session integration using C++ bridging.
- Real-time WASAPI audio capture for system loopback.
- Dynamic FFT visualizer with customizable 8, 16, or 32 bands.
- Smooth Apple Music-style fluid mesh gradient background that reacts to bass intensity.
- Extracted dominant colors from the current album art for dynamic theme tinting.
- Playback controls (Play, Pause, Skip, Previous).
- Frameless window with custom draggable title bar.
- Install wizard via Inno Setup.
