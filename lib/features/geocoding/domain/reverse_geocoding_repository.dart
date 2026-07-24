import 'package:flutter/foundation.dart';

enum ReverseGeocodingFailureKind {
  invalidCoordinate,
  notFound,
  invalidData,
  unavailable,
}

class ReverseGeocodingException implements Exception {
  const ReverseGeocodingException(this.kind);

  final ReverseGeocodingFailureKind kind;
}

@immutable
class ReverseGeocodedAddress {
  const ReverseGeocodedAddress({required this.formattedAddress});

  final String formattedAddress;
}

abstract interface class ReverseGeocodingRepository {
  Future<ReverseGeocodedAddress> findAddress({
    required double latitude,
    required double longitude,
  });
}
