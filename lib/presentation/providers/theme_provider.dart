import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/hive_database.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    try {
      final db = HiveDatabase.instance;
      if (!db.isInitialized) {
        // Retry later or fallback to system
        return;
      }
      final value = db.getSettings('themeMode', defaultValue: 'system');
      state = _parseThemeMode(value as String);
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final db = HiveDatabase.instance;
      String value;
      switch (mode) {
        case ThemeMode.light:
          value = 'light';
          break;
        case ThemeMode.dark:
          value = 'dark';
          break;
        default:
          value = 'system';
      }
      await db.saveSettings('themeMode', value);
    } catch (_) {
      // Silently fail - theme mode preference is not critical
    }
  }

  Future<void> toggleTheme() async {
    switch (state) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        await setThemeMode(ThemeMode.dark);
        break;
    }
  }
}
