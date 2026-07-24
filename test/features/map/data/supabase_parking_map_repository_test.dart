import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/backend/api_requests/api_calls.dart';
import 'package:j_s_truck_park/features/map/data/supabase_parking_map_repository.dart';
import 'package:j_s_truck_park/features/map/domain/map_bounds.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_point.dart';
import 'package:j_s_truck_park/features/map/domain/map_parking_query.dart';

class _FakeDataSource implements ParkingMapDataSource {
  final queries = <MapParkingQuery>[];
  Object? response = const <Object>[];
  Object? error;

  @override
  Future<Object?> fetchParkingRows(MapParkingQuery query) async {
    queries.add(query);
    if (error case final error?) {
      throw error;
    }
    return response;
  }
}

const _validQuery = MapParkingQuery(
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

void main() {
  group('GeneratedAnonymousParkingMapDataSource', () {
    test('passes the exact bounded RPC body and returns a successful body',
        () async {
      Map<String, Object>? capturedParameters;
      final dataSource = GeneratedAnonymousParkingMapDataSource(
        rpcCall: (parameters) async {
          capturedParameters = parameters;
          return const ApiCallResponse(
            <Object>[
              {
                'id': 'parking-1',
                'lat': 52.1,
                'lng': 21.2,
                'count': 1,
                'is_cluster': false,
              },
            ],
            {},
            200,
          );
        },
      );

      final result = await dataSource.fetchParkingRows(_validQuery);

      expect(capturedParameters, _validQuery.toFilteredRpcParameters());
      expect(capturedParameters, hasLength(18));
      expect(result, isA<List<Object>>());
    });

    test('maps a non-success response to a redacted unavailable failure',
        () async {
      final dataSource = GeneratedAnonymousParkingMapDataSource(
        rpcCall: (_) async => const ApiCallResponse(
          {'message': 'raw backend details'},
          {},
          503,
        ),
      );

      await expectLater(
        dataSource.fetchParkingRows(_validQuery),
        throwsA(
          isA<MapReadException>()
              .having(
                (error) => error.kind,
                'kind',
                MapReadFailureKind.unavailable,
              )
              .having(
                (error) => error.toString(),
                'redacted message',
                isNot(contains('raw backend details')),
              ),
        ),
      );
    });
  });

  group('SupabaseParkingMapRepository', () {
    test('returns an immutable typed marker and cluster result', () async {
      final dataSource = _FakeDataSource()
        ..response = [
          {
            'id': 'parking-1',
            'lat': 52.1,
            'lng': 21.2,
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
        ];
      final repository = SupabaseParkingMapRepository(dataSource: dataSource);

      final result = await repository.fetchParkingPoints(_validQuery);

      expect(dataSource.queries, [_validQuery]);
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
        ],
      );
      expect(() => result.add(result.first), throwsUnsupportedError);
    });

    test('rejects invalid queries before the network boundary', () async {
      final invalidQueries = [
        const MapParkingQuery(
          bounds: MapBounds(
            minLatitude: 50,
            minLongitude: 170,
            maxLatitude: 54,
            maxLongitude: -170,
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
        ),
        const MapParkingQuery(
          bounds: MapBounds(
            minLatitude: 50,
            minLongitude: 20,
            maxLatitude: 54,
            maxLongitude: 24,
          ),
          zoom: double.infinity,
          radiusMeters: -1,
          minCapacity: 80,
          maxCapacity: 2,
          needGas: false,
          needShower: false,
          needLaundry: false,
          needHotel: false,
          needShop: false,
          needRecreation: false,
          isFilterActive: true,
        ),
      ];
      final dataSource = _FakeDataSource();
      final repository = SupabaseParkingMapRepository(dataSource: dataSource);

      for (final query in invalidQueries) {
        await expectLater(
          repository.fetchParkingPoints(query),
          throwsA(
            isA<MapReadException>().having(
              (error) => error.kind,
              'kind',
              MapReadFailureKind.invalidQuery,
            ),
          ),
        );
      }

      expect(dataSource.queries, isEmpty);
    });

    test('keeps invalid response data distinct from transport failure',
        () async {
      final dataSource = _FakeDataSource()..response = {'not': 'a list'};
      final repository = SupabaseParkingMapRepository(dataSource: dataSource);

      await expectLater(
        repository.fetchParkingPoints(_validQuery),
        throwsA(
          isA<MapReadException>().having(
            (error) => error.kind,
            'kind',
            MapReadFailureKind.invalidData,
          ),
        ),
      );
    });

    test('redacts unexpected data-source errors', () async {
      final dataSource = _FakeDataSource()
        ..error = StateError('raw transport details');
      final repository = SupabaseParkingMapRepository(dataSource: dataSource);

      await expectLater(
        repository.fetchParkingPoints(_validQuery),
        throwsA(
          isA<MapReadException>()
              .having(
                (error) => error.kind,
                'kind',
                MapReadFailureKind.unavailable,
              )
              .having(
                (error) => error.toString(),
                'redacted message',
                isNot(contains('raw transport details')),
              ),
        ),
      );
    });
  });
}
