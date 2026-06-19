import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lyrics_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

class LyricsPanel extends StatefulWidget {
  const LyricsPanel({super.key});

  @override
  State<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends State<LyricsPanel> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = -1;

  // When the user manually scrolls, we pause auto-scroll and show a Sync btn.
  bool _autoScroll = true;

  // Last known active index + scale so the sync button can jump to it.
  int _lastActiveIndex = -1;
  double _lastInactiveHeight = 52.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls the list so the active line is centred in the viewport.
  void _scrollToActive() {
    if (!_scrollController.hasClients || _lastActiveIndex < 0) return;
    // targetOffset is mathematically guaranteed to be correct.
    // Do NOT clamp to maxScrollExtent because ListView might temporarily
    // under-estimate it before laying out all items.
    final targetOffset = _lastActiveIndex * _lastInactiveHeight;
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleFactor =
            (constraints.maxHeight / 520).clamp(1.0, 2.2);

        return Consumer2<LyricsProvider, PlayerProvider>(
          builder: (context, lyricsProvider, playerProvider, child) {
            final status = lyricsProvider.status;

            if (status == LyricsStatus.initial ||
                status == LyricsStatus.loading) {
              return _buildLoading(scaleFactor);
            }

            if (status == LyricsStatus.offline) {
              return _buildMessage(
                Icons.wifi_off_rounded,
                'No internet connection',
                'Connect to the internet to load lyrics.',
                scaleFactor: scaleFactor,
                color: Colors.orangeAccent,
                onRetry: () => context.read<LyricsProvider>().retry(),
              );
            }

            if (status == LyricsStatus.notFound) {
              return _buildMessage(
                Icons.lyrics_outlined,
                'No lyrics found',
                'Could not find lyrics for this track\non lrclib or Genius.',
                scaleFactor: scaleFactor,
                onRetry: () => context.read<LyricsProvider>().retry(),
              );
            }

            if (status == LyricsStatus.error) {
              return _buildMessage(
                Icons.error_outline_rounded,
                'Something went wrong',
                'Failed to load lyrics.',
                scaleFactor: scaleFactor,
                color: Colors.redAccent,
                onRetry: () => context.read<LyricsProvider>().retry(),
              );
            }

            // ── Loaded ──────────────────────────────────────────────
            final synced = lyricsProvider.syncedLyrics;
            final plain = lyricsProvider.plainLyrics;
            final source = lyricsProvider.source;
            final hasSynced = synced != null && synced.isNotEmpty;

            Widget content;
            if (hasSynced) {
              content = _buildSyncedLyrics(
                  synced!, playerProvider.state.position, scaleFactor, constraints.maxHeight);
            } else if (plain != null && plain.isNotEmpty) {
              content = _buildPlainLyrics(plain, scaleFactor);
            } else {
              content = _buildMessage(
                  Icons.lyrics_outlined, 'No lyrics', '',
                  scaleFactor: scaleFactor);
            }

            return Stack(
              children: [
                content,

                // ── Sync button — always visible for synced lyrics ──
                if (hasSynced)
                  Positioned(
                    bottom: 36,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        // Bright when user has scrolled away, dimmed when tracking
                        opacity: _autoScroll ? 0.35 : 1.0,
                        child: _SyncButton(
                          scale: scaleFactor,
                          isPulsing: !_autoScroll,
                          onTap: () {
                            setState(() => _autoScroll = true);
                            _scrollToActive();
                          },
                        ),
                      ),
                    ),
                  ),

                // ── Source badge ─────────────────────────────────────
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _SourceBadge(
                    source: source,
                    isSynced: hasSynced,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLoading(double scale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36 * scale,
            height: 36 * scale,
            child: CircularProgressIndicator(
              color: AppTheme.accentCyan,
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(height: 20 * scale),
          Text(
            'Searching lyrics…',
            style: TextStyle(
              fontSize: 14 * scale,
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Trying lrclib → Genius',
            style: TextStyle(
              fontSize: 11 * scale,
              letterSpacing: 1.5,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(
    IconData icon,
    String title,
    String subtitle, {
    double scaleFactor = 1.0,
    Color? color,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color ?? AppTheme.textMuted,
                size: 48 * scaleFactor),
            SizedBox(height: 16 * scaleFactor),
            Text(
              title,
              style: TextStyle(
                fontSize: 18 * scaleFactor,
                fontWeight: FontWeight.bold,
                color: color ?? AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: 8 * scaleFactor),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13 * scaleFactor,
                  height: 1.6,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: 24 * scaleFactor),
              _RetryButton(onTap: onRetry, scale: scaleFactor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlainLyrics(String lyrics, double scale) {
    return Center(
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 48 * scale),
          child: Text(
            lyrics,
            style: TextStyle(
              fontSize: 15 * scale,
              height: 2.0,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSyncedLyrics(
      List<LyricsLine> lines, Duration currentPosition, double scale, double maxHeight) {
    final activeHeight = 68.0 * scale;
    final inactiveHeight = 52.0 * scale;

    // Cache for scroll-to-active triggered from sync button
    _lastInactiveHeight = inactiveHeight;

    // Find the currently active line
    int activeIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      if (currentPosition >= lines[i].timestamp) {
        activeIndex = i;
      } else {
        break;
      }
    }

    _lastActiveIndex = activeIndex;

    // Auto-scroll only when enabled and the active line changed
    if (_autoScroll && activeIndex != _currentIndex && activeIndex >= 0) {
      _currentIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && _autoScroll) {
          final targetOffset = activeIndex * inactiveHeight;
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    // Exact padding needed to make the first/last item perfectly centerable
    final verticalPadding = ((maxHeight - activeHeight) / 2).clamp(0.0, double.infinity);

    // ── User scroll detection ─────────────────────────────────────────
    // On Windows desktop, scrolling is done via mouse wheel which fires
    // PointerScrollEvent — NOT a drag gesture. dragDetails is always null
    // for mouse wheel events, so the old NotificationListener check failed.
    // We use a Listener widget to catch pointer-level scroll events instead.
    final listView = ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
          vertical: verticalPadding, horizontal: 24 * scale),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final isActive = index == activeIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isActive ? activeHeight : inactiveHeight,
          alignment: Alignment.center,
          // Animate scale rather than fontSize to prevent jarring line-wrap
          // recalculations mid-animation. Layout is computed once for the largest size.
          child: AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: isActive ? 1.0 : (15.0 / 22.0),
            alignment: Alignment.center,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 22 * scale, // Fixed layout size
                fontWeight: FontWeight.w700, // Fixed width to prevent character jitter
                color: isActive
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary.withOpacity(0.45),
                shadows: isActive
                    ? [
                        Shadow(
                          color: AppTheme.accentCyan.withOpacity(0.4),
                          blurRadius: 18 * scale,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                lines[index].text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );

    return Listener(
      // Mouse wheel on Windows → PointerScrollEvent (dragDetails is always null
      // for wheel events so NotificationListener alone doesn't work on desktop)
      onPointerSignal: (event) {
        if (event is PointerScrollEvent && _autoScroll) {
          setState(() => _autoScroll = false);
        }
      },
      // Touch drag on other platforms (belt-and-suspenders)
      child: NotificationListener<ScrollStartNotification>(
        onNotification: (notification) {
          if (notification.dragDetails != null && _autoScroll) {
            setState(() => _autoScroll = false);
          }
          return false;
        },
        child: listView,
      ),
    );
  }
}

// ── Sync button ───────────────────────────────────────────────────────
class _SyncButton extends StatefulWidget {
  final VoidCallback onTap;
  final double scale;
  final bool isPulsing;
  const _SyncButton(
      {required this.onTap, this.scale = 1.0, this.isPulsing = false});

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.92,
      upperBound: 1.0,
    )..value = 1.0;
    if (widget.isPulsing) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_SyncButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isPulsing && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 1.0; // reset to full scale
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pulse,
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
          decoration: BoxDecoration(
            color: AppTheme.accentCyan.withOpacity(0.15),
            border: Border.all(
                color: AppTheme.accentCyan.withOpacity(0.5), width: 1),
            borderRadius: BorderRadius.circular(24 * s),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentCyan.withOpacity(0.25),
                blurRadius: 16 * s,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.gps_fixed_rounded,
                size: 14 * s,
                color: AppTheme.accentCyan,
              ),
              SizedBox(width: 6 * s),
              Text(
                'Sync',
                style: TextStyle(
                  fontSize: 12 * s,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppTheme.accentCyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ── Retry button ──────────────────────────────────────────────────────
class _RetryButton extends StatefulWidget {
  final VoidCallback onTap;
  final double scale;
  const _RetryButton({required this.onTap, this.scale = 1.0});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.92,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.reverse();
  void _onTapUp(_) {
    _ctrl.forward();
    widget.onTap();
  }
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: 20 * s, vertical: 10 * s),
          decoration: BoxDecoration(
            color: AppTheme.accentCyan.withOpacity(0.12),
            border:
                Border.all(color: AppTheme.accentCyan.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(10 * s),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded,
                  size: 15 * s,
                  color: AppTheme.accentCyan.withOpacity(0.9)),
              SizedBox(width: 8 * s),
              Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 13 * s,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppTheme.accentCyan.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Source badge ──────────────────────────────────────────────────────
class _SourceBadge extends StatelessWidget {
  final LyricsSource source;
  final bool isSynced;

  const _SourceBadge({required this.source, this.isSynced = false});

  @override
  Widget build(BuildContext context) {
    if (source == LyricsSource.none) return const SizedBox.shrink();

    final isLrclib = source == LyricsSource.lrclib;
    final color = isLrclib
        ? AppTheme.accentCyan
        : const Color(0xFFFFD700); // Genius gold

    // Show sync state so the user knows why lyrics aren't moving
    final syncLabel = isSynced ? '· synced' : '· plain';
    final sourceLabel = isLrclib ? 'lrclib' : 'Genius';
    final label = '$sourceLabel $syncLabel';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.sync_rounded : Icons.text_snippet_outlined,
            size: 10,
            color: color.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
