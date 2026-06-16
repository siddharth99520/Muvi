import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyBarCount = 'setting_bar_count';
  static const String _keyDynamicColors = 'setting_dynamic_colors';
  static const String _keyBgOpacity = 'setting_bg_opacity';

  int _barCount = 16;
  bool _useDynamicColors = true;
  double _bgOpacity = 0.4;

  int get barCount => _barCount;
  bool get useDynamicColors => _useDynamicColors;
  double get bgOpacity => _bgOpacity;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _barCount = prefs.getInt(_keyBarCount) ?? 16;
    _useDynamicColors = prefs.getBool(_keyDynamicColors) ?? true;
    _bgOpacity = prefs.getDouble(_keyBgOpacity) ?? 0.4;
    notifyListeners();
  }

  Future<void> setBarCount(int count) async {
    _barCount = count;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBarCount, count);
  }

  Future<void> setUseDynamicColors(bool value) async {
    _useDynamicColors = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDynamicColors, value);
  }

  Future<void> setBgOpacity(double opacity) async {
    _bgOpacity = opacity;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBgOpacity, opacity);
  }
}
