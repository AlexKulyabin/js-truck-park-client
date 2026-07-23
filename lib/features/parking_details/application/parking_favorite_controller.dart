import 'package:flutter/foundation.dart';

import '../domain/parking_favorite_repository.dart';

enum ParkingFavoriteMutationPhase { idle, updating, failure }

enum ParkingFavoriteToggleOutcome { updated, ignored, failed }

@immutable
class ParkingFavoriteState {
  const ParkingFavoriteState({
    required this.isFavorite,
    required this.phase,
    this.failureKind,
  });

  const ParkingFavoriteState.initial()
      : isFavorite = false,
        phase = ParkingFavoriteMutationPhase.idle,
        failureKind = null;

  final bool isFavorite;
  final ParkingFavoriteMutationPhase phase;
  final ParkingFavoriteFailureKind? failureKind;
}

class ParkingFavoriteController extends ChangeNotifier {
  ParkingFavoriteController({
    required ParkingFavoriteRepository repository,
    required String parkingId,
  })  : _repository = repository,
        _parkingId = parkingId;

  final ParkingFavoriteRepository _repository;
  final String _parkingId;

  ParkingFavoriteState _state = const ParkingFavoriteState.initial();
  bool _initialized = false;
  bool _disposed = false;
  int _mutationGeneration = 0;

  ParkingFavoriteState get state => _state;

  void initialize(bool isFavorite) {
    if (_disposed || _initialized) {
      return;
    }
    _initialized = true;
    _publish(
      ParkingFavoriteState(
        isFavorite: isFavorite,
        phase: ParkingFavoriteMutationPhase.idle,
      ),
    );
  }

  Future<ParkingFavoriteToggleOutcome> toggle() async {
    if (_disposed ||
        !_initialized ||
        _state.phase == ParkingFavoriteMutationPhase.updating) {
      return ParkingFavoriteToggleOutcome.ignored;
    }

    final previousValue = _state.isFavorite;
    final nextValue = !previousValue;
    final generation = ++_mutationGeneration;
    _publish(
      ParkingFavoriteState(
        isFavorite: nextValue,
        phase: ParkingFavoriteMutationPhase.updating,
      ),
    );

    try {
      await _repository.setFavorite(
        parkingId: _parkingId,
        isFavorite: nextValue,
      );
      if (_disposed || generation != _mutationGeneration) {
        return ParkingFavoriteToggleOutcome.ignored;
      }
      _publish(
        ParkingFavoriteState(
          isFavorite: nextValue,
          phase: ParkingFavoriteMutationPhase.idle,
        ),
      );
      return ParkingFavoriteToggleOutcome.updated;
    } on ParkingFavoriteMutationException catch (error) {
      return _publishFailure(
        generation: generation,
        previousValue: previousValue,
        kind: error.kind,
      );
    } catch (_) {
      return _publishFailure(
        generation: generation,
        previousValue: previousValue,
        kind: ParkingFavoriteFailureKind.unavailable,
      );
    }
  }

  ParkingFavoriteToggleOutcome _publishFailure({
    required int generation,
    required bool previousValue,
    required ParkingFavoriteFailureKind kind,
  }) {
    if (_disposed || generation != _mutationGeneration) {
      return ParkingFavoriteToggleOutcome.ignored;
    }
    _publish(
      ParkingFavoriteState(
        isFavorite: previousValue,
        phase: ParkingFavoriteMutationPhase.failure,
        failureKind: kind,
      ),
    );
    return ParkingFavoriteToggleOutcome.failed;
  }

  void _publish(ParkingFavoriteState state) {
    if (_disposed) {
      return;
    }
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _mutationGeneration++;
    super.dispose();
  }
}
