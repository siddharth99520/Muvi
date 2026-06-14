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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            // ── Title Bar ────────────────────────────────────
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
