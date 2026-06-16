import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: const Color(0xFF1E0A1E).withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Visualizer Settings',
                        style: AppTheme.displayTitle.copyWith(fontSize: 20),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Background Opacity Slider
                  Text('Background Contrast', style: AppTheme.songTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  Slider(
                    value: settings.bgOpacity,
                    min: 0.0,
                    max: 0.8,
                    activeColor: AppTheme.accent,
                    inactiveColor: Colors.white24,
                    onChanged: (val) => settings.setBgOpacity(val),
                  ),
                  const SizedBox(height: 24),

                  // Color Theme Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dynamic Album Colors', style: AppTheme.songTitle.copyWith(fontSize: 16)),
                      Switch(
                        value: settings.useDynamicColors,
                        activeColor: AppTheme.accent,
                        onChanged: (val) => settings.setUseDynamicColors(val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Extracts vibrant colors from the current album art to tint the background mesh.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 24),

                  // FFT Bar Count
                  Text('FFT Bar Count', style: AppTheme.songTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 8, label: Text('8 Bands')),
                      ButtonSegment(value: 16, label: Text('16 Bands')),
                      ButtonSegment(value: 32, label: Text('32 Bands')),
                    ],
                    selected: {settings.barCount},
                    onSelectionChanged: (Set<int> newSelection) {
                      settings.setBarCount(newSelection.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.accent.withOpacity(0.3);
                        }
                        return Colors.transparent;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.accent;
                        }
                        return Colors.white70;
                      }),
                      side: WidgetStateProperty.all(
                        BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
