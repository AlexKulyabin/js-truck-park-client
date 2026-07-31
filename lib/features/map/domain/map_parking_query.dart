import 'map_bounds.dart';

class MapParkingQuery {
  const MapParkingQuery({
    required this.bounds,
    required this.zoom,
    required this.radiusMeters,
    required this.minCapacity,
    required this.maxCapacity,
    required this.needGas,
    required this.needShower,
    required this.needLaundry,
    required this.needHotel,
    required this.needShop,
    required this.needRecreation,
    required this.isFilterActive,
    this.searchQuery = '',
  });

  final MapBounds bounds;
  final double zoom;
  final double radiusMeters;
  final int minCapacity;
  final int maxCapacity;
  final bool needGas;
  final bool needShower;
  final bool needLaundry;
  final bool needHotel;
  final bool needShop;
  final bool needRecreation;
  final bool isFilterActive;
  final String searchQuery;

  Map<String, Object> toFilteredRpcParameters() => {
        'center_lat': bounds.centerLatitude,
        'center_lng': bounds.centerLongitude,
        'radius_meters': radiusMeters,
        'min_lat': bounds.minLatitude,
        'max_lat': bounds.maxLatitude,
        'min_lng': bounds.minLongitude,
        'max_lng': bounds.maxLongitude,
        'min_capacity': minCapacity,
        'max_capacity': maxCapacity,
        'need_gas': needGas,
        'need_shower': needShower,
        'need_laundry': needLaundry,
        'need_hotel': needHotel,
        'need_shop': needShop,
        'need_recreation': needRecreation,
        'is_filter_active': isFilterActive,
        'zoom_level': zoom,
        'search_query': searchQuery,
      };
}

String normalizeLegacyMapSearch(String value) => value.toLowerCase();
