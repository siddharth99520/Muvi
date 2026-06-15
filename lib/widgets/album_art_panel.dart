import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/player_state.dart';
import '../theme/app_theme.dart';

class AlbumArtPanel extends StatelessWidget {
  const AlbumArtPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlayerProvider>();
    final state = provider.state;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Album Art ──────────────────────────────────────────
        _AlbumArt(albumArtBytes: state.albumArtBytes, isLive: state.isLive),
        const SizedBox(height: 28),

        // ── Song Info ─────────────────────────────────────────
        _SongInfo(state: state),
        const SizedBox(height: 24),

        // ── Progress Bar ──────────────────────────────────────
        _ProgressBar(state: state, provider: provider),
        const SizedBox(height: 20),

        // ── Playback Controls ─────────────────────────────────
        _PlaybackControls(provider: provider, state: state),
      ],
    );
  }
}

// ── Album Art Widget ────────────────────────────────────────────
class _AlbumArt extends StatefulWidget {
  final Uint8List? albumArtBytes;
  final bool isLive;

  const _AlbumArt({this.albumArtBytes, required this.isLive});

  @override
  State<_AlbumArt> createState() => _AlbumArtState();
}

class _AlbumArtState extends State<_AlbumArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glowOpacity = widget.isLive ? 0.35 + 0.15 * _pulse.value : 0.35;
        final cyanOpacity = widget.isLive ? 0.15 + 0.10 * _pulse.value : 0.15;

        return Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(glowOpacity),
                  blurRadius: 40,
                  spreadRadius: 4,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppTheme.accentCyan.withOpacity(cyanOpacity),
                  blurRadius: 60,
                  spreadRadius: 8,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.albumArtBytes != null
                  ? Image.memory(
                      widget.albumArtBytes!,
                      fit: BoxFit.cover,
                      width: 220,
                      height: 220,
                    )
                  : Image.asset(
                      'assets/images/placeholder_album.png',
                      fit: BoxFit.cover,
                      width: 220,
                      height: 220,
                      errorBuilder: (_, __, ___) => _PlaceholderArt(),
                    ),
            ),
          ),
        );
      },
    );
  }
}


class _PlaceholderArt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B69), Color(0xFF11274F), Color(0xFF0D3050)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 72,
          color: Color(0x55FFFFFF),
        ),
      ),
    );
  }
}

// ── Song Info ───────────────────────────────────────────────────
class _SongInfo extends StatelessWidget {
  final PlayerState state;
  const _SongInfo({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.title,
          style: AppTheme.songTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          state.artist,
          style: AppTheme.artistName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          state.album,
          style: AppTheme.albumName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Progress Bar ────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final PlayerState state;
  final PlayerProvider provider;

  const _ProgressBar({required this.state, required this.provider});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = state.duration.inMilliseconds == 0
        ? 0.0
        : state.position.inMilliseconds / state.duration.inMilliseconds;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            thumbColor: AppTheme.accentGlow,
            activeTrackColor: AppTheme.accent,
            inactiveTrackColor: AppTheme.divider,
            overlayColor: AppTheme.accent.withOpacity(0.2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: provider.seek,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(state.position), style: AppTheme.timeLabel),
              Text(_fmt(state.duration), style: AppTheme.timeLabel),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Playback Controls ───────────────────────────────────────────
class _PlaybackControls extends StatelessWidget {
  final PlayerProvider provider;
  final PlayerState state;

  const _PlaybackControls({required this.provider, required this.state});

  @override
  Widget build(BuildContext context) {
    final isPlaying = state.status == PlaybackStatus.playing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.skip_previous_rounded,
          size: 26,
          onTap: provider.previous,
        ),
        const SizedBox(width: 16),
        _PlayPauseButton(isPlaying: isPlaying, onTap: provider.playPause),
        const SizedBox(width: 16),
        _ControlButton(
          icon: Icons.skip_next_rounded,
          size: 26,
          onTap: provider.next,
        ),
      ],
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _ControlButton(
      {required this.icon, required this.size, required this.onTap});

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered
                ? AppTheme.surfaceHigher
                : AppTheme.surface,
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: _hovered ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayPauseButton({required this.isPlaying, required this.onTap});

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scale;
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _scale.reverse();
    widget.onTap();
    await _scale.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.accent, AppTheme.accentCyan],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              widget.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              key: ValueKey(widget.isPlaying),
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
