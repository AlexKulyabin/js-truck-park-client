import 'package:flutter/foundation.dart';

import '../domain/favorite_parking_summary.dart';
import '../domain/favorites_repository.dart';

enum FavoritesLoadPhase { idle, loading, loaded, failure }

@immutable
class FavoritesState {
  const FavoritesState({
    required this.phase,
    required this.favorites,
    this.failureKind,
  });

  const FavoritesState.initial()
      : phase = FavoritesLoadPhase.idle,
        favorites = const [],
        failureKind = null;

  final FavoritesLoadPhase phase;
  final List<FavoriteParkingSummary> favorites;
  final FavoritesFailureKind? failureKind;
}

class FavoritesController extends ChangeNotifier {
  FavoritesController({
    required FavoritesRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId;

  final FavoritesRepository _repository;
  final String _userId;

  FavoritesState _state = const FavoritesState.initial();
  int _loadGeneration = 0;
  bool _disposed = false;

  FavoritesState get state => _state;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _publish(
      const FavoritesState(
        phase: FavoritesLoadPhase.loading,
        favorites: [],
      ),
    );

    try {
      final favorites = await _repository.fetchOwnedFavorites(_userId);
      if (_disposed || generation != _loadGeneration) {
        return;
      }
      _publish(
        FavoritesState(
          phase: FavoritesLoadPhase.loaded,
          favorites: List.unmodifiable(favorites),
        ),
      );
    } on FavoritesReadException catch (error) {
      _publishFailure(generation, error.kind);
    } catch (_) {
      _publishFailure(generation, FavoritesFailureKind.unavailable);
    }
  }

  Future<void> retry() => load();

  void _publishFailure(int generation, FavoritesFailureKind kind) {
    if (_disposed || generation != _loadGeneration) {
      return;
    }
    _publish(
      FavoritesState(
        phase: FavoritesLoadPhase.failure,
        favorites: const [],
        failureKind: kind,
      ),
    );
  }

  void _publish(FavoritesState state) {
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
