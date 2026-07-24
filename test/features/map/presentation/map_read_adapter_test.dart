import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/map/domain/map_bounds.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_point.dart';
import 'package:j_s_truck_park/features/map/presentation/map_read_adapter.dart';

void main() {
  test('builds one immutable query snapshot from viewport and filters', () {
    final query = buildMapParkingQuery(
      bounds: const MapBounds(
        minLatitude: 50,
        minLongitude: 20,
        maxLatitude: 54,
        maxLongitude: 24,
      ),
      zoom: 20,
      filter: const MapFilterSnapshot(
        radiusMeters: 10000,
        minCapacity: 2,
        maxCapacity: 80,
        needGas: true,
        needShower: false,
        needLaundry: true,
        needHotel: false,
        needShop: true,
        needRecreation: false,
        isActive: true,
      ),
      searchQuery: 'warsaw',
    );

    expect(query.bounds.centerLatitude, 52);
    expect(query.bounds.centerLongitude, 22);
    expect(query.zoom, 20);
    expect(query.radiusMeters, 10000);
    expect(query.minCapacity, 2);
    expect(query.maxCapacity, 80);
    expect(query.needGas, isTrue);
    expect(query.needLaundry, isTrue);
    expect(query.needShop, isTrue);
    expect(query.isFilterActive, isTrue);
    expect(query.searchQuery, 'warsaw');
  });

  test('adapts typed points to the complete legacy map and search shape', () {
    final items = toLegacyMapItems(const [
      MapParkingPoint(
        id: 'parking-1',
        latitude: 52.1,
        longitude: 21.2,
        count: 1,
        isCluster: false,
        address: 'Test address',
        rating: 4.5,
      ),
    ]);

    expect(items, [
      {
        'id': 'parking-1',
        'lat': 52.1,
        'lng': 21.2,
        'latitude': 52.1,
        'longitude': 21.2,
        'count': 1,
        'is_cluster': false,
        'address': 'Test address',
        'rating': 4.5,
      },
    ]);
    expect(() => items.add(items.first), throwsUnsupportedError);
    expect(() => items.first['id'] = 'changed', throwsUnsupportedError);
  });
}
