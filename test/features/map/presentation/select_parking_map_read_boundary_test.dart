import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/create_parking2/select_parking/select_parking_widget.dart';
import 'package:j_s_truck_park/features/geocoding/domain/reverse_geocoding_repository.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_point.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_query.dart';
import 'package:j_s_truck_park/features/map/domain/parking_map_repository.dart';

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
  test('SelectParking exposes an injectable parking read boundary', () {
    final repository = _FakeParkingMapRepository();
    final reverseGeocodingRepository = _FakeReverseGeocodingRepository();

    final widget = SelectParkingWidget(
      parkingMapRepository: repository,
      reverseGeocodingRepository: reverseGeocodingRepository,
    );

    expect(widget.parkingMapRepository, same(repository));
    expect(
      widget.reverseGeocodingRepository,
      same(reverseGeocodingRepository),
    );
    expect(SelectParkingWidget.routeName, 'SelectParking');
    expect(SelectParkingWidget.routePath, '/selectParking');
  });

  test('SelectParking isolates reads without changing the create flow',
      () async {
    final source = await File(
      'lib/create_parking2/select_parking/select_parking_widget.dart',
    ).readAsString();

    expect(source, isNot(contains('GetFilteredParkingsCall')));
    expect(source, isNot(contains('GetAddressFromCoordsCall')));
    expect(source, contains('_parkingMapController'));
    expect(source, contains('_reverseGeocodingService'));
    expect(source, contains('CreateParkingDialog2Widget'));
  });
}
