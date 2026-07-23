import 'package:flutter/foundation.dart';

import '../domain/parking_request_summary.dart';
import '../domain/parking_requests_repository.dart';

enum ParkingRequestsLoadPhase {
  idle,
  loading,
  loaded,
  failure,
}

@immutable
class ParkingRequestsState {
  const ParkingRequestsState({
    required this.status,
    required this.phase,
    required this.requests,
    this.failureKind,
  });

  const ParkingRequestsState.initial()
      : status = ParkingRequestStatus.pending,
        phase = ParkingRequestsLoadPhase.idle,
        requests = const [],
        failureKind = null;

  final ParkingRequestStatus status;
  final ParkingRequestsLoadPhase phase;
  final List<ParkingRequestSummary> requests;
  final ParkingRequestsFailureKind? failureKind;
}

class ParkingRequestsController extends ChangeNotifier {
  ParkingRequestsController({
    required ParkingRequestsRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId;

  final ParkingRequestsRepository _repository;
  final String _userId;

  ParkingRequestsState _state = const ParkingRequestsState.initial();
  int _loadGeneration = 0;
  bool _disposed = false;

  ParkingRequestsState get state => _state;

  Future<void> load() => _load(ParkingRequestStatus.pending);

  Future<void> selectStatus(ParkingRequestStatus status) {
    if (status == _state.status &&
        _state.phase != ParkingRequestsLoadPhase.idle &&
        _state.phase != ParkingRequestsLoadPhase.failure) {
      return Future.value();
    }
    return _load(status);
  }

  Future<void> retry() => _load(_state.status);

  Future<void> _load(ParkingRequestStatus status) async {
    final generation = ++_loadGeneration;
    _publish(
      ParkingRequestsState(
        status: status,
        phase: ParkingRequestsLoadPhase.loading,
        requests: const [],
      ),
    );

    try {
      final requests = await _repository.fetchOwnedRequests(
        userId: _userId,
        status: status,
      );
      if (generation != _loadGeneration || _disposed) {
        return;
      }
      _publish(
        ParkingRequestsState(
          status: status,
          phase: ParkingRequestsLoadPhase.loaded,
          requests: List.unmodifiable(requests),
        ),
      );
    } on ParkingRequestsReadException catch (error) {
      if (generation != _loadGeneration || _disposed) {
        return;
      }
      _publish(
        ParkingRequestsState(
          status: status,
          phase: ParkingRequestsLoadPhase.failure,
          requests: const [],
          failureKind: error.kind,
        ),
      );
    } catch (_) {
      if (generation != _loadGeneration || _disposed) {
        return;
      }
      _publish(
        ParkingRequestsState(
          status: status,
          phase: ParkingRequestsLoadPhase.failure,
          requests: const [],
          failureKind: ParkingRequestsFailureKind.unavailable,
        ),
      );
    }
  }

  void _publish(ParkingRequestsState state) {
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
