import '../domain/map_parking_point.dart';
import '../domain/map_parking_query.dart';
import '../domain/parking_map_repository.dart';
import 'parking_map_controller.dart';

class HomeMapReadController {
  HomeMapReadController({
    required ParkingMapRepository repository,
  })  : _viewportController = ParkingMapController(repository: repository),
        _searchController = ParkingMapController(repository: repository);

  final ParkingMapController _viewportController;
  final ParkingMapController _searchController;

  Future<List<MapParkingPoint>?> loadViewport(MapParkingQuery query) async {
    return _loadCurrent(_viewportController, query);
  }

  Future<List<MapParkingPoint>?> loadSearch(MapParkingQuery query) async {
    return _loadCurrent(_searchController, query);
  }

  void resetSearch() {
    _searchController.reset();
  }

  Future<List<MapParkingPoint>?> _loadCurrent(
    ParkingMapController controller,
    MapParkingQuery query,
  ) async {
    await controller.load(query);
    final state = controller.state;
    if (!identical(state.query, query) ||
        state.phase != ParkingMapLoadPhase.loaded) {
      return null;
    }
    return state.points;
  }

  void dispose() {
    _viewportController.dispose();
    _searchController.dispose();
  }
}
