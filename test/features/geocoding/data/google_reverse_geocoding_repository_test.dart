import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/backend/api_requests/api_manager.dart';
import 'package:j_s_truck_park/features/geocoding/data/google_reverse_geocoding_repository.dart';
import 'package:j_s_truck_park/features/geocoding/domain/reverse_geocoding_repository.dart';

class _FakeDataSource implements ReverseGeocodingDataSource {
  Object? response;
  Object? error;
  final calls = <({double latitude, double longitude})>[];

  @override
  Future<Object?> fetchAddressResponse({
    required double latitude,
    required double longitude,
  }) async {
    calls.add((latitude: latitude, longitude: longitude));
    if (error case final error?) {
      throw error;
    }
    return response;
  }
}

void main() {
  test('generated data source passes exact coordinates and returns JSON',
      () async {
    double? requestedLatitude;
    double? requestedLongitude;
    final dataSource = GeneratedGoogleReverseGeocodingDataSource(
      apiCall: ({required latitude, required longitude}) async {
        requestedLatitude = latitude;
        requestedLongitude = longitude;
        return const ApiCallResponse(
          {
            'status': 'OK',
            'results': [
              {'formatted_address': 'Test address'},
            ],
          },
          {},
          200,
        );
      },
    );

    final response = await dataSource.fetchAddressResponse(
      latitude: 52.1,
      longitude: 21.2,
    );

    expect(requestedLatitude, 52.1);
    expect(requestedLongitude, 21.2);
    expect(response, isA<Map>());
  });

  test('generated data source maps HTTP failure to unavailable', () async {
    final dataSource = GeneratedGoogleReverseGeocodingDataSource(
      apiCall: ({required latitude, required longitude}) async =>
          const ApiCallResponse({'raw': 'secret'}, {}, 403),
    );

    await expectLater(
      dataSource.fetchAddressResponse(latitude: 52.1, longitude: 21.2),
      throwsA(
        isA<ReverseGeocodingException>().having(
          (error) => error.kind,
          'kind',
          ReverseGeocodingFailureKind.unavailable,
        ),
      ),
    );
  });

  test('repository returns one validated formatted address', () async {
    final dataSource = _FakeDataSource()
      ..response = {
        'status': 'OK',
        'results': [
          {'formatted_address': 'Warszawska 1, Poland'},
        ],
      };
    final repository = GoogleReverseGeocodingRepository(
      dataSource: dataSource,
    );

    final result = await repository.findAddress(
      latitude: 52.1,
      longitude: 21.2,
    );

    expect(result.formattedAddress, 'Warszawska 1, Poland');
    expect(dataSource.calls, [(latitude: 52.1, longitude: 21.2)]);
  });

  test('repository rejects invalid coordinates before transport', () async {
    final dataSource = _FakeDataSource();
    final repository = GoogleReverseGeocodingRepository(
      dataSource: dataSource,
    );

    await expectLater(
      repository.findAddress(latitude: 91, longitude: 21.2),
      throwsA(
        isA<ReverseGeocodingException>().having(
          (error) => error.kind,
          'kind',
          ReverseGeocodingFailureKind.invalidCoordinate,
        ),
      ),
    );
    expect(dataSource.calls, isEmpty);
  });

  test('repository distinguishes no result from malformed data', () async {
    final dataSource = _FakeDataSource()
      ..response = {'status': 'ZERO_RESULTS', 'results': []};
    final repository = GoogleReverseGeocodingRepository(
      dataSource: dataSource,
    );

    await expectLater(
      repository.findAddress(latitude: 52.1, longitude: 21.2),
      throwsA(
        isA<ReverseGeocodingException>().having(
          (error) => error.kind,
          'kind',
          ReverseGeocodingFailureKind.notFound,
        ),
      ),
    );

    dataSource.response = {
      'status': 'OK',
      'results': [
        {'formatted_address': ''},
      ],
    };
    await expectLater(
      repository.findAddress(latitude: 52.1, longitude: 21.2),
      throwsA(
        isA<ReverseGeocodingException>().having(
          (error) => error.kind,
          'kind',
          ReverseGeocodingFailureKind.invalidData,
        ),
      ),
    );
  });

  test('repository redacts unexpected source errors', () async {
    final dataSource = _FakeDataSource()..error = StateError('raw payload');
    final repository = GoogleReverseGeocodingRepository(
      dataSource: dataSource,
    );

    await expectLater(
      repository.findAddress(latitude: 52.1, longitude: 21.2),
      throwsA(
        isA<ReverseGeocodingException>().having(
          (error) => error.kind,
          'kind',
          ReverseGeocodingFailureKind.unavailable,
        ),
      ),
    );
  });
}
