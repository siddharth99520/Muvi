import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:provider/provider.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/lyrics_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

class MuviApp extends StatelessWidget {
  const MuviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProxyProvider<PlayerProvider, LyricsProvider>(
          create: (context) => LyricsProvider(context.read<PlayerProvider>()),
          update: (context, player, previous) => previous ?? LyricsProvider(player),
        ),
      ],
      child: MaterialApp(
        title: 'Muvi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
