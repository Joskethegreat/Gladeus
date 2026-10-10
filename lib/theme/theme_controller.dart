import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's theme mode. The Settings screen persists the choice under
/// 'setting_theme' ('Light' / 'Dark'); this loads it at startup.
class ThemeController {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.dark);

  static ThemeMode _fromLabel(String? label) =>
      label == 'Light' ? ThemeMode.light : ThemeMode.dark;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      mode.value = _fromLabel(prefs.getString('setting_theme'));
    } catch (_) {
      // fall back to dark
    }
  }

  static void apply(String label) => mode.value = _fromLabel(label);
}
