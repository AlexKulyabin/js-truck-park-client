import '/backend/supabase/database/database.dart';
import '/core/config/app_config.dart';

class FavoriteActionException implements Exception {
  const FavoriteActionException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class FavoritesGateway {
  Future<bool> isFavorite({
    required String parkingId,
    required String userId,
  });

  Future<void> addFavorite({
    required String parkingId,
    required String userId,
  });

  Future<void> removeFavorite({
    required String parkingId,
    required String userId,
  });
}

class SupabaseFavoritesGateway implements FavoritesGateway {
  SupabaseFavoritesGateway({FavoritesTable? table})
      : _table = table ?? FavoritesTable();

  final FavoritesTable _table;

  @override
  Future<bool> isFavorite({
    required String parkingId,
    required String userId,
  }) async {
    final rows = await _table.queryRows(
      queryFn: (q) => q
          .eqOrNull(
            'parking_id',
            parkingId,
          )
          .eqOrNull(
            'user_id',
            userId,
          ),
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> addFavorite({
    required String parkingId,
    required String userId,
  }) async {
    await _table.insert({
      'user_id': userId,
      'parking_id': parkingId,
    });
  }

  @override
  Future<void> removeFavorite({
    required String parkingId,
    required String userId,
  }) async {
    await _table.delete(
      matchingRows: (rows) => rows
          .eqOrNull(
            'parking_id',
            parkingId,
          )
          .eqOrNull(
            'user_id',
            userId,
          ),
    );
  }
}

class FavoritesService {
  FavoritesService({
    FavoritesGateway? gateway,
    AppConfig? config,
  })  : _gateway = gateway ?? SupabaseFavoritesGateway(),
        _config = config ?? AppConfig.current;

  final FavoritesGateway _gateway;
  final AppConfig _config;

  Future<bool> isFavorite({
    required String? parkingId,
    required String userId,
  }) async {
    final ids = _normalizeIds(parkingId: parkingId, userId: userId);
    if (ids == null) {
      return false;
    }

    return _gateway.isFavorite(
      parkingId: ids.parkingId,
      userId: ids.userId,
    );
  }

  Future<bool> toggleFavorite({
    required String? parkingId,
    required String userId,
    required bool currentlyFavorite,
  }) async {
    if (!_config.canPerformWrite(AppWriteOperation.favoriteToggle)) {
      throw const FavoriteActionException(
        'Favorite changes are disabled for this build.',
      );
    }

    final ids = _normalizeIds(parkingId: parkingId, userId: userId);
    if (ids == null) {
      throw const FavoriteActionException(
        'Sign in again before changing favorites.',
      );
    }

    if (currentlyFavorite) {
      await _gateway.removeFavorite(
        parkingId: ids.parkingId,
        userId: ids.userId,
      );
      return false;
    }

    await _gateway.addFavorite(
      parkingId: ids.parkingId,
      userId: ids.userId,
    );
    return true;
  }

  _FavoriteIds? _normalizeIds({
    required String? parkingId,
    required String userId,
  }) {
    final normalizedParkingId = parkingId?.trim();
    final normalizedUserId = userId.trim();
    if (normalizedParkingId == null ||
        normalizedParkingId.isEmpty ||
        normalizedUserId.isEmpty) {
      return null;
    }

    return _FavoriteIds(
      parkingId: normalizedParkingId,
      userId: normalizedUserId,
    );
  }
}

class _FavoriteIds {
  const _FavoriteIds({
    required this.parkingId,
    required this.userId,
  });

  final String parkingId;
  final String userId;
}
