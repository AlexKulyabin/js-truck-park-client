import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_store.dart';

class SharedPreferencesThemeStore implements ThemeStore {
  SharedPreferencesThemeStore(this._preferences);

  static const storageKey = '__theme_mode__';

  final SharedPreferences _preferences;

  static Future<SharedPreferencesThemeStore> create() async =>
      SharedPreferencesThemeStore(await SharedPreferences.getInstance());

  @override
  ThemeMode readThemeMode() {
    final darkMode = _preferences.getBool(storageKey);
    return darkMode == null
        ? ThemeMode.system
        : darkMode
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  @override
  Future<void> writeThemeMode(ThemeMode themeMode) async {
    if (themeMode == ThemeMode.system) {
      await _preferences.remove(storageKey);
      return;
    }

    await _preferences.setBool(storageKey, themeMode == ThemeMode.dark);
  }
}
