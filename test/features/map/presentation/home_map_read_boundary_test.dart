import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/geocoding/domain/reverse_geocoding_repository.dart';
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

class _FakeReverseGeocodingRepository implements ReverseGeocodingRepository {
  @override
  Future<ReverseGeocodedAddress> findAddress({
    required double latitude,
    required double longitude,
  }) async =>
      const ReverseGeocodedAddress(formattedAddress: 'Test address');
}

void main() {
  test('Home exposes an injectable parking read boundary', () {
    final repository = _FakeParkingMapRepository();
    final reverseGeocodingRepository = _FakeReverseGeocodingRepository();

    final widget = HomePageWidget(
      parkingMapRepository: repository,
      reverseGeocodingRepository: reverseGeocodingRepository,
    );

    expect(widget.parkingMapRepository, same(repository));
    expect(
      widget.reverseGeocodingRepository,
      same(reverseGeocodingRepository),
    );
    expect(HomePageWidget.routeName, 'HomePage');
    expect(HomePageWidget.routePath, '/homePage');
  });

  test('Home does not call the generated parking RPC directly', () async {
    final source = await File(
      'lib/map/home_page/home_page_widget.dart',
    ).readAsString();

    expect(source, isNot(contains('GetFilteredParkingsCall')));
    expect(source, isNot(contains('GetAddressFromCoordsCall')));
    expect(source, contains('_parkingMapController'));
    expect(source, contains('_parkingSearchController'));
    expect(source, contains('_reverseGeocodingService'));
    expect(source, contains('toMapMarkerItems(state.points)'));
    expect(source, contains('toMapSearchResultItems(state.points)'));
    expect(source, contains('markers: _model.parkingsOnMap'));
    expect(source, isNot(contains('markerData:')));
    expect(source, isNot(contains('toLegacyMapItems')));
    expect(source, isNot(contains('getJsonField(')));
  });
}
