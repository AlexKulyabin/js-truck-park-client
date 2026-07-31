import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/map/application/parking_map_controller.dart';
import 'package:j_s_truck_park/features/map/domain/map_bounds.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_point.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_query.dart';
import 'package:j_s_truck_park/features/map/domain/parking_map_repository.dart';

class _FakeRepository implements ParkingMapRepository {
  final queries = <MapParkingQuery>[];
  final completions = <Completer<List<MapParkingPoint>>>[];
  Object? synchronousError;

  @override
  Future<List<MapParkingPoint>> fetchParkingPoints(MapParkingQuery query) {
    queries.add(query);
    if (synchronousError case final error?) {
      throw error;
    }
    final completer = Completer<List<MapParkingPoint>>();
    completions.add(completer);
    return completer.future;
  }
}

const _firstQuery = MapParkingQuery(
  bounds: MapBounds(
    minLatitude: 50,
    minLongitude: 20,
    maxLatitude: 54,
    maxLongitude: 24,
  ),
  zoom: 13,
  radiusMeters: 0,
  minCapacity: 0,
  maxCapacity: 100,
  needGas: false,
  needShower: false,
  needLaundry: false,
  needHotel: false,
  needShop: false,
  needRecreation: false,
  isFilterActive: false,
);

const _secondQuery = MapParkingQuery(
  bounds: MapBounds(
    minLatitude: 52,
    minLongitude: 22,
    maxLatitude: 56,
    maxLongitude: 26,
  ),
  zoom: 14,
  radiusMeters: 10000,
  minCapacity: 10,
  maxCapacity: 80,
  needGas: true,
  needShower: false,
  needLaundry: false,
  needHotel: false,
  needShop: true,
  needRecreation: false,
  isFilterActive: true,
  searchQuery: 'warsaw',
);

const _firstPoint = MapParkingPoint(
  id: 'parking-1',
  latitude: 52.1,
  longitude: 21.2,
  count: 1,
  isCluster: false,
);

const _secondPoint = MapParkingPoint(
  id: 'parking-2',
  latitude: 53.1,
  longitude: 22.2,
  count: 1,
  isCluster: false,
);

void main() {
  test('publishes loading and an immutable typed result', () async {
    final repository = _FakeRepository();
    final controller = ParkingMapController(repository: repository);

    final loading = controller.load(_firstQuery);

    expect(controller.state.phase, ParkingMapLoadPhase.loading);
    expect(controller.state.query, same(_firstQuery));
    expect(controller.state.points, isEmpty);

    repository.completions.single.complete(const [_firstPoint]);
    await loading;

    expect(controller.state.phase, ParkingMapLoadPhase.loaded);
    expect(controller.state.points, const [_firstPoint]);
    expect(
      () => controller.state.points.add(_secondPoint),
      throwsUnsupportedError,
    );
  });

  test('keeps current markers while the next viewport is loading', () async {
    final repository = _FakeRepository();
    final controller = ParkingMapController(repository: repository);

    final firstLoad = controller.load(_firstQuery);
    repository.completions[0].complete(const [_firstPoint]);
    await firstLoad;

    final secondLoad = controller.load(_secondQuery);

    expect(controller.state.phase, ParkingMapLoadPhase.loading);
    expect(controller.state.query, same(_secondQuery));
    expect(controller.state.points, const [_firstPoint]);

    repository.completions[1].complete(const [_secondPoint]);
    await secondLoad;
    expect(controller.state.points, const [_secondPoint]);
  });

  test('ignores an older camera response that completes last', () async {
    final repository = _FakeRepository();
    final controller = ParkingMapController(repository: repository);

    final firstLoad = controller.load(_firstQuery);
    final secondLoad = controller.load(_secondQuery);
    repository.completions[1].complete(const [_secondPoint]);
    await secondLoad;
    repository.completions[0].complete(const [_firstPoint]);
    await firstLoad;

    expect(controller.state.phase, ParkingMapLoadPhase.loaded);
    expect(controller.state.query, same(_secondQuery));
    expect(controller.state.points, const [_secondPoint]);
  });

  test('ignores an older camera failure that completes last', () async {
    final repository = _FakeRepository();
    final controller = ParkingMapController(repository: repository);

    final firstLoad = controller.load(_firstQuery);
    final secondLoad = controller.load(_secondQuery);
    repository.completions[1].complete(const [_secondPoint]);
    await secondLoad;
    repository.completions[0].completeError(
      const MapReadException(MapReadFailureKind.unavailable),
    );
    await firstLoad;

    expect(controller.state.phase, ParkingMapLoadPhase.loaded);
    expect(controller.state.query, same(_secondQuery));
    expect(controller.state.points, const [_secondPoint]);
  });

  test('retains previous markers on failure and retries the same query',
      () async {
    final repository = _FakeRepository();
    final controller = ParkingMapController(repository: repository);

    final firstLoad = controller.load(_firstQuery);
    repository.completions[0].complete(const [_firstPoint]);
    await firstLoad;

    final failedLoad = controller.load(_secondQuery);
    repository.completions[1].completeError(
      const MapReadException(MapReadFailureKind.invalidData),
    );
    await failedLoad;

    expect(controller.state.phase, ParkingMapLoadPhase.failure);
    expect(controller.state.points, const [_firstPoint]);
    expect(controller.state.failureKind, MapReadFailureKind.invalidData);

    final retry = controller.retry();
    expect(repository.queries, [_firstQuery, _secondQuery, _secondQuery]);
    repository.completions[2].complete(const [_secondPoint]);
    await retry;

    expect(controller.state.phase, ParkingMapLoadPhase.loaded);
    expect(controller.state.points, const [_secondPoint]);
  });

  test('retry is a no-op before the first query', () async {
    final repository = _FakeRepository();
    final controller = ParkingMapController(repository: repository);

    await controller.retry();

    expect(controller.state.phase, ParkingMapLoadPhase.idle);
    expect(repository.queries, isEmpty);
  });

  test('reset clears state and invalidates an in-flight response', () async {
    final repository = _FakeRepository();
    final controller = ParkingMapController(repository: repository);

    final loading = controller.load(_firstQuery);
    controller.reset();
    repository.completions.single.complete(const [_firstPoint]);
    await loading;

    expect(controller.state.phase, ParkingMapLoadPhase.idle);
    expect(controller.state.query, isNull);
    expect(controller.state.points, isEmpty);
  });

  test('maps unexpected errors to a redacted unavailable failure', () async {
    final repository = _FakeRepository()
      ..synchronousError = StateError('raw transport details');
    final controller = ParkingMapController(repository: repository);

    await controller.load(_firstQuery);

    expect(controller.state.phase, ParkingMapLoadPhase.failure);
    expect(controller.state.failureKind, MapReadFailureKind.unavailable);
    expect(controller.state.points, isEmpty);
    expect(
        controller.state.toString(), isNot(contains('raw transport details')));
  });

  test('does not publish a response after disposal', () async {
    final repository = _FakeRepository();
    final controller = ParkingMapController(repository: repository);

    final loading = controller.load(_firstQuery);
    controller.dispose();
    repository.completions.single.complete(const [_firstPoint]);

    await loading;
  });
}
