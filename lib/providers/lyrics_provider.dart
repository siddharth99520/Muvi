import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'player_provider.dart';

enum LyricsStatus { initial, loading, loaded, offline, notFound, error }

/// Which backend ultimately provided the lyrics.
enum LyricsSource { lrclib, genius, none }

/// Internal per-source fetch outcome.
enum _FetchStatus { found, notFound, networkError }

class _FetchResult {
  final _FetchStatus status;
  final Map<String, dynamic>? data;
  const _FetchResult(this.status, [this.data]);
}

class LyricsLine {
  final Duration timestamp;
  final String text;
  LyricsLine({required this.timestamp, required this.text});
}

class LyricsProvider extends ChangeNotifier {
  LyricsStatus _status = LyricsStatus.initial;
  LyricsStatus get status => _status;

  LyricsSource _source = LyricsSource.none;
  LyricsSource get source => _source;

  String? _plainLyrics;
  String? get plainLyrics => _plainLyrics;

  List<LyricsLine>? _syncedLyrics;
  List<LyricsLine>? get syncedLyrics => _syncedLyrics;

  String _currentTrackId = '';
  Timer? _debounceTimer;
  final PlayerProvider _playerProvider;

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  };

  LyricsProvider(this._playerProvider) {
    _playerProvider.addListener(_onPlayerStateChanged);
    _onPlayerStateChanged();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _playerProvider.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    final state = _playerProvider.state;
    final trackId = '${state.artist}|||${state.title}';

    if (trackId != _currentTrackId &&
        state.title.isNotEmpty &&
        state.title != 'Unknown Track') {
      _currentTrackId = trackId;

      // Debounce: cancel any pending fetch and wait 1.5s for the
      // track to settle (handles rapid skipping).
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
        _fetchLyrics(state.artist, state.title);
      });
    }
  }

  // Expose retry so the UI can trigger a fresh fetch.
  void retry() {
    final state = _playerProvider.state;
    if (state.title.isNotEmpty && state.title != 'Unknown Track') {
      _fetchLyrics(state.artist, state.title);
    }
  }

  Future<void> _fetchLyrics(String artist, String title) async {
    _status = LyricsStatus.loading;
    _plainLyrics = null;
    _syncedLyrics = null;
    _source = LyricsSource.none;
    notifyListeners();

    // Each source is fetched independently so that a network error from one
    // does not mask a "not found" result from the other.
    final lrclibResult = await _tryFetchFromLrclib(artist, title);
    if (lrclibResult.status == _FetchStatus.found) {
      _applyResult(lrclibResult.data!, LyricsSource.lrclib);
      notifyListeners();
      return;
    }

    final geniusResult = await _tryFetchFromGenius(artist, title);
    if (geniusResult.status == _FetchStatus.found) {
      _applyResult(geniusResult.data!, LyricsSource.genius);
      notifyListeners();
      return;
    }

    // Only report offline when EVERY source had a network error.
    // If at least one source responded (even with no results), we're online.
    final bothNetworkErrors =
        lrclibResult.status == _FetchStatus.networkError &&
        geniusResult.status == _FetchStatus.networkError;

    _status = bothNetworkErrors ? LyricsStatus.offline : LyricsStatus.notFound;
    notifyListeners();
  }

  void _applyResult(Map<String, dynamic> result, LyricsSource src) {
    _syncedLyrics = result['synced'] as List<LyricsLine>?;
    _plainLyrics = result['plain'] as String?;
    _source = src;
    _status = LyricsStatus.loaded;
  }

  // ────────────────────────────────────────────────────────────────────
  // lrclib: /api/search (fuzzy, no duration required)
  // ────────────────────────────────────────────────────────────────────
  Future<_FetchResult> _tryFetchFromLrclib(String artist, String title) async {
    try {
      final q = artist.isNotEmpty ? '$artist $title' : title;
      final uri = Uri.parse('https://lrclib.net/api/search')
          .replace(queryParameters: {'q': q});

      final response = await http
          .get(uri, headers: {'Lrclib-Client': 'Muvi/1.0.0'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return const _FetchResult(_FetchStatus.notFound);

      final list = json.decode(response.body) as List<dynamic>;
      if (list.isEmpty) return const _FetchResult(_FetchStatus.notFound);

      // Prefer synced, then plain
      Map<String, dynamic>? best;
      for (final item in list) {
        if ((item['syncedLyrics'] as String?)?.trim().isNotEmpty == true) {
          best = item as Map<String, dynamic>;
          break;
        }
      }
      if (best == null) {
        for (final item in list) {
          if ((item['plainLyrics'] as String?)?.trim().isNotEmpty == true) {
            best = item as Map<String, dynamic>;
            break;
          }
        }
      }

      if (best == null) return const _FetchResult(_FetchStatus.notFound);

      final syncedStr = best['syncedLyrics'] as String?;
      final plainStr = best['plainLyrics'] as String?;

      if ((syncedStr == null || syncedStr.trim().isEmpty) &&
          (plainStr == null || plainStr.trim().isEmpty)) {
        return const _FetchResult(_FetchStatus.notFound);
      }

      return _FetchResult(_FetchStatus.found, {
        'synced': (syncedStr?.trim().isNotEmpty == true)
            ? _parseSyncedLyrics(syncedStr!)
            : null,
        'plain': (plainStr?.trim().isNotEmpty == true) ? plainStr : null,
      });
    } on SocketException {
      return const _FetchResult(_FetchStatus.networkError);
    } on TimeoutException {
      return const _FetchResult(_FetchStatus.networkError);
    } catch (_) {
      return const _FetchResult(_FetchStatus.notFound);
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // Genius: internal search API → scrape lyrics page
  // Much larger catalogue, covers Tamil & other regional languages well
  // ────────────────────────────────────────────────────────────────────
  Future<_FetchResult> _tryFetchFromGenius(String artist, String title) async {
    try {
      final q = artist.isNotEmpty ? '$artist $title' : title;
      final searchUri =
          Uri.parse('https://genius.com/api/search/multi').replace(
        queryParameters: {'q': q, 'per_page': '5'},
      );

      final searchResp = await http
          .get(searchUri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (searchResp.statusCode != 200) {
        return const _FetchResult(_FetchStatus.notFound);
      }

      final data = json.decode(searchResp.body);
      final sections = data['response']?['sections'] as List<dynamic>?;
      if (sections == null || sections.isEmpty) {
        return const _FetchResult(_FetchStatus.notFound);
      }

      // Walk sections to find the first song hit URL
      String? songUrl;
      for (final section in sections) {
        final hits = section['hits'] as List<dynamic>?;
        if (hits != null && hits.isNotEmpty) {
          for (final hit in hits) {
            if (hit['type'] == 'song') {
              songUrl = hit['result']?['url'] as String?;
              if (songUrl != null) break;
            }
          }
        }
        if (songUrl != null) break;
      }

      if (songUrl == null) return const _FetchResult(_FetchStatus.notFound);

      // Fetch the lyrics HTML page
      final pageResp = await http
          .get(Uri.parse(songUrl), headers: _headers)
          .timeout(const Duration(seconds: 20));

      if (pageResp.statusCode != 200) return const _FetchResult(_FetchStatus.notFound);

      final lyrics = _parseGeniusHtml(pageResp.body);
      if (lyrics == null || lyrics.trim().isEmpty) {
        return const _FetchResult(_FetchStatus.notFound);
      }

      return _FetchResult(_FetchStatus.found, {'synced': null, 'plain': lyrics});
    } on SocketException {
      return const _FetchResult(_FetchStatus.networkError);
    } on TimeoutException {
      return const _FetchResult(_FetchStatus.networkError);
    } catch (_) {
      return const _FetchResult(_FetchStatus.notFound);
    }
  }

  /// Extracts plain-text lyrics from a Genius song HTML page.
  /// Genius renders lyrics inside [data-lyrics-container="true"] divs.
  ///
  /// Key fix: <span> and <h*> tags are separated with newlines BEFORE
  /// stripping so their content doesn't concatenate (e.g. "4 ContributorsAathi
  /// Lyrics" becomes two separate lines that can then be filtered out).
  String? _parseGeniusHtml(String html) {
    final containerRegex = RegExp(
      r'data-lyrics-container="true"[^>]*>(.*?)</div>',
      dotAll: true,
    );

    final matches = containerRegex.allMatches(html);
    if (matches.isEmpty) return null;

    // Patterns to filter out Genius metadata lines
    final contributorPattern =
        RegExp(r'^\d+\s+Contributor', caseSensitive: false);
    // "Song Name Lyrics" headers — typically short and end with " Lyrics"
    final titlePattern =
        RegExp(r'^.{1,80}\bLyrics\s*$', caseSensitive: false);

    final buffer = StringBuffer();
    for (final match in matches) {
      var chunk = match.group(1) ?? '';

      // ① Separate inline/heading elements with newlines BEFORE stripping
      //   so their text values don't run together.
      chunk = chunk.replaceAll(
          RegExp(r'</?(?:span|h[1-6]|a)[^>]*>'), '\n');

      // ② <br> → newline
      chunk = chunk.replaceAll(RegExp(r'<br\s*/?>'), '\n');

      // ③ Strip all remaining HTML tags
      chunk = chunk.replaceAll(RegExp(r'<[^>]+>'), '');

      // ④ Decode common HTML entities
      chunk = chunk
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&nbsp;', ' ');

      // ⑤ Process line-by-line, filtering Genius metadata
      bool wroteAnything = false;
      for (final rawLine in chunk.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty) {
          if (wroteAnything) buffer.writeln();
          continue;
        }
        // Skip "N Contributors" / "N Contributor"
        if (contributorPattern.hasMatch(line)) continue;
        // Skip "Song Name Lyrics" title headers
        if (titlePattern.hasMatch(line)) continue;

        buffer.writeln(line);
        wroteAnything = true;
      }
      if (wroteAnything) buffer.writeln(); // verse gap
    }

    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }

  // ────────────────────────────────────────────────────────────────────
  // LRC timestamp parser  [mm:ss.ms] text
  // ────────────────────────────────────────────────────────────────────
  List<LyricsLine> _parseSyncedLyrics(String syncedStr) {
    final lines = <LyricsLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in syncedStr.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisStr = match.group(3)!;
        final milliseconds = millisStr.length == 2
            ? int.parse(millisStr) * 10
            : int.parse(millisStr);
        final text = match.group(4)!.trim();
        if (text.isNotEmpty) {
          lines.add(LyricsLine(
            timestamp: Duration(
                minutes: minutes,
                seconds: seconds,
                milliseconds: milliseconds),
            text: text,
          ));
        }
      }
    }
    return lines;
  }
}
