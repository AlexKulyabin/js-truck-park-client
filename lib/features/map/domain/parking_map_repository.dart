import 'map_parking_point.dart';
import 'map_parking_query.dart';

abstract interface class ParkingMapRepository {
  Future<List<MapParkingPoint>> fetchParkingPoints(MapParkingQuery query);
}
