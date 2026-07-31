import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/map/application/parking_filter_controller.dart';
import 'package:j_s_truck_park/features/map/domain/map_bounds.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_point.dart';
import 'package:j_s_truck_park/features/map/presentation/map_marker_item.dart';
import 'package:j_s_truck_park/features/map/presentation/map_read_adapter.dart';
import 'package:j_s_truck_park/features/map/presentation/map_search_result_item.dart';

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

  test('adapts parking filter state to the map filter snapshot', () {
    final snapshot = toMapFilterSnapshot(
      const ParkingFilterState(
        capacityFrom: 5,
        capacityTo: 25,
        hasGas: true,
        hasShower: true,
        hasLaundry: false,
        hasHotel: false,
        hasShop: true,
        hasRecreation: true,
        showNearest: true,
        radiusIndex: 2,
        isApplied: true,
      ),
    );

    expect(snapshot.radiusMeters, 50000);
    expect(snapshot.minCapacity, 5);
    expect(snapshot.maxCapacity, 25);
    expect(snapshot.needGas, isTrue);
    expect(snapshot.needShower, isTrue);
    expect(snapshot.needLaundry, isFalse);
    expect(snapshot.needHotel, isFalse);
    expect(snapshot.needShop, isTrue);
    expect(snapshot.needRecreation, isTrue);
    expect(snapshot.isActive, isTrue);
  });

  test('adapts typed points to immutable map marker items', () {
    final items = toMapMarkerItems(const [
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

    expect(items, const [
      MapMarkerItem(
        id: 'parking-1',
        latitude: 52.1,
        longitude: 21.2,
        count: 1,
        isCluster: false,
      ),
    ]);
    expect(
      () => items.add(
        const MapMarkerItem(
          id: 'parking-2',
          latitude: 52.2,
          longitude: 21.3,
          count: 1,
          isCluster: false,
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('adapts typed points to immutable search result items', () {
    final items = toMapSearchResultItems(const [
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

    expect(
      items,
      const [
        MapSearchResultItem(
          id: 'parking-1',
          latitude: 52.1,
          longitude: 21.2,
          address: 'Test address',
        ),
      ],
    );
    expect(
      () => items.add(
        const MapSearchResultItem(
          id: 'parking-2',
          latitude: 52.2,
          longitude: 21.3,
        ),
      ),
      throwsUnsupportedError,
    );
  });
}
