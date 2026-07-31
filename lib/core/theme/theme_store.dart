import 'package:flutter/material.dart';

abstract interface class ThemeStore {
  ThemeMode readThemeMode();

  Future<void> writeThemeMode(ThemeMode themeMode);
}
