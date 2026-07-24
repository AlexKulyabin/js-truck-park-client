import '../domain/reverse_geocoding_repository.dart';

class ReverseGeocodingService {
  ReverseGeocodingService({required ReverseGeocodingRepository repository})
      : _repository = repository;

  final ReverseGeocodingRepository _repository;

  Future<String> resolveAddress({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final result = await _repository.findAddress(
        latitude: latitude,
        longitude: longitude,
      );
      return result.formattedAddress;
    } on ReverseGeocodingException {
      return '';
    }
  }
}
