import 'package:flutter/foundation.dart';

@immutable
class MapSearchResultItem {
  const MapSearchResultItem({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String? address;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapSearchResultItem &&
          id == other.id &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          address == other.address;

  @override
  int get hashCode => Object.hash(id, latitude, longitude, address);
}
