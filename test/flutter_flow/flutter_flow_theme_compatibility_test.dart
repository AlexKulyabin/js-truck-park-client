import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/core/theme/theme_store.dart';
import 'package:j_s_truck_park/flutter_flow/flutter_flow_theme.dart';

class _MemoryThemeStore implements ThemeStore {
  _MemoryThemeStore(this.themeMode);

  ThemeMode themeMode;

  @override
  ThemeMode readThemeMode() => themeMode;

  @override
  Future<void> writeThemeMode(ThemeMode themeMode) async {
    this.themeMode = themeMode;
  }
}

void main() {
  test('legacy theme API reads through the injected store', () async {
    final store = _MemoryThemeStore(ThemeMode.dark);
    await FlutterFlowTheme.initialize(themeStore: store);

    expect(FlutterFlowTheme.themeMode, ThemeMode.dark);
  });

  test('legacy theme API writes through the injected store', () async {
    final store = _MemoryThemeStore(ThemeMode.system);
    await FlutterFlowTheme.initialize(themeStore: store);

    FlutterFlowTheme.saveThemeMode(ThemeMode.light);
    await Future<void>.delayed(Duration.zero);

    expect(store.themeMode, ThemeMode.light);
  });
}
