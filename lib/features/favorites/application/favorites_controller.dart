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

enum FavoriteToggleStatus {
  initial,
  loading,
  loaded,
  updating,
  failure,
}

class FavoriteToggleState {
  const FavoriteToggleState({
    this.status = FavoriteToggleStatus.initial,
    this.isFavorite = false,
    this.errorMessage,
  });

  final FavoriteToggleStatus status;
  final bool isFavorite;
  final String? errorMessage;

  bool get isUpdating => status == FavoriteToggleStatus.updating;

  FavoriteToggleState copyWith({
    FavoriteToggleStatus? status,
    bool? isFavorite,
    Object? errorMessage = _unset,
  }) {
    return FavoriteToggleState(
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class FavoriteToggleController extends ChangeNotifier {
  FavoriteToggleController({
    FavoritesService? service,
  }) : _service = service ?? FavoritesService();

  final FavoritesService _service;

  FavoriteToggleState _state = const FavoriteToggleState();
  int _loadGeneration = 0;

  FavoriteToggleState get state => _state;

  Future<void> load({
    required String? parkingId,
    required String userId,
  }) async {
    final generation = ++_loadGeneration;
    _setState(
      _state.copyWith(
        status: FavoriteToggleStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final isFavorite = await _service.isFavorite(
        parkingId: parkingId,
        userId: userId,
      );
      if (generation != _loadGeneration) {
        return;
      }

      _setState(
        FavoriteToggleState(
          status: FavoriteToggleStatus.loaded,
          isFavorite: isFavorite,
        ),
      );
    } catch (_) {
      if (generation != _loadGeneration) {
        return;
      }

      _setState(
        _state.copyWith(
          status: FavoriteToggleStatus.failure,
          errorMessage: 'Could not load favorite status.',
        ),
      );
    }
  }

  Future<bool> toggle({
    required String? parkingId,
    required String userId,
  }) async {
    if (_state.isUpdating) {
      return false;
    }

    final previousValue = _state.isFavorite;
    _setState(
      _state.copyWith(
        status: FavoriteToggleStatus.updating,
        isFavorite: !previousValue,
        errorMessage: null,
      ),
    );

    try {
      final isFavorite = await _service.toggleFavorite(
        parkingId: parkingId,
        userId: userId,
        currentlyFavorite: previousValue,
      );
      _setState(
        FavoriteToggleState(
          status: FavoriteToggleStatus.loaded,
          isFavorite: isFavorite,
        ),
      );
      return true;
    } catch (_) {
      _setState(
        FavoriteToggleState(
          status: FavoriteToggleStatus.failure,
          isFavorite: previousValue,
          errorMessage: 'Could not update favorites.',
        ),
      );
      return false;
    }
  }

  void _setState(FavoriteToggleState state) {
    _state = state;
    notifyListeners();
  }
}

const _unset = Object();
