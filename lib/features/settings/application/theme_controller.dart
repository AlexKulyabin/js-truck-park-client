import 'package:flutter/material.dart';

import '../../../core/theme/theme_store.dart';

@immutable
class ThemeState {
  const ThemeState({required this.themeMode});

  final ThemeMode themeMode;
}

class ThemeController extends ChangeNotifier {
  ThemeController({required ThemeStore themeStore})
      : _themeStore = themeStore,
        _state = ThemeState(themeMode: themeStore.readThemeMode());

  final ThemeStore _themeStore;
  ThemeState _state;

  ThemeState get state => _state;

  Future<void> selectThemeMode(ThemeMode themeMode) {
    _state = ThemeState(themeMode: themeMode);
    notifyListeners();
    return _themeStore.writeThemeMode(themeMode);
  }
}
