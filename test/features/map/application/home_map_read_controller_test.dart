import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/map/application/home_map_read_controller.dart';
import 'package:j_s_truck_park/features/map/domain/map_bounds.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_point.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_query.dart';
import 'package:j_s_truck_park/features/map/domain/parking_map_repository.dart';

class _FakeRepository implements ParkingMapRepository {
  final queries = <MapParkingQuery>[];
  final completions = <Completer<List<MapParkingPoint>>>[];

  @override
  Future<List<MapParkingPoint>> fetchParkingPoints(MapParkingQuery query) {
    queries.add(query);
    final completer = Completer<List<MapParkingPoint>>();
    completions.add(completer);
    return completer.future;
  }
}

const _viewportQuery = MapParkingQuery(
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

const _searchQuery = MapParkingQuery(
  bounds: MapBounds(
    minLatitude: 50,
    minLongitude: 20,
    maxLatitude: 54,
    maxLongitude: 24,
  ),
  zoom: 20,
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
  searchQuery: 'war',
);

const _newSearchQuery = MapParkingQuery(
  bounds: MapBounds(
    minLatitude: 51,
    minLongitude: 21,
    maxLatitude: 55,
    maxLongitude: 25,
  ),
  zoom: 20,
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
  searchQuery: 'warsaw',
);

const _viewportPoint = MapParkingPoint(
  id: 'parking-1',
  latitude: 52.1,
  longitude: 21.2,
  count: 1,
  isCluster: false,
);

const _searchPoint = MapParkingPoint(
  id: 'parking-2',
  latitude: 53.1,
  longitude: 22.2,
  count: 1,
  isCluster: false,
);

const _newSearchPoint = MapParkingPoint(
  id: 'parking-3',
  latitude: 54.1,
  longitude: 23.2,
  count: 1,
  isCluster: false,
);

void main() {
  test('loads viewport and search through independent read channels', () async {
    final repository = _FakeRepository();
    final controller = HomeMapReadController(repository: repository);

    final viewportLoad = controller.loadViewport(_viewportQuery);
    final searchLoad = controller.loadSearch(_searchQuery);

    expect(repository.queries, [_viewportQuery, _searchQuery]);

    repository.completions[1].complete(const [_searchPoint]);
    await expectLater(searchLoad, completion(const [_searchPoint]));

    repository.completions[0].complete(const [_viewportPoint]);
    await expectLater(viewportLoad, completion(const [_viewportPoint]));

    controller.dispose();
  });

  test('resetSearch invalidates only pending search results', () async {
    final repository = _FakeRepository();
    final controller = HomeMapReadController(repository: repository);

    final viewportLoad = controller.loadViewport(_viewportQuery);
    final searchLoad = controller.loadSearch(_searchQuery);

    controller.resetSearch();
    repository.completions[1].complete(const [_searchPoint]);
    await expectLater(searchLoad, completion(isNull));

    repository.completions[0].complete(const [_viewportPoint]);
    await expectLater(viewportLoad, completion(const [_viewportPoint]));

    controller.dispose();
  });

  test('older search load returns null after a newer search wins', () async {
    final repository = _FakeRepository();
    final controller = HomeMapReadController(repository: repository);

    final firstLoad = controller.loadSearch(_searchQuery);
    final secondLoad = controller.loadSearch(_newSearchQuery);

    repository.completions[1].complete(const [_newSearchPoint]);
    await expectLater(secondLoad, completion(const [_newSearchPoint]));

    repository.completions[0].complete(const [_searchPoint]);
    await expectLater(firstLoad, completion(isNull));

    controller.dispose();
  });
}
