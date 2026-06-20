# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-06-20

### Added
- **Live Lyrics Engine:** Added a dual-source lyrics engine powered by `lrclib.net` (for time-synced lyrics) and `genius.com` (for plain text fallbacks).
- **Lyrics Panel UI:** A beautiful, responsive, auto-scrolling lyrics panel with active line highlighting and precise centering.
- **Tab Navigation:** Seamless toggle between the Live Spectrum visualizer and the new Lyrics view.
- **Sync Recovery:** Manual scroll detection with a floating sync button to easily resume auto-tracking lyrics.
- **Settings & About:** Added app versioning visibility and a professional about section inside the settings dialog.

### Changed
- Smooth zoom transitions and anti-jitter layout math for active lyrics.
- Fully overhauled the `ListView` scrolling algorithm to handle edge cases like fullscreen transitions and lazy rendering.

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
