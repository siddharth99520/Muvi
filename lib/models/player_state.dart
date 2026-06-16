import 'dart:typed_data';
import 'package:flutter/material.dart';

enum PlaybackStatus { playing, paused, stopped }

class PlayerState {
  final String title;
  final String artist;
  final String album;
  final Duration position;
  final Duration duration;
  final PlaybackStatus status;
  final Uint8List? albumArtBytes; // From GSMTC (Phase 2)
  final Color? dominantColor; // Extracted via PaletteGenerator
  final Color? vibrantColor; // Extracted via PaletteGenerator
  final List<double> fftBands; // 16 normalized [0.0–1.0] values
  final bool isLive; // true once native channels are active

  const PlayerState({
    required this.title,
    required this.artist,
    required this.album,
    required this.position,
    required this.duration,
    required this.status,
    this.albumArtBytes,
    this.dominantColor,
    this.vibrantColor,
    required this.fftBands,
    this.isLive = false,
  });

  static PlayerState get mock => PlayerState(
        title: 'Neon Reverie',
        artist: 'Synthwave Collective',
        album: 'Digital Dreams',
        position: const Duration(minutes: 1, seconds: 42),
        duration: const Duration(minutes: 3, seconds: 54),
        status: PlaybackStatus.playing,
        albumArtBytes: null,
        dominantColor: null,
        vibrantColor: null,
        fftBands: List.filled(16, 0.0),
        isLive: false,
      );

  PlayerState copyWith({
    String? title,
    String? artist,
    String? album,
    Duration? position,
    Duration? duration,
    PlaybackStatus? status,
    Uint8List? albumArtBytes,
    Color? dominantColor,
    Color? vibrantColor,
    List<double>? fftBands,
    bool? isLive,
  }) {
    return PlayerState(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      albumArtBytes: albumArtBytes ?? this.albumArtBytes,
      dominantColor: dominantColor ?? this.dominantColor,
      vibrantColor: vibrantColor ?? this.vibrantColor,
      fftBands: fftBands ?? this.fftBands,
      isLive: isLive ?? this.isLive,
    );
  }
}
