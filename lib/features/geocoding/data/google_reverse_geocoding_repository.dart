import '../../../backend/api_requests/api_calls.dart';
import '../domain/reverse_geocoding_repository.dart';

typedef ReverseGeocodingApiCall = Future<ApiCallResponse> Function({
  required double latitude,
  required double longitude,
});

abstract interface class ReverseGeocodingDataSource {
  Future<Object?> fetchAddressResponse({
    required double latitude,
    required double longitude,
  });
}

class GeneratedGoogleReverseGeocodingDataSource
    implements ReverseGeocodingDataSource {
  GeneratedGoogleReverseGeocodingDataSource({
    ReverseGeocodingApiCall? apiCall,
  }) : _apiCall = apiCall ?? _callGeneratedApi;

  final ReverseGeocodingApiCall _apiCall;

  @override
  Future<Object?> fetchAddressResponse({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiCall(
      latitude: latitude,
      longitude: longitude,
    );
    if (!response.succeeded) {
      throw const ReverseGeocodingException(
        ReverseGeocodingFailureKind.unavailable,
      );
    }
    return response.jsonBody;
  }

  static Future<ApiCallResponse> _callGeneratedApi({
    required double latitude,
    required double longitude,
  }) =>
      GetAddressFromCoordsCall.call(lat: latitude, lng: longitude);
}

class GoogleReverseGeocodingRepository implements ReverseGeocodingRepository {
  GoogleReverseGeocodingRepository({ReverseGeocodingDataSource? dataSource})
      : _dataSource = dataSource ?? GeneratedGoogleReverseGeocodingDataSource();

  final ReverseGeocodingDataSource _dataSource;

  @override
  Future<ReverseGeocodedAddress> findAddress({
    required double latitude,
    required double longitude,
  }) async {
    if (!_isValidCoordinate(latitude: latitude, longitude: longitude)) {
      throw const ReverseGeocodingException(
        ReverseGeocodingFailureKind.invalidCoordinate,
      );
    }

    try {
      final response = await _dataSource.fetchAddressResponse(
        latitude: latitude,
        longitude: longitude,
      );
      return _parseResponse(response);
    } on ReverseGeocodingException {
      rethrow;
    } catch (_) {
      throw const ReverseGeocodingException(
        ReverseGeocodingFailureKind.unavailable,
      );
    }
  }

  ReverseGeocodedAddress _parseResponse(Object? response) {
    if (response is! Map) {
      throw const ReverseGeocodingException(
        ReverseGeocodingFailureKind.invalidData,
      );
    }

    final status = response['status'];
    if (status == 'ZERO_RESULTS') {
      throw const ReverseGeocodingException(
        ReverseGeocodingFailureKind.notFound,
      );
    }
    if (status != 'OK') {
      throw ReverseGeocodingException(
        status is String
            ? ReverseGeocodingFailureKind.unavailable
            : ReverseGeocodingFailureKind.invalidData,
      );
    }

    final results = response['results'];
    if (results is! List || results.isEmpty) {
      throw const ReverseGeocodingException(
        ReverseGeocodingFailureKind.notFound,
      );
    }
    final firstResult = results.first;
    if (firstResult is! Map) {
      throw const ReverseGeocodingException(
        ReverseGeocodingFailureKind.invalidData,
      );
    }
    final formattedAddress = firstResult['formatted_address'];
    if (formattedAddress is! String || formattedAddress.trim().isEmpty) {
      throw const ReverseGeocodingException(
        ReverseGeocodingFailureKind.invalidData,
      );
    }

    return ReverseGeocodedAddress(formattedAddress: formattedAddress);
  }

  bool _isValidCoordinate({
    required double latitude,
    required double longitude,
  }) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}
