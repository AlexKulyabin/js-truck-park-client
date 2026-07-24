import 'package:flutter/foundation.dart';

import '../domain/map_parking_point.dart';
import '../domain/map_parking_query.dart';
import '../domain/parking_map_repository.dart';

enum ParkingMapLoadPhase { idle, loading, loaded, failure }

@immutable
class ParkingMapState {
  const ParkingMapState({
    required this.phase,
    required this.points,
    this.query,
    this.failureKind,
  });

  const ParkingMapState.initial()
      : phase = ParkingMapLoadPhase.idle,
        points = const [],
        query = null,
        failureKind = null;

  final ParkingMapLoadPhase phase;
  final List<MapParkingPoint> points;
  final MapParkingQuery? query;
  final MapReadFailureKind? failureKind;
}

class ParkingMapController extends ChangeNotifier {
  ParkingMapController({required ParkingMapRepository repository})
      : _repository = repository;

  final ParkingMapRepository _repository;

  ParkingMapState _state = const ParkingMapState.initial();
  int _loadGeneration = 0;
  bool _disposed = false;

  ParkingMapState get state => _state;

  Future<void> load(MapParkingQuery query) async {
    final generation = ++_loadGeneration;
    final previousPoints = _state.points;
    _publish(
      ParkingMapState(
        phase: ParkingMapLoadPhase.loading,
        points: previousPoints,
        query: query,
      ),
    );

    try {
      final points = await _repository.fetchParkingPoints(query);
      if (!_isCurrent(generation)) {
        return;
      }
      _publish(
        ParkingMapState(
          phase: ParkingMapLoadPhase.loaded,
          points: List.unmodifiable(points),
          query: query,
        ),
      );
    } on MapReadException catch (error) {
      _publishFailure(
        generation: generation,
        query: query,
        previousPoints: previousPoints,
        kind: error.kind,
      );
    } catch (_) {
      _publishFailure(
        generation: generation,
        query: query,
        previousPoints: previousPoints,
        kind: MapReadFailureKind.unavailable,
      );
    }
  }

  Future<void> retry() {
    final query = _state.query;
    return query == null ? Future.value() : load(query);
  }

  void reset() {
    _loadGeneration++;
    _publish(const ParkingMapState.initial());
  }

  void _publishFailure({
    required int generation,
    required MapParkingQuery query,
    required List<MapParkingPoint> previousPoints,
    required MapReadFailureKind kind,
  }) {
    if (!_isCurrent(generation)) {
      return;
    }
    _publish(
      ParkingMapState(
        phase: ParkingMapLoadPhase.failure,
        points: previousPoints,
        query: query,
        failureKind: kind,
      ),
    );
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _loadGeneration;

  void _publish(ParkingMapState state) {
    if (_disposed) {
      return;
    }
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadGeneration++;
    super.dispose();
  }
}
