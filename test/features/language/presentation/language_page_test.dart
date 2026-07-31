import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/core/localization/locale_store.dart';
import 'package:j_s_truck_park/features/language/application/language_controller.dart';
import 'package:j_s_truck_park/flutter_flow/flutter_flow_widgets.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';
import 'package:j_s_truck_park/language/language_widget.dart';
import 'package:provider/provider.dart';

class _MemoryLocaleStore implements LocaleStore {
  String? languageCode;

  @override
  String? readLanguageCode() => languageCode;

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    this.languageCode = languageCode;
  }
}

Widget _buildSubject({
  required Locale locale,
  ValueChanged<String>? onLanguageSelected,
  ThemeMode themeMode = ThemeMode.light,
  LanguageController? languageController,
}) {
  final app = MaterialApp(
    localizationsDelegates: const [
      FFLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ru')],
    locale: locale,
    theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
    darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: false),
    themeMode: themeMode,
    home: LanguageWidget(onLanguageSelected: onLanguageSelected),
  );

  return languageController == null
      ? app
      : ChangeNotifierProvider.value(
          value: languageController,
          child: app,
        );
}

void main() {
  test('keeps the public route contract and has no generated state model', () {
    const subject = LanguageWidget();

    expect(LanguageWidget.routeName, 'Language');
    expect(LanguageWidget.routePath, '/language');
    expect(subject, isA<StatelessWidget>());
  });

  testWidgets('renders the existing English labels and layout configuration',
      (tester) async {
    await tester.pumpWidget(_buildSubject(locale: const Locale('en')));

    expect(find.text('En'), findsOneWidget);
    expect(find.text('Ru'), findsOneWidget);

    final buttons = tester.widgetList<FFButtonWidget>(
      find.byType(FFButtonWidget),
    );
    expect(buttons, hasLength(2));
    for (final button in buttons) {
      expect(button.options.width, double.infinity);
      expect(button.options.height, 40.0);
    }
  });

  testWidgets('reports both language choices through the injected boundary',
      (tester) async {
    final selectedLanguages = <String>[];
    await tester.pumpWidget(
      _buildSubject(
        locale: const Locale('en'),
        onLanguageSelected: selectedLanguages.add,
      ),
    );

    await tester.tap(find.text('En'));
    await tester.pump();
    await tester.tap(find.text('Ru'));
    await tester.pump();

    expect(selectedLanguages, ['en', 'ru']);
  });

  testWidgets('uses the application controller through the default boundary',
      (tester) async {
    final store = _MemoryLocaleStore();
    final controller = LanguageController(localeStore: store);
    await tester.pumpWidget(
      _buildSubject(
        locale: const Locale('en'),
        languageController: controller,
      ),
    );

    await tester.tap(find.text('Ru'));
    await tester.pump();

    expect(controller.state.locale?.languageCode, 'ru');
    expect(store.languageCode, 'ru');
  });

  testWidgets('preserves the current empty Russian translations',
      (tester) async {
    await tester.pumpWidget(_buildSubject(locale: const Locale('ru')));

    final buttons = tester.widgetList<FFButtonWidget>(
      find.byType(FFButtonWidget),
    );
    expect(buttons.map((button) => button.text), ['', '']);
  });

  testWidgets('renders in dark mode without an exception', (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        locale: const Locale('en'),
        themeMode: ThemeMode.dark,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(LanguageWidget), findsOneWidget);
  });
}
