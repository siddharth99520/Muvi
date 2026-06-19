import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'player_provider.dart';

enum LyricsStatus { initial, loading, loaded, notFound, offline, error }

class LyricsLine {
  final Duration timestamp;
  final String text;
  LyricsLine(this.timestamp, this.text);
}

class LyricsProvider extends ChangeNotifier {
  final PlayerProvider _playerProvider;
  LyricsStatus _status = LyricsStatus.initial;
  List<LyricsLine>? _syncedLyrics;
  String? _plainLyrics;
  String? _source;
  String _currentTrackId = '';

  LyricsStatus get status => _status;
  List<LyricsLine>? get syncedLyrics => _syncedLyrics;
  String? get plainLyrics => _plainLyrics;
  String? get source => _source;

  LyricsProvider(this._playerProvider) {
    _playerProvider.addListener(_onPlayerStateChanged);
  }

  @override
  void dispose() {
    _playerProvider.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    final track = _playerProvider.state.currentTrack;
    if (track == null) {
      _status = LyricsStatus.initial;
      notifyListeners();
      return;
    }
    final trackId = "${track.title}-${track.artist}";
    if (trackId != _currentTrackId) {
      _currentTrackId = trackId;
      _fetchLyrics(track.title, track.artist ?? '');
    }
  }

  Future<void> retry() async {
    final track = _playerProvider.state.currentTrack;
    if (track != null) {
      await _fetchLyrics(track.title, track.artist ?? '');
    }
  }

  Future<void> _fetchLyrics(String title, String artist) async {
    _status = LyricsStatus.loading;
    notifyListeners();
    // Implementation placeholder
    _status = LyricsStatus.notFound;
    notifyListeners();
  }
}
