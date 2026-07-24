import 'package:flutter/foundation.dart';

import '../domain/map_bounds.dart';
import '../domain/map_parking_point.dart';
import '../domain/map_parking_query.dart';
import 'map_marker_item.dart';
import 'map_search_result_item.dart';

@immutable
class MapFilterSnapshot {
  const MapFilterSnapshot({
    required this.radiusMeters,
    required this.minCapacity,
    required this.maxCapacity,
    required this.needGas,
    required this.needShower,
    required this.needLaundry,
    required this.needHotel,
    required this.needShop,
    required this.needRecreation,
    required this.isActive,
  });

  final double radiusMeters;
  final int minCapacity;
  final int maxCapacity;
  final bool needGas;
  final bool needShower;
  final bool needLaundry;
  final bool needHotel;
  final bool needShop;
  final bool needRecreation;
  final bool isActive;
}

MapParkingQuery buildMapParkingQuery({
  required MapBounds bounds,
  required double zoom,
  required MapFilterSnapshot filter,
  String searchQuery = '',
}) =>
    MapParkingQuery(
      bounds: bounds,
      zoom: zoom,
      radiusMeters: filter.radiusMeters,
      minCapacity: filter.minCapacity,
      maxCapacity: filter.maxCapacity,
      needGas: filter.needGas,
      needShower: filter.needShower,
      needLaundry: filter.needLaundry,
      needHotel: filter.needHotel,
      needShop: filter.needShop,
      needRecreation: filter.needRecreation,
      isFilterActive: filter.isActive,
      searchQuery: searchQuery,
    );

List<MapMarkerItem> toMapMarkerItems(
  List<MapParkingPoint> points,
) =>
    List.unmodifiable(
      points.map(
        (point) => MapMarkerItem(
          id: point.id,
          latitude: point.latitude,
          longitude: point.longitude,
          count: point.count,
          isCluster: point.isCluster,
        ),
      ),
    );

List<MapSearchResultItem> toMapSearchResultItems(
  List<MapParkingPoint> points,
) =>
    List.unmodifiable(
      points.map(
        (point) => MapSearchResultItem(
          id: point.id,
          latitude: point.latitude,
          longitude: point.longitude,
          address: point.address,
        ),
      ),
    );
