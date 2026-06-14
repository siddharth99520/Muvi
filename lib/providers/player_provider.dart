import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/player_state.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerState _state = PlayerState.mock;
  PlayerState get state => _state;

  // Platform channels (Phase 2)
  static const _mediaChannel = MethodChannel('muvi/media');
  static const _controlChannel = MethodChannel('muvi/controls');
  static const _audioChannel = EventChannel('muvi/audio_visualizer');

  Timer? _mockTimer;
  Timer? _progressTimer;
  final Random _rand = Random();

  // Mock FFT animation state
  final List<double> _targets = List.filled(32, 0.0);
  final List<double> _current = List.filled(32, 0.0);
  double _mockTime = 0.0;

  PlayerProvider() {
    _startMockVisualizer();
    _startProgressTimer();
    _tryConnectNative();
  }

  // ──────────────────────────────────────────────
  // Mock animated visualizer (Phase 1)
  // ──────────────────────────────────────────────
  void _startMockVisualizer() {
    _mockTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _mockTime += 0.05;
      _updateMockBands();
      _state = _state.copyWith(fftBands: List<double>.from(_current));
      notifyListeners();
    });
  }

  void _updateMockBands() {
    for (int i = 0; i < 32; i++) {
      // Simulate a frequency curve: bass heavy, mid present, treble drops
      final freqWeight = i < 6
          ? 0.85
          : i < 14
              ? 0.65
              : i < 24
                  ? 0.45
                  : 0.25;

      // Multiple sine waves to look organic
      final wave1 = sin(_mockTime * 1.3 + i * 0.4) * 0.4;
      final wave2 = sin(_mockTime * 2.7 + i * 0.9) * 0.25;
      final wave3 = sin(_mockTime * 0.8 + i * 1.2) * 0.2;
      final noise = (_rand.nextDouble() - 0.5) * 0.15;

      _targets[i] =
          ((wave1 + wave2 + wave3 + noise + 0.5) * freqWeight).clamp(0.05, 1.0);

      // Smooth interpolation (attack fast, decay slow)
      final diff = _targets[i] - _current[i];
      _current[i] += diff * (diff > 0 ? 0.4 : 0.15);
    }
  }

  void _startProgressTimer() {
    if (_state.status == PlaybackStatus.playing) {
      _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final next = _state.position + const Duration(seconds: 1);
        if (next >= _state.duration) {
          _state = _state.copyWith(position: _state.duration);
        } else {
          _state = _state.copyWith(position: next);
        }
        notifyListeners();
      });
    }
  }

  // ──────────────────────────────────────────────
  // Playback control (mock in Phase 1)
  // ──────────────────────────────────────────────
  void playPause() {
    final newStatus = _state.status == PlaybackStatus.playing
        ? PlaybackStatus.paused
        : PlaybackStatus.playing;
    _state = _state.copyWith(status: newStatus);

    if (newStatus == PlaybackStatus.playing) {
      _startProgressTimer();
    } else {
      _progressTimer?.cancel();
    }
    notifyListeners();

    // Phase 2: send to native
    _controlChannel
        .invokeMethod(newStatus == PlaybackStatus.playing ? 'play' : 'pause')
        .catchError((_) {});
  }

  void next() {
    // Phase 2: invoke native next
    _controlChannel.invokeMethod('next').catchError((_) {});
    // Mock: reset progress
    _state = _state.copyWith(position: Duration.zero);
    notifyListeners();
  }

  void previous() {
    _controlChannel.invokeMethod('previous').catchError((_) {});
    _state = _state.copyWith(position: Duration.zero);
    notifyListeners();
  }

  void seek(double fraction) {
    final ms = (fraction * _state.duration.inMilliseconds).round();
    _state = _state.copyWith(position: Duration(milliseconds: ms));
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Phase 2 native bridge (silently fails in Phase 1)
  // ──────────────────────────────────────────────
  void _tryConnectNative() {
    _mediaChannel.setMethodCallHandler((call) async {
      if (call.method == 'onMediaChanged') {
        final data = call.arguments as Map;
        _state = _state.copyWith(
          title: data['title'] as String? ?? _state.title,
          artist: data['artist'] as String? ?? _state.artist,
          albumArtBytes: data['albumArt'] as Uint8List?,
        );
        notifyListeners();
      }
    });

    _audioChannel.receiveBroadcastStream().listen((data) {
      if (data is List) {
        final bands = data.cast<double>();
        _state = _state.copyWith(fftBands: bands);
        _mockTimer?.cancel(); // Stop mock once real data arrives
        notifyListeners();
      }
    }).onError((_) {}); // Silently ignore until Phase 2
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }
}
