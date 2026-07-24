import 'package:flutter/foundation.dart';

import '../data/favorites_service.dart';

enum FavoritesLoadStatus {
  initial,
  loading,
  loaded,
  failure,
}

class FavoritesState {
  const FavoritesState({
    this.status = FavoritesLoadStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final FavoritesLoadStatus status;
  final List<FavoriteParking> items;
  final String? errorMessage;

  bool get isLoading =>
      status == FavoritesLoadStatus.initial ||
      status == FavoritesLoadStatus.loading;

  FavoritesState copyWith({
    FavoritesLoadStatus? status,
    List<FavoriteParking>? items,
    Object? errorMessage = _unset,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class FavoritesController extends ChangeNotifier {
  FavoritesController({
    FavoritesService? service,
  }) : _service = service ?? FavoritesService();

  final FavoritesService _service;

  FavoritesState _state = const FavoritesState();
  int _loadGeneration = 0;

  FavoritesState get state => _state;

  Future<void> load({
    required String userId,
  }) async {
    final generation = ++_loadGeneration;
    _setState(
      _state.copyWith(
        status: FavoritesLoadStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final items = await _service.listFavorites(userId: userId);
      if (generation != _loadGeneration) {
        return;
      }

      _setState(
        FavoritesState(
          status: FavoritesLoadStatus.loaded,
          items: items,
        ),
      );
    } catch (_) {
      if (generation != _loadGeneration) {
        return;
      }

      _setState(
        _state.copyWith(
          status: FavoritesLoadStatus.failure,
          errorMessage: 'Could not load favorites.',
        ),
      );
    }
  }

  void _setState(FavoritesState state) {
    _state = state;
    notifyListeners();
  }
}

const _unset = Object();
