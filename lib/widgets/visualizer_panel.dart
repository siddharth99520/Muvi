import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'visualizer_painter.dart';

class VisualizerPanel extends StatefulWidget {
  const VisualizerPanel({super.key});

  @override
  State<VisualizerPanel> createState() => _VisualizerPanelState();
}

class _VisualizerPanelState extends State<VisualizerPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final List<double> _currentBands = List.filled(32, 0.0);
  List<double> _targetBands = List.filled(32, 0.0);

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Selector<PlayerProvider, List<double>>(
      selector: (_, p) => p.state.fftBands,
      builder: (context, bands, _) {
        // Update targets whenever native layer pushes new data (~20 Hz)
        if (bands.isNotEmpty && bands.length <= 32) {
          for (int i = 0; i < bands.length; i++) {
            _targetBands[i] = bands[i];
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentCyan,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentCyan.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'LIVE SPECTRUM',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Visualizer canvas ─────────────────────────────
            Expanded(
              child: AnimatedBuilder(
                animation: _ticker,
                builder: (context, _) {
                  // Buttery smooth 60fps interpolation
                  for (int i = 0; i < 32; i++) {
                    final diff = _targetBands[i] - _currentBands[i];
                    // Fast attack (bars jump up quickly), slow decay (fall down smoothly)
                    _currentBands[i] += diff * (diff > 0 ? 0.35 : 0.15);
                  }

                  return CustomPaint(
                    painter: VisualizerPainter(
                      bands: List.from(_currentBands),
                      animationValue: _ticker.value,
                      barCount: settings.barCount,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),

            // ── Frequency labels ──────────────────────────────
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['20Hz', '100Hz', '500Hz', '2kHz', '8kHz', '20kHz']
                    .map((label) => Text(
                          label,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.3,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
