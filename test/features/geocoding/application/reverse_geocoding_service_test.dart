import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/geocoding/application/reverse_geocoding_service.dart';
import 'package:j_s_truck_park/features/geocoding/domain/reverse_geocoding_repository.dart';

class _FakeRepository implements ReverseGeocodingRepository {
  ReverseGeocodedAddress? result;
  ReverseGeocodingException? error;

  @override
  Future<ReverseGeocodedAddress> findAddress({
    required double latitude,
    required double longitude,
  }) async {
    if (error case final error?) {
      throw error;
    }
    return result!;
  }
}

void main() {
  test('returns the validated formatted address', () async {
    final repository = _FakeRepository()
      ..result = const ReverseGeocodedAddress(
        formattedAddress: 'Warszawska 1, Poland',
      );
    final service = ReverseGeocodingService(repository: repository);

    final result = await service.resolveAddress(
      latitude: 52.1,
      longitude: 21.2,
    );

    expect(result, 'Warszawska 1, Poland');
  });

  test('returns a safe empty value for every typed failure', () async {
    final repository = _FakeRepository();
    final service = ReverseGeocodingService(repository: repository);

    for (final kind in ReverseGeocodingFailureKind.values) {
      repository.error = ReverseGeocodingException(kind);

      expect(
        await service.resolveAddress(latitude: 52.1, longitude: 21.2),
        isEmpty,
      );
    }
  });
}
