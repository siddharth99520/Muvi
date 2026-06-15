import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // flutter_acrylic MUST initialize before runApp
  await Window.initialize();

  runApp(const MuviApp());

  // Window sizing + acrylic effect AFTER runApp so the engine is ready
  doWhenWindowReady(() async {
    const minSize = Size(960, 600);
    appWindow
      ..minSize = minSize
      ..size = minSize
      ..alignment = Alignment.center
      ..title = 'Muvi';

    // Apply acrylic after the window handle exists
    await Window.setEffect(
      effect: WindowEffect.acrylic,
      color: const Color(0xCC0D0D12),
    );

    appWindow.show();
  });
}
