import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Color Palette ────────────────────────────────────────────
  static const Color bgDeep = Color(0xFF0D0D12);
  static const Color bgGradientStart = Color(0xFF1A1A2E);
  static const Color bgGradientEnd = Color(0xFF16213E);
  static const Color accent = Color(0xFF7C3AED); // Violet
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan
  static const Color accentGlow = Color(0xFF9F67F7);
  static const Color surface = Color(0x0DFFFFFF); // 5% white
  static const Color surfaceHigher = Color(0x1AFFFFFF); // 10% white
  static const Color divider = Color(0x14FFFFFF);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

  // ── Gradients ────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgGradientStart, bgGradientEnd, bgDeep],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentCyan],
  );

  static LinearGradient visualizerBarGradient(double intensity) =>
      LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color.lerp(accent, accentCyan, intensity)!.withOpacity(0.9),
          Color.lerp(accentCyan, Colors.white, intensity * 0.4)!
              .withOpacity(0.7),
        ],
      );

  // ── Typography ───────────────────────────────────────────────
  static TextStyle get displayTitle => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get songTitle => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get artistName => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.2,
      );

  static TextStyle get albumName => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textMuted,
        letterSpacing: 0.3,
      );

  static TextStyle get timeLabel => GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        letterSpacing: 0.5,
        fontFeatures: [const FontFeature.tabularFigures()],
      );

  static TextStyle get appName => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: 4,
      );

  // ── Theme Data ───────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accentCyan,
          surface: bgGradientStart,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      );
}
