import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/flutter_flow/flutter_flow_widgets.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';
import 'package:j_s_truck_park/language/language_widget.dart';

Widget _buildSubject({
  required Locale locale,
  ValueChanged<String>? onLanguageSelected,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
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
