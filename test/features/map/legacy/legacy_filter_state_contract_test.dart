import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/app_state.dart';
import 'package:j_s_truck_park/features/map/application/parking_filter_controller.dart';
import 'package:j_s_truck_park/features/map/domain/map_bounds.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_query.dart';
import 'package:j_s_truck_park/features/map/presentation/map_read_adapter.dart';
import 'package:j_s_truck_park/filter/filter/filter_widget.dart';
import 'package:j_s_truck_park/flutter_flow/custom_functions.dart' as functions;
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';
import 'package:provider/provider.dart';

const _openFilterKey = Key('open-filter');

Widget _buildFilterHost(ParkingFilterController controller) => MultiProvider(
      providers: [
        ChangeNotifierProvider<FFAppState>.value(value: FFAppState()),
        ChangeNotifierProvider<ParkingFilterController>.value(
          value: controller,
        ),
      ],
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

Future<ParkingFilterController> _openFilterWithController(
  WidgetTester tester,
) async {
  final controller = ParkingFilterController();
  _setMobileViewSize(tester);
  await tester.pumpWidget(_buildFilterHost(controller));
  await tester.tap(find.byKey(_openFilterKey));
  await tester.pumpAndSettle();
  return controller;
}

void _setMobileViewSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

MapFilterSnapshot _legacyFilterSnapshot(FFAppState state) => MapFilterSnapshot(
      radiusMeters: state.isFilterShowNearest
          ? functions.getMetersFromIndex(state.filterRadius)
          : 0.0,
      minCapacity: state.filterCapacityFrom,
      maxCapacity: state.filterCapacityTo,
      needGas: state.isFilterHasGas,
      needShower: state.isFilterHasShower,
      needLaundry: state.isFilterHasLaundry,
      needHotel: state.isFilterHasHotel,
      needShop: state.isFilterHasShop,
      needRecreation: state.isFilterHasRecreation,
      isActive: state.isFilterApplied,
    );

MapParkingQuery _queryFromLegacyFilter(FFAppState state) =>
    buildMapParkingQuery(
      bounds: const MapBounds(
        minLatitude: 50,
        minLongitude: 20,
        maxLatitude: 54,
        maxLongitude: 24,
      ),
      zoom: 12,
      filter: _legacyFilterSnapshot(state),
      searchQuery: 'war',
    );

void _setNonDefaultFilterState() {
  FFAppState()
    ..filterCapacityFrom = 7
    ..filterCapacityTo = 42
    ..isFilterHasGas = true
    ..isFilterHasShower = true
    ..isFilterHasLaundry = true
    ..isFilterHasHotel = true
    ..isFilterHasShop = true
    ..isFilterHasRecreation = true
    ..isFilterShowNearest = true
    ..filterRadius = 3
    ..isFilterApplied = true;
}

void main() {
  setUp(FFAppState.reset);

  test('legacy filter defaults stay compatible with map reads', () {
    final state = FFAppState();

    expect(state.filterCapacityFrom, 0);
    expect(state.filterCapacityTo, 100);
    expect(state.isFilterHasGas, isFalse);
    expect(state.isFilterHasShower, isFalse);
    expect(state.isFilterHasLaundry, isFalse);
    expect(state.isFilterHasHotel, isFalse);
    expect(state.isFilterHasShop, isFalse);
    expect(state.isFilterHasRecreation, isFalse);
    expect(state.isFilterShowNearest, isFalse);
    expect(state.filterRadius, 0);
    expect(state.isFilterApplied, isFalse);

    final query = _queryFromLegacyFilter(state);
    expect(query.radiusMeters, 0);
    expect(query.minCapacity, 0);
    expect(query.maxCapacity, 100);
    expect(query.isFilterActive, isFalse);
  });

  test('legacy filter radius only affects queries when nearest is enabled', () {
    final state = FFAppState()
      ..filterRadius = 3
      ..isFilterApplied = true;

    expect(_queryFromLegacyFilter(state).radiusMeters, 0);

    state.isFilterShowNearest = true;

    expect(_queryFromLegacyFilter(state).radiusMeters, 100000);
  });

  test('legacy filter query includes every active service flag', () {
    final state = FFAppState()
      ..filterCapacityFrom = 5
      ..filterCapacityTo = 25
      ..isFilterHasGas = true
      ..isFilterHasShower = true
      ..isFilterHasLaundry = true
      ..isFilterHasHotel = true
      ..isFilterHasShop = true
      ..isFilterHasRecreation = true
      ..isFilterShowNearest = true
      ..filterRadius = 1
      ..isFilterApplied = true;

    final parameters = _queryFromLegacyFilter(state).toFilteredRpcParameters();

    expect(parameters['radius_meters'], 10000);
    expect(parameters['min_capacity'], 5);
    expect(parameters['max_capacity'], 25);
    expect(parameters['need_gas'], isTrue);
    expect(parameters['need_shower'], isTrue);
    expect(parameters['need_laundry'], isTrue);
    expect(parameters['need_hotel'], isTrue);
    expect(parameters['need_shop'], isTrue);
    expect(parameters['need_recreation'], isTrue);
    expect(parameters['is_filter_active'], isTrue);
    expect(parameters['search_query'], 'war');
  });

  testWidgets('Reset restores legacy defaults and clears applied state',
      (tester) async {
    _setNonDefaultFilterState();
    final controller = await _openFilterWithController(tester);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(controller.state, const ParkingFilterState.initial());

    final state = FFAppState();
    expect(state.filterCapacityFrom, 0);
    expect(state.filterCapacityTo, 100);
    expect(state.isFilterHasGas, isFalse);
    expect(state.isFilterHasShower, isFalse);
    expect(state.isFilterHasLaundry, isFalse);
    expect(state.isFilterHasHotel, isFalse);
    expect(state.isFilterHasShop, isFalse);
    expect(state.isFilterHasRecreation, isFalse);
    expect(state.isFilterShowNearest, isFalse);
    expect(state.filterRadius, 0);
    expect(state.isFilterApplied, isFalse);
  });

  testWidgets('Apply marks current legacy filter values as active',
      (tester) async {
    FFAppState()
      ..filterCapacityFrom = 7
      ..filterCapacityTo = 42
      ..isFilterHasGas = true
      ..isFilterApplied = false;
    final controller = await _openFilterWithController(tester);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(controller.state.capacityFrom, 7);
    expect(controller.state.capacityTo, 42);
    expect(controller.state.hasGas, isTrue);
    expect(controller.state.isApplied, isTrue);

    final state = FFAppState();
    expect(state.filterCapacityFrom, 7);
    expect(state.filterCapacityTo, 42);
    expect(state.isFilterHasGas, isTrue);
    expect(state.isFilterApplied, isTrue);
  });

  test('Back action closes without applying the legacy filter', () async {
    final source = await File(
      'lib/filter/filter/filter_widget.dart',
    ).readAsString();

    final backActionIndex = source.indexOf('context.safePop();');
    expect(backActionIndex, isNonNegative);

    final backAction = source.substring(
      backActionIndex - 80,
      backActionIndex + 80,
    );
    expect(backAction, isNot(contains('isFilterApplied')));
  });
}
