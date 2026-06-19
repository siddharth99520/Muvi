import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lyrics_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

class LyricsPanel extends StatelessWidget {
  const LyricsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleFactor = (constraints.maxHeight / 520).clamp(1.0, 2.2);

        return Consumer2<LyricsProvider, PlayerProvider>(
          builder: (context, lyricsProvider, playerProvider, child) {
            final status = lyricsProvider.status;

            if (status == LyricsStatus.initial || status == LyricsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (status == LyricsStatus.error) {
              return const Center(child: Text('Error loading lyrics', style: TextStyle(color: Colors.red)));
            }
            if (status == LyricsStatus.notFound) {
              return const Center(child: Text('No lyrics found', style: TextStyle(color: Colors.white)));
            }

            final synced = lyricsProvider.syncedLyrics;
            if (synced != null && synced.isNotEmpty) {
              return ListView.builder(
                itemCount: synced.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(synced[index].text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                  );
                },
              );
            }

            return const Center(child: Text('Plain lyrics view', style: TextStyle(color: Colors.white)));
          },
        );
      },
    );
  }
}
