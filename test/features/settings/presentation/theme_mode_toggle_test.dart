import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/core/theme/theme_store.dart';
import 'package:j_s_truck_park/features/settings/application/theme_controller.dart';
import 'package:j_s_truck_park/features/settings/presentation/theme_mode_toggle.dart';
import 'package:provider/provider.dart';

class _MemoryThemeStore implements ThemeStore {
  _MemoryThemeStore(this.themeMode);

  ThemeMode themeMode;
  final writes = <ThemeMode>[];

  @override
  ThemeMode readThemeMode() => themeMode;

  @override
  Future<void> writeThemeMode(ThemeMode themeMode) async {
    writes.add(themeMode);
    this.themeMode = themeMode;
  }
}

Widget _buildSubject(_MemoryThemeStore store) {
  final controller = ThemeController(themeStore: store);

  return ChangeNotifierProvider.value(
    value: controller,
    child: MaterialApp(
      theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: false),
      themeMode: store.themeMode,
      home: const Scaffold(
        body: Center(child: ThemeModeToggle()),
      ),
    ),
  );
}

void main() {
  testWidgets('preserves the generated toggle geometry', (tester) async {
    final store = _MemoryThemeStore(ThemeMode.light);
    await tester.pumpWidget(_buildSubject(store));

    expect(
      tester.getSize(find.byKey(ThemeModeToggle.toggleKey)),
      const Size(118.0, 28.0),
    );
    expect(
      tester.getSize(find.byKey(ThemeModeToggle.lightSelectionKey)),
      const Size(57.0, 24.0),
    );
  });

  testWidgets('reflects a persisted dark mode on first render', (tester) async {
    final store = _MemoryThemeStore(ThemeMode.dark);
    await tester.pumpWidget(_buildSubject(store));

    expect(find.byKey(ThemeModeToggle.darkSelectionKey), findsOneWidget);
    expect(find.byKey(ThemeModeToggle.lightSelectionKey), findsNothing);
  });

  testWidgets('changes dark and light through the single controller state',
      (tester) async {
    final store = _MemoryThemeStore(ThemeMode.light);
    await tester.pumpWidget(_buildSubject(store));

    await tester.tap(find.byKey(ThemeModeToggle.toggleKey));
    await tester.pump();

    expect(store.writes, [ThemeMode.dark]);
    expect(find.byKey(ThemeModeToggle.darkSelectionKey), findsOneWidget);

    await tester.tap(find.byKey(ThemeModeToggle.toggleKey));
    await tester.pump();

    expect(store.writes, [ThemeMode.dark, ThemeMode.light]);
    expect(find.byKey(ThemeModeToggle.lightSelectionKey), findsOneWidget);
  });

  testWidgets('treats system mode as the existing light toggle position',
      (tester) async {
    final store = _MemoryThemeStore(ThemeMode.system);
    await tester.pumpWidget(_buildSubject(store));

    expect(find.byKey(ThemeModeToggle.lightSelectionKey), findsOneWidget);
  });
}
