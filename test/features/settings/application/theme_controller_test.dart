import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/core/theme/theme_store.dart';
import 'package:j_s_truck_park/features/settings/application/theme_controller.dart';

class _FakeThemeStore implements ThemeStore {
  _FakeThemeStore({this.themeMode = ThemeMode.system});

  ThemeMode themeMode;
  final writes = <ThemeMode>[];
  Completer<void>? pendingWrite;

  @override
  ThemeMode readThemeMode() => themeMode;

  @override
  Future<void> writeThemeMode(ThemeMode themeMode) {
    writes.add(themeMode);
    this.themeMode = themeMode;
    return pendingWrite?.future ?? Future.value();
  }
}

void main() {
  test('restores the persisted theme mode when it is created', () {
    final controller = ThemeController(
      themeStore: _FakeThemeStore(themeMode: ThemeMode.dark),
    );

    expect(controller.state.themeMode, ThemeMode.dark);
  });

  test('updates state immediately and persists the selected mode', () async {
    final store = _FakeThemeStore()..pendingWrite = Completer<void>();
    final controller = ThemeController(themeStore: store);
    var notifications = 0;
    controller.addListener(() => notifications++);

    final persistence = controller.selectThemeMode(ThemeMode.light);

    expect(controller.state.themeMode, ThemeMode.light);
    expect(store.writes, [ThemeMode.light]);
    expect(notifications, 1);

    store.pendingWrite!.complete();
    await persistence;
  });
}
