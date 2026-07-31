enum MapReadFailureKind { invalidData, invalidQuery, unavailable }

class MapReadException implements Exception {
  const MapReadException(this.kind);

  final MapReadFailureKind kind;
}

class MapParkingPoint {
  const MapParkingPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.count,
    required this.isCluster,
    this.address,
    this.rating,
  });

  final String id;
  final double latitude;
  final double longitude;
  final int count;
  final bool isCluster;
  final String? address;
  final double? rating;

  static List<MapParkingPoint> parseFilteredRpcResponse(Object? response) {
    if (response is! List) {
      throw const MapReadException(MapReadFailureKind.invalidData);
    }
    return List.unmodifiable(response.map(_parseFilteredRow));
  }

  static MapParkingPoint _parseFilteredRow(Object? value) {
    if (value is! Map) {
      throw const MapReadException(MapReadFailureKind.invalidData);
    }

    final id = value['id'];
    final latitude = _asDouble(value['lat']);
    final longitude = _asDouble(value['lng']);
    final count = _asInt(value['count']);
    final isCluster = value['is_cluster'];
    final address = value['address'];
    final rating = _asNullableDouble(value['rating']);

    if (id is! String ||
        id.isEmpty ||
        latitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude == null ||
        longitude < -180 ||
        longitude > 180 ||
        count == null ||
        count < 1 ||
        isCluster is! bool ||
        address != null && address is! String ||
        rating == _invalidNumber) {
      throw const MapReadException(MapReadFailureKind.invalidData);
    }

    return MapParkingPoint(
      id: id,
      latitude: latitude,
      longitude: longitude,
      count: count,
      isCluster: isCluster,
      address: address as String?,
      rating: rating as double?,
    );
  }

  static const _invalidNumber = Object();

  static double? _asDouble(Object? value) {
    if (value is! num) {
      return null;
    }
    final result = value.toDouble();
    return result.isFinite ? result : null;
  }

  static Object? _asNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }
    return _asDouble(value) ?? _invalidNumber;
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapParkingPoint &&
          id == other.id &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          count == other.count &&
          isCluster == other.isCluster &&
          address == other.address &&
          rating == other.rating;

  @override
  int get hashCode => Object.hash(
        id,
        latitude,
        longitude,
        count,
        isCluster,
        address,
        rating,
      );
}
