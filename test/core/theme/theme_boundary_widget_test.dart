import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/core/theme/theme_store.dart';
import 'package:j_s_truck_park/features/settings/application/theme_controller.dart';
import 'package:j_s_truck_park/flutter_flow/flutter_flow_util.dart';
import 'package:provider/provider.dart';

class _MemoryThemeStore implements ThemeStore {
  ThemeMode themeMode = ThemeMode.system;

  @override
  ThemeMode readThemeMode() => themeMode;

  @override
  Future<void> writeThemeMode(ThemeMode themeMode) async {
    this.themeMode = themeMode;
  }
}

void main() {
  testWidgets('compatibility helper delegates to ThemeController',
      (tester) async {
    final store = _MemoryThemeStore();
    final controller = ThemeController(themeStore: store);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => setDarkModeSetting(context, ThemeMode.dark),
              child: const Text('Dark'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(controller.state.themeMode, ThemeMode.dark);
    expect(store.themeMode, ThemeMode.dark);
  });
}
