import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/map/domain/map_bounds.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_point.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_query.dart';

void main() {
  group('MapParkingQuery', () {
    test('preserves all 18 active filtered RPC parameters', () {
      const query = MapParkingQuery(
        bounds: MapBounds(
          minLatitude: 50,
          minLongitude: 20,
          maxLatitude: 54,
          maxLongitude: 24,
        ),
        zoom: 13,
        radiusMeters: 10000,
        minCapacity: 2,
        maxCapacity: 80,
        needGas: true,
        needShower: false,
        needLaundry: true,
        needHotel: false,
        needShop: true,
        needRecreation: false,
        isFilterActive: true,
        searchQuery: 'warsaw',
      );

      expect(
        query.toFilteredRpcParameters(),
        {
          'center_lat': 52.0,
          'center_lng': 22.0,
          'radius_meters': 10000.0,
          'min_lat': 50.0,
          'max_lat': 54.0,
          'min_lng': 20.0,
          'max_lng': 24.0,
          'min_capacity': 2,
          'max_capacity': 80,
          'need_gas': true,
          'need_shower': false,
          'need_laundry': true,
          'need_hotel': false,
          'need_shop': true,
          'need_recreation': false,
          'is_filter_active': true,
          'zoom_level': 13.0,
          'search_query': 'warsaw',
        },
      );
      expect(query.toFilteredRpcParameters(), hasLength(18));
    });

    test('captures the existing lowercase-only search normalization', () {
      expect(normalizeLegacyMapSearch(' WarSaw '), ' warsaw ');
      expect(normalizeLegacyMapSearch(''), '');
    });
  });

  group('MapBounds', () {
    test('calculates the same midpoint used by both active map consumers', () {
      const bounds = MapBounds(
        minLatitude: 50,
        minLongitude: 20,
        maxLatitude: 54,
        maxLongitude: 24,
      );

      expect(bounds.centerLatitude, 52);
      expect(bounds.centerLongitude, 22);
      expect(bounds.hasOrderedLatitudes, isTrue);
      expect(bounds.hasValidCoordinateRanges, isTrue);
      expect(bounds.isFinite, isTrue);
    });

    test('detects an antimeridian viewport unsupported by current SQL', () {
      const bounds = MapBounds(
        minLatitude: -10,
        minLongitude: 170,
        maxLatitude: 10,
        maxLongitude: -170,
      );

      expect(bounds.crossesAntimeridian, isTrue);
      expect(bounds.hasValidCoordinateRanges, isTrue);
    });
  });

  group('MapParkingPoint', () {
    test('maps marker, cluster and low-zoom single-point cluster shapes', () {
      final result = MapParkingPoint.parseFilteredRpcResponse([
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
        {
          'id': 'c_34_14',
          'lat': 51.5,
          'lng': 21.5,
          'count': 12,
          'is_cluster': true,
          'address': null,
          'rating': null,
        },
        {
          'id': 'parking-2',
          'lat': 53,
          'lng': 22,
          'count': 1,
          'is_cluster': true,
          'address': 'Hidden by cluster presentation',
          'rating': 4,
        },
      ]);

      expect(
        result,
        const [
          MapParkingPoint(
            id: 'parking-1',
            latitude: 52.1,
            longitude: 21.2,
            count: 1,
            isCluster: false,
            address: 'Test address',
            rating: 4.5,
          ),
          MapParkingPoint(
            id: 'c_34_14',
            latitude: 51.5,
            longitude: 21.5,
            count: 12,
            isCluster: true,
          ),
          MapParkingPoint(
            id: 'parking-2',
            latitude: 53,
            longitude: 22,
            count: 1,
            isCluster: true,
            address: 'Hidden by cluster presentation',
            rating: 4,
          ),
        ],
      );
    });

    test('rejects a non-list response and malformed rows', () {
      expect(
        () => MapParkingPoint.parseFilteredRpcResponse({'id': 'parking-1'}),
        throwsA(
          isA<MapReadException>().having(
            (error) => error.kind,
            'kind',
            MapReadFailureKind.invalidData,
          ),
        ),
      );
      expect(
        () => MapParkingPoint.parseFilteredRpcResponse([
          {
            'id': '',
            'lat': 52,
            'lng': 21,
            'count': 0,
            'is_cluster': false,
          },
        ]),
        throwsA(isA<MapReadException>()),
      );
      expect(
        () => MapParkingPoint.parseFilteredRpcResponse([
          {
            'id': 'parking-1',
            'lat': 52,
            'lng': 21,
            'count': 1,
            'is_cluster': false,
            'rating': 'raw invalid rating',
          },
        ]),
        throwsA(
          isA<MapReadException>().having(
            (error) => error.toString(),
            'redacted message',
            isNot(contains('raw invalid rating')),
          ),
        ),
      );
    });
  });
}
