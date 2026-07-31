import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/map/application/parking_filter_controller.dart';
import 'package:j_s_truck_park/filter/filter/filter_widget.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';
import 'package:provider/provider.dart';

const _openFilterKey = Key('open-filter');

const _nonDefaultFilterState = ParkingFilterState(
  capacityFrom: 7,
  capacityTo: 42,
  hasGas: true,
  hasShower: true,
  hasLaundry: true,
  hasHotel: true,
  hasShop: true,
  hasRecreation: true,
  showNearest: true,
  radiusIndex: 3,
  isApplied: true,
);

Widget _buildFilterHost(ParkingFilterController controller) =>
    ChangeNotifierProvider<ParkingFilterController>.value(
      value: controller,
      child: MaterialApp(
        localizationsDelegates: const [
          FFLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ru')],
        locale: const Locale('en'),
        theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: _openFilterKey,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Material(child: FilterWidget()),
                  ),
                ),
                child: const Text('Open filter'),
              ),
            ),
          ),
        ),
      ),
    );

Future<void> _openFilter(
  WidgetTester tester,
  ParkingFilterController controller,
) async {
  _setMobileViewSize(tester);
  await tester.pumpWidget(_buildFilterHost(controller));
  await tester.tap(find.byKey(_openFilterKey));
  await tester.pumpAndSettle();
}

void _setMobileViewSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('Reset restores controller defaults and clears applied state',
      (tester) async {
    final controller = ParkingFilterController()
      ..restore(_nonDefaultFilterState);
    await _openFilter(tester, controller);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(controller.state, const ParkingFilterState.initial());
  });

  testWidgets('Apply marks current controller filter values as active',
      (tester) async {
    final controller = ParkingFilterController()
      ..restore(
        _nonDefaultFilterState.copyWith(isApplied: false),
      );
    await _openFilter(tester, controller);

    await tester.ensureVisible(find.text('Apply'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(controller.state.capacityFrom, 7);
    expect(controller.state.capacityTo, 42);
    expect(controller.state.hasGas, isTrue);
    expect(controller.state.isApplied, isTrue);
  });

  test('Back action closes without applying the controller filter', () async {
    final source = await File(
      'lib/filter/filter/filter_widget.dart',
    ).readAsString();

    final backActionIndex = source.indexOf('context.safePop();');
    expect(backActionIndex, isNonNegative);

    final backAction = source.substring(
      backActionIndex - 80,
      backActionIndex + 80,
    );
    expect(backAction, isNot(contains('.apply()')));
  });

  test('filter widget no longer reads or writes legacy app state fields',
      () async {
    final source = await File(
      'lib/filter/filter/filter_widget.dart',
    ).readAsString();

    expect(source, isNot(contains('FFAppState().filterCapacityFrom')));
    expect(source, isNot(contains('FFAppState().isFilterShowNearest')));
    expect(source, isNot(contains('FFAppState().isFilterApplied')));
  });
}
