import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../models/player_state.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerState _state = PlayerState.mock;
  PlayerState get state => _state;

  // Platform channels
  static const _mediaChannel   = MethodChannel('muvi/media');
  static const _controlChannel = MethodChannel('muvi/controls');
  static const _audioChannel   = EventChannel('muvi/audio_visualizer');

  Timer? _mockTimer;
  Timer? _progressTimer;
  final Random _rand = Random();

  // Mock FFT animation state
  final List<double> _targets = List.filled(16, 0.0);
  final List<double> _current = List.filled(16, 0.0);
  double _mockTime = 0.0;

  PlayerProvider() {
    // Defer all channel/timer init to after the first frame is painted so
    // notifyListeners() can never fire during build.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _startMockVisualizer();
      _startProgressTimer();
      _tryConnectNative();
    });
  }

  // ──────────────────────────────────────────────────────────────
  // Mock animated visualizer (active until native data arrives)
  // ──────────────────────────────────────────────────────────────
  void _startMockVisualizer() {
    _mockTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!hasListeners) return;
      _mockTime += 0.05;
      _updateMockBands();
      _state = _state.copyWith(fftBands: List<double>.from(_current));
      notifyListeners();
    });
  }

  void _updateMockBands() {
    for (int i = 0; i < 16; i++) {
      final freqWeight = i < 3
          ? 0.85
          : i < 7
              ? 0.65
              : i < 12
                  ? 0.45
                  : 0.25;

      final wave1 = sin(_mockTime * 1.3 + i * 0.4) * 0.4;
      final wave2 = sin(_mockTime * 2.7 + i * 0.9) * 0.25;
      final wave3 = sin(_mockTime * 0.8 + i * 1.2) * 0.2;
      final noise = (_rand.nextDouble() - 0.5) * 0.15;

      _targets[i] =
          ((wave1 + wave2 + wave3 + noise + 0.5) * freqWeight).clamp(0.05, 1.0);

      final diff = _targets[i] - _current[i];
      _current[i] += diff * (diff > 0 ? 0.4 : 0.15);
    }
  }

  void _startProgressTimer() {
    if (_state.status == PlaybackStatus.playing) {
      _progressTimer?.cancel();
      _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!hasListeners) return;
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

  // ──────────────────────────────────────────────────────────────
  // Playback controls — forwarded to native; also update local state
  // ──────────────────────────────────────────────────────────────
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

    _controlChannel
        .invokeMethod(newStatus == PlaybackStatus.playing ? 'play' : 'pause')
        .catchError((_) {});
  }

  void next() {
    _controlChannel.invokeMethod('next').catchError((_) {});
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
    _controlChannel.invokeMethod('seek', ms).catchError((_) {});
    _state = _state.copyWith(position: Duration(milliseconds: ms));
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────
  // Phase 2 — native bridge
  // Probes the control channel first; on MissingPluginException the app
  // continues in mock-only mode without error output.
  // ──────────────────────────────────────────────────────────────
  Future<void> _tryConnectNative() async {
    try {
      await _controlChannel.invokeMethod<bool>('checkConnection');
    } on MissingPluginException {
      return; // Native not available — stay in mock mode
    } catch (_) {
      // Native returned an error but IS registered; continue
    }

    // ── Media metadata channel (native → Dart) ──────────────────
    _mediaChannel.setMethodCallHandler((call) async {
      if (call.method == 'onMediaChanged') {
        final data = call.arguments as Map;
        final artBytes = data['albumArt'];
        final durationMs = data['durationMs'] as num?;
        final positionMs = data['positionMs'] as num?;
        
        _state = _state.copyWith(
          title: data['title'] as String? ?? _state.title,
          artist: data['artist'] as String? ?? _state.artist,
          album: data['album'] as String? ?? _state.album,
          albumArtBytes: artBytes is Uint8List ? artBytes : _state.albumArtBytes,
          duration: durationMs != null && durationMs > 0 
              ? Duration(milliseconds: durationMs.toInt()) 
              : _state.duration,
          position: positionMs != null && positionMs > 0 
              ? Duration(milliseconds: positionMs.toInt()) 
              : _state.position,
          isLive: true,
        );
        notifyListeners();
      }
    });

    // ── Audio visualizer EventChannel (native → Dart) ────────────
    _audioChannel.receiveBroadcastStream().listen(
      (data) {
        if (data is List) {
          // C++ sends EncodableList of doubles; Dart receives List<Object?>
          final bands = data.map((e) => (e as num).toDouble()).toList();
          _mockTimer?.cancel(); // Switch off mock once real data flows
          _state = _state.copyWith(fftBands: bands, isLive: true);
          notifyListeners();
        }
      },
      onError: (_) {}, // Ignore errors — mock visualizer stays active
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }
}
