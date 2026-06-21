# Muvi — Flutter Windows Music Companion

A borderless, glassmorphic Windows desktop app that reads the currently playing media (via Windows GSMTC), captures system audio via WASAPI loopback, runs a real-time FFT, and drives a live bar visualizer — built with Flutter.

---

## ✨ Features

- 🎵 **Live Media Detection** — reads Spotify / any Windows media via GSMTC
- 📊 **Real-time FFT Visualizer** — 32-band bar spectrum powered by WASAPI loopback + Kiss FFT
- 🎤 **Synchronized Lyrics** — Fetches time-synced lyrics from lrclib and plain text from Genius
- 🪟 **Borderless Window** — custom title bar with macOS-style controls via `bitsdojo_window`
- 🌫️ **Acrylic / Frosted Glass** — native Windows acrylic effect via `flutter_acrylic`
- 🎨 **Premium UI** — deep navy + violet/cyan palette, Space Grotesk + Inter typography

---

## 🖼️ UI Layout

```
┌──────────────────────────────────────────────────────────────┐
│  ● ●   M U V I                          ◉ DETECTING MEDIA   │
├───────────────────┬──────────────────────────────────────────┤
│                   │  [ SPECTRUM ]  [ LYRICS ]                │
│   [Album Art]     │                                          │
│                   │    ████ █  ████  █  ███  ████  █  ████  │
│  Song Title       │         LIVE SPECTRUM                    │
│  Artist Name      │    20Hz      500Hz      8kHz    20kHz   │
│  Album            │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
│                   │    [Lyrics tab: auto-scrolling,          │
│  ═══════════════  │     active line highlighted + zoom]      │
│  ◀◀  ▶▶  ▶▶▶     │                                          │
│  ⚙ Settings       │                              ↺ SYNC     │
└───────────────────┴──────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.x (Windows desktop) |
| Window chrome | `bitsdojo_window` |
| Acrylic effect | `flutter_acrylic` |
| Fullscreen / window control | `window_manager` |
| State management | `provider` |
| Persistent settings | `shared_preferences` |
| Typography | Google Fonts (Space Grotesk, Inter) |
| Image caching | `cached_network_image` |
| Color extraction | `palette_generator` |
| App versioning | `package_info_plus` |
| Media detection | Windows GSMTC (C++ platform channel) |
| Audio capture | WASAPI Loopback (C++ platform channel) |
| FFT | Kiss FFT — single-header C library |
| Lyrics (synced) | [lrclib.net](https://lrclib.net) API |
| Lyrics (fallback) | [Genius](https://genius.com) scraping |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0 with Windows desktop support enabled
- Visual Studio 2022 with "Desktop development with C++" workload
- Windows 10/11 (build 1903+) for acrylic support

### Run

```powershell
flutter pub get
flutter run -d windows
```

### Build (release)

```powershell
flutter build windows --release
```

---

## 📁 Project Structure

```
lib/
├── main.dart                        # Entry: acrylic init + bitsdojo + window_manager
├── app.dart                         # MaterialApp + theme
├── models/
│   └── player_state.dart            # Immutable song + FFT state
├── providers/
│   ├── player_provider.dart         # GSMTC media + WASAPI FFT channel bridge
│   ├── lyrics_provider.dart         # Dual-source lyrics engine (lrclib + Genius)
│   └── settings_provider.dart       # Persisted settings (shared_preferences)
├── screens/
│   └── home_screen.dart             # Two-column split layout + F11 fullscreen
├── widgets/
│   ├── title_bar.dart               # Custom borderless title bar
│   ├── album_art_panel.dart         # Art, song info, progress bar, controls
│   ├── visualizer_panel.dart        # Tab container: Spectrum ↔ Lyrics toggle
│   ├── visualizer_painter.dart      # CustomPainter: 32 FFT bars
│   ├── lyrics_panel.dart            # Auto-scrolling synced lyrics + sync button
│   └── settings_dialog.dart         # Settings sheet (bar count, theme, opacity)
└── theme/app_theme.dart             # Color palette + typography tokens

windows/
├── CMakeLists.txt                   # Top-level Windows build
├── flutter/CMakeLists.txt           # Flutter SDK integration
└── runner/
    ├── main.cpp                     # WinMain entry
    ├── flutter_window.{h,cpp}       # Flutter view host
    ├── win32_window.{h,cpp}         # DPI-aware Win32 base
    ├── utils.{h,cpp}                # Console + UTF helpers
    └── Runner.rc                    # App version + icon resource
```

---

## 🗺️ Roadmap

- [x] Phase 1: Scaffold, UI, mock animated visualizer, window styling
- [x] Phase 2: GSMTC C++ platform channel — real media metadata
- [x] Phase 2: WASAPI loopback + Kiss FFT → real audio visualizer
- [x] Phase 3: Settings panel (bar count, color themes, opacity)
- [x] Phase 3: Album art dominant color extraction
- [x] Phase 4: Live synced lyrics engine (lrclib + genius fallbacks)

---

## 📜 License

MIT © 2024 Muvi
