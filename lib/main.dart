import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize acrylic window effects
  await Window.initialize();
  await Window.setEffect(
    effect: WindowEffect.acrylic,
    color: const Color(0xCC0D0D12), // ~80% opaque deep navy
  );

  runApp(const MuviApp());

  // Configure the window via bitsdojo_window
  doWhenWindowReady(() {
    const minSize = Size(960, 600);
    appWindow
      ..minSize = minSize
      ..size = minSize
      ..alignment = Alignment.center
      ..title = 'Muvi'
      ..show();
  });
}
