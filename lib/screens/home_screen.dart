import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_art_panel.dart';
import '../widgets/visualizer_panel.dart';
import '../widgets/title_bar.dart';

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
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Stack(
          children: [
            // Base background
            Container(color: const Color(0xFF1E0A1E)), // Deep plum base

            // Center-left Magenta/Pink
            Positioned(
              top: -100 + (t * 200),
              left: -200 - (t * 100),
              child: _GlowingOrb(
                color: const Color(0xFFFA2C56).withOpacity(0.6),
                size: 800,
              ),
            ),

            // Top-right Orange/Peach
            Positioned(
              top: -300 - (t * 150),
              right: -100 + (t * 200),
              child: _GlowingOrb(
                color: const Color(0xFFF98C40).withOpacity(0.55),
                size: 900,
              ),
            ),

            // Bottom-right Deep Purple
            Positioned(
              bottom: -200 - (t * 250),
              right: -150 - (t * 100),
              child: _GlowingOrb(
                color: const Color(0xFF66118C).withOpacity(0.6),
                size: 850,
              ),
            ),

            // Center-bottom Soft Red
            Positioned(
              bottom: -100 + (t * 300),
              left: 100 + (t * 150),
              child: _GlowingOrb(
                color: const Color(0xFFE01A4F).withOpacity(0.4),
                size: 700,
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
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
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
