import 'package:flutter/foundation.dart';

@immutable
class MapMarkerItem {
  const MapMarkerItem({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.count,
    required this.isCluster,
  });

  final String id;
  final double latitude;
  final double longitude;
  final int count;
  final bool isCluster;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapMarkerItem &&
          id == other.id &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          count == other.count &&
          isCluster == other.isCluster;

  @override
  int get hashCode => Object.hash(
        id,
        latitude,
        longitude,
        count,
        isCluster,
      );
}
