import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_point.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_query.dart';
import 'package:j_s_truck_park/features/map/domain/parking_map_repository.dart';
import 'package:j_s_truck_park/map/home_page/home_page_widget.dart';

class _FakeParkingMapRepository implements ParkingMapRepository {
  @override
  Future<List<MapParkingPoint>> fetchParkingPoints(
      MapParkingQuery query) async {
    return const [];
  }
}

void main() {
  test('Home exposes an injectable parking read boundary', () {
    final repository = _FakeParkingMapRepository();

    final widget = HomePageWidget(parkingMapRepository: repository);

    expect(widget.parkingMapRepository, same(repository));
    expect(HomePageWidget.routeName, 'HomePage');
    expect(HomePageWidget.routePath, '/homePage');
  });

  test('Home does not call the generated parking RPC directly', () async {
    final source = await File(
      'lib/map/home_page/home_page_widget.dart',
    ).readAsString();

    expect(source, isNot(contains('GetFilteredParkingsCall')));
    expect(source, contains('_parkingMapController'));
    expect(source, contains('_parkingSearchController'));
  });
}
