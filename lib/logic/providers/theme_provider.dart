// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import '../../data/services/local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  ThemeMode _themeMode = ThemeMode.dark; // default dark

  ThemeProvider({required LocalStorageService storage}) : _storage = storage;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    final saved = await _storage.getThemeMode();
    if (saved != null) {
      _themeMode = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.dark,
      };
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.setThemeMode(mode.name);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
