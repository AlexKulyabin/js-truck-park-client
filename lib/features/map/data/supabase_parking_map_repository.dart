import '../../../backend/api_requests/api_calls.dart';
import '../domain/map_parking_point.dart';
import '../domain/map_parking_query.dart';
import '../domain/parking_map_repository.dart';

typedef FilteredParkingRpcCall = Future<ApiCallResponse> Function(
  Map<String, Object> parameters,
);

abstract interface class ParkingMapDataSource {
  Future<Object?> fetchParkingRows(MapParkingQuery query);
}

class GeneratedAnonymousParkingMapDataSource implements ParkingMapDataSource {
  GeneratedAnonymousParkingMapDataSource({FilteredParkingRpcCall? rpcCall})
      : _rpcCall = rpcCall ?? _callGeneratedRpc;

  final FilteredParkingRpcCall _rpcCall;

  @override
  Future<Object?> fetchParkingRows(MapParkingQuery query) async {
    final response = await _rpcCall(query.toFilteredRpcParameters());
    if (!response.succeeded) {
      throw const MapReadException(MapReadFailureKind.unavailable);
    }
    return response.jsonBody;
  }

  static Future<ApiCallResponse> _callGeneratedRpc(
    Map<String, Object> parameters,
  ) =>
      GetFilteredParkingsCall.call(
        lat: parameters['center_lat']! as double,
        lng: parameters['center_lng']! as double,
        radius: parameters['radius_meters']! as double,
        minLat: parameters['min_lat']! as double,
        maxLat: parameters['max_lat']! as double,
        minLng: parameters['min_lng']! as double,
        maxLng: parameters['max_lng']! as double,
        minCap: parameters['min_capacity']! as int,
        maxCap: parameters['max_capacity']! as int,
        gas: parameters['need_gas']! as bool,
        shower: parameters['need_shower']! as bool,
        laundry: parameters['need_laundry']! as bool,
        hotel: parameters['need_hotel']! as bool,
        shop: parameters['need_shop']! as bool,
        recreation: parameters['need_recreation']! as bool,
        isActive: parameters['is_filter_active']! as bool,
        zoom: parameters['zoom_level']! as double,
        searchQuery: parameters['search_query']! as String,
      );
}

class SupabaseParkingMapRepository implements ParkingMapRepository {
  SupabaseParkingMapRepository({ParkingMapDataSource? dataSource})
      : _dataSource = dataSource ?? GeneratedAnonymousParkingMapDataSource();

  final ParkingMapDataSource _dataSource;

  @override
  Future<List<MapParkingPoint>> fetchParkingPoints(
    MapParkingQuery query,
  ) async {
    if (!_isValid(query)) {
      throw const MapReadException(MapReadFailureKind.invalidQuery);
    }

    try {
      final response = await _dataSource.fetchParkingRows(query);
      return MapParkingPoint.parseFilteredRpcResponse(response);
    } on MapReadException {
      rethrow;
    } catch (_) {
      throw const MapReadException(MapReadFailureKind.unavailable);
    }
  }

  bool _isValid(MapParkingQuery query) {
    final bounds = query.bounds;
    return bounds.isFinite &&
        bounds.hasValidCoordinateRanges &&
        bounds.hasOrderedLatitudes &&
        !bounds.crossesAntimeridian &&
        query.zoom.isFinite &&
        query.radiusMeters.isFinite &&
        query.radiusMeters >= 0 &&
        query.minCapacity >= 0 &&
        query.maxCapacity >= query.minCapacity;
  }
}
