import 'dart:typed_data';

enum PlaybackStatus { playing, paused, stopped }

class PlayerState {
  final String title;
  final String artist;
  final String album;
  final Duration position;
  final Duration duration;
  final PlaybackStatus status;
  final Uint8List? albumArtBytes; // From GSMTC (Phase 2)
  final List<double> fftBands; // 32 normalized [0.0–1.0] values

  const PlayerState({
    required this.title,
    required this.artist,
    required this.album,
    required this.position,
    required this.duration,
    required this.status,
    this.albumArtBytes,
    required this.fftBands,
  });

  static PlayerState get mock => PlayerState(
        title: 'Neon Reverie',
        artist: 'Synthwave Collective',
        album: 'Digital Dreams',
        position: const Duration(minutes: 1, seconds: 42),
        duration: const Duration(minutes: 3, seconds: 54),
        status: PlaybackStatus.playing,
        albumArtBytes: null,
        fftBands: List.filled(32, 0.0),
      );

  PlayerState copyWith({
    String? title,
    String? artist,
    String? album,
    Duration? position,
    Duration? duration,
    PlaybackStatus? status,
    Uint8List? albumArtBytes,
    List<double>? fftBands,
  }) {
    return PlayerState(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      albumArtBytes: albumArtBytes ?? this.albumArtBytes,
      fftBands: fftBands ?? this.fftBands,
    );
  }
}
