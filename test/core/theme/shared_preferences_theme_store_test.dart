import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/core/theme/shared_preferences_theme_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('uses system mode when no preference is stored', () async {
    final store = await SharedPreferencesThemeStore.create();

    expect(store.readThemeMode(), ThemeMode.system);
  });

  test('reads the existing FlutterFlow boolean contract', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesThemeStore.storageKey: true,
    });
    final darkStore = await SharedPreferencesThemeStore.create();
    expect(darkStore.readThemeMode(), ThemeMode.dark);

    SharedPreferences.setMockInitialValues({
      SharedPreferencesThemeStore.storageKey: false,
    });
    final lightStore = await SharedPreferencesThemeStore.create();
    expect(lightStore.readThemeMode(), ThemeMode.light);
  });

  test('persists dark and light using the compatible boolean key', () async {
    final store = await SharedPreferencesThemeStore.create();

    await store.writeThemeMode(ThemeMode.dark);
    var preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(SharedPreferencesThemeStore.storageKey),
      isTrue,
    );

    await store.writeThemeMode(ThemeMode.light);
    preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(SharedPreferencesThemeStore.storageKey),
      isFalse,
    );
  });

  test('removes the stored override when system mode is selected', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesThemeStore.storageKey: true,
    });
    final store = await SharedPreferencesThemeStore.create();

    await store.writeThemeMode(ThemeMode.system);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.containsKey(SharedPreferencesThemeStore.storageKey),
      isFalse,
    );
  });
}
