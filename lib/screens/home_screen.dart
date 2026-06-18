import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_art_panel.dart';
import '../widgets/visualizer_panel.dart';
import '../widgets/title_bar.dart';
import 'package:flutter/scheduler.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          // ── Smooth Mesh Gradient Background ──────────────
          const Positioned.fill(
            child: _SmoothBackground(),
          ),

          // ── App Content ──────────────────────────────────
          Column(
            children: [
              // ── Title Bar ────────────────────────────────
              const TitleBar(),

              // ── Main Content ─────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Left Column: Player ─────────────────
                      SizedBox(
                        width: 280,
                        child: ChangeNotifierProvider.value(
                          value: context.read<PlayerProvider>(),
                          child: const AlbumArtPanel(),
                        ),
                      ),

                      // ── Divider ─────────────────────────────
                      const _VerticalDivider(),

                      // ── Right Column: Visualizer ────────────
                      const Expanded(
                        child: VisualizerPanel(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppTheme.divider,
            AppTheme.divider,
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
    );
  }
}

// ── Smooth Mesh Background (Apple Music Style) ──────────────────────
class _SmoothBackground extends StatefulWidget {
  const _SmoothBackground();

  @override
  State<_SmoothBackground> createState() => _SmoothBackgroundState();
}

class _SmoothBackgroundState extends State<_SmoothBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _timeNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _bassIntensityNotifier = ValueNotifier(0.0);
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;

      if (!mounted) return;
      
      final state = context.read<PlayerProvider>().state;
      double bass = 0.0;
      if (state.fftBands.length >= 3) {
        // Average the first 3 bands (bass frequencies)
        bass = (state.fftBands[0] + state.fftBands[1] + state.fftBands[2]) / 3.0;
      }
      
      // Smooth the bass intensity so brightness doesn't flicker violently
      _bassIntensityNotifier.value += (bass - _bassIntensityNotifier.value) * (dt * 15.0).clamp(0.0, 1.0);

      // Base speed: 0.1 rad/s, Bass boost: up to 1.5 rad/s
      _timeNotifier.value += dt * (0.1 + _bassIntensityNotifier.value * 1.5);
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _timeNotifier.dispose();
    _bassIntensityNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final playerState = context.watch<PlayerProvider>().state;

    // Determine colors
    final useDynamic = settings.useDynamicColors;
    final baseColor = useDynamic && playerState.dominantColor != null 
        ? playerState.dominantColor! 
        : const Color(0xFF1E0A1E);
    final color1 = useDynamic && playerState.vibrantColor != null 
        ? playerState.vibrantColor!.withOpacity(0.6) 
        : const Color(0xFFFA2C56).withOpacity(0.6);
    final color2 = useDynamic && playerState.dominantColor != null 
        ? playerState.dominantColor!.withOpacity(0.55) 
        : const Color(0xFFF98C40).withOpacity(0.55);
    final color3 = useDynamic && playerState.dominantColor != null 
        ? playerState.dominantColor!.withOpacity(0.6) 
        : const Color(0xFF66118C).withOpacity(0.6);
    final color4 = useDynamic && playerState.vibrantColor != null 
        ? playerState.vibrantColor!.withOpacity(0.4) 
        : const Color(0xFFE01A4F).withOpacity(0.4);

    return AnimatedBuilder(
      animation: Listenable.merge([_timeNotifier, _bassIntensityNotifier]),
      builder: (context, _) {
        final t = _timeNotifier.value;
        final bass = _bassIntensityNotifier.value;
        
        // Boost size and brightness based on bass
        final sizeBoost = bass * 150.0;
        final opacityBoost = bass * 0.4;
        
        // Helper to apply opacity boost to colors
        Color boostColor(Color c) {
          return c.withOpacity((c.opacity + opacityBoost).clamp(0.0, 1.0));
        }
        
        return Stack(
          children: [
            // Base background
            Container(color: baseColor),

            // Center-left Magenta/Pink
            Positioned(
              top: -100 + (math.sin(t) * 150),
              left: -200 + (math.cos(t) * 150),
              child: _GlowingOrb(
                color: boostColor(color1),
                size: 800 + sizeBoost,
              ),
            ),

            // Top-right Orange/Peach
            Positioned(
              top: -300 + (math.cos(t + 1) * 200),
              right: -100 + (math.sin(t + 1) * 200),
              child: _GlowingOrb(
                color: boostColor(color2),
                size: 900 + sizeBoost,
              ),
            ),

            // Bottom-right Deep Purple
            Positioned(
              bottom: -200 + (math.sin(t + 2) * 250),
              right: -150 + (math.cos(t + 2) * 250),
              child: _GlowingOrb(
                color: boostColor(color3),
                size: 850 + sizeBoost,
              ),
            ),

            // Center-bottom Soft Red
            Positioned(
              bottom: -100 + (math.cos(t + 3) * 200),
              left: 100 + (math.sin(t + 3) * 200),
              child: _GlowingOrb(
                color: boostColor(color4),
                size: 700 + sizeBoost,
              ),
            ),

            // ── Massive frosted glass blur for the fluid liquid effect ──
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 140, sigmaY: 140),
                child: Container(color: Colors.transparent),
              ),
            ),

            // Dark overlay to keep text legible and contrast high
            // Slightly reduce the overlay opacity when bass is strong for extra brightness
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity((settings.bgOpacity - bass * 0.2).clamp(0.0, 1.0)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowingOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowingOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.6),
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }
}
