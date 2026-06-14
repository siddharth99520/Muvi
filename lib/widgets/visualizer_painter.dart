import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VisualizerPainter extends CustomPainter {
  final List<double> bands;
  final double animationValue;

  static const int _barCount = 32;
  static const double _barGap = 4.0;
  static const double _cornerRadius = 4.0;

  VisualizerPainter({
    required this.bands,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bands.isEmpty) return;

    final count = min(bands.length, _barCount);
    final totalGap = _barGap * (count - 1);
    final barWidth = (size.width - totalGap) / count;

    for (int i = 0; i < count; i++) {
      final amp = bands[i].clamp(0.0, 1.0);
      final barHeight = max(6.0, amp * size.height * 0.92);
      final x = i * (barWidth + _barGap);
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(_cornerRadius),
        topRight: const Radius.circular(_cornerRadius),
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      );

      // Bar gradient fill
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color.lerp(AppTheme.accent, AppTheme.accentCyan, amp)!
              .withOpacity(0.85),
          Color.lerp(AppTheme.accentCyan, const Color(0xFFE0F2FE), amp * 0.5)!
              .withOpacity(0.7),
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

      // Reflection (subtle mirrored ghost below)
      final reflectHeight = barHeight * 0.18;
      final reflectRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, size.height, barWidth, reflectHeight),
        bottomLeft: const Radius.circular(_cornerRadius),
        bottomRight: const Radius.circular(_cornerRadius),
      );

      final reflectGrad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.accent.withOpacity(amp * 0.25),
          AppTheme.accent.withOpacity(0.0),
        ],
      );
      final reflectPaint = Paint()
        ..shader = reflectGrad.createShader(
          Rect.fromLTWH(x, size.height, barWidth, reflectHeight),
        );
      canvas.drawRRect(reflectRect, reflectPaint);
    }
  }

  @override
  bool shouldRepaint(VisualizerPainter old) =>
      old.bands != bands || old.animationValue != animationValue;
}
