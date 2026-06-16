import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VisualizerPainter extends CustomPainter {
  final List<double> bands;
  final double animationValue;
  final int barCount;

  static const double _barGap = 8.0;

  VisualizerPainter({
    required this.bands,
    required this.animationValue,
    required this.barCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bands.isEmpty) return;

    // Downsample bands array (from max 32) to the requested barCount
    final List<double> displayBands = [];
    if (bands.length <= barCount) {
      displayBands.addAll(bands.take(barCount));
    } else {
      final chunkSize = bands.length ~/ barCount;
      for (int i = 0; i < barCount; i++) {
        double sum = 0;
        for (int j = 0; j < chunkSize; j++) {
          sum += bands[i * chunkSize + j];
        }
        displayBands.add(sum / chunkSize);
      }
    }

    final count = displayBands.length;
    if (count == 0) return;

    final totalGap = _barGap * (count - 1);
    final barWidth = (size.width - totalGap) / count;
    final barRadius = Radius.circular(barWidth / 2);

    for (int i = 0; i < count; i++) {
      final amp = displayBands[i].clamp(0.0, 1.0);
      final barHeight = max(barWidth, amp * size.height * 0.92);
      final x = i * (barWidth + _barGap);
      // Vertically center the bar
      final y = (size.height - barHeight) / 2;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: barRadius,
        topRight: barRadius,
        bottomLeft: barRadius,
        bottomRight: barRadius,
      );

      // Symmetric gradient from the center out
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        stops: const [0.0, 0.5, 1.0],
        colors: [
          Color.lerp(AppTheme.accent, AppTheme.accentCyan, amp)!
              .withOpacity(0.85),
          Color.lerp(AppTheme.accentCyan, const Color(0xFFE0F2FE), amp * 0.5)!
              .withOpacity(0.85),
          Color.lerp(AppTheme.accent, AppTheme.accentCyan, amp)!
              .withOpacity(0.85),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(x, y, barWidth, barHeight),
        )
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, paint);

      // Glow effect for taller bars
      if (amp > 0.4) {
        final glowPaint = Paint()
          ..color = AppTheme.accent.withOpacity(amp * 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawRRect(rect, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(VisualizerPainter old) =>
      old.bands != bands || old.animationValue != animationValue;
}
