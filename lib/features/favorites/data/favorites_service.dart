import '/backend/supabase/database/database.dart';
import '/core/config/app_config.dart';

class FavoriteActionException implements Exception {
  const FavoriteActionException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class FavoritesGateway {
  Future<List<FavoriteParking>> listFavorites({
    required String userId,
  });

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
  SupabaseFavoritesGateway({
    FavoritesTable? favoritesTable,
    ViewUserFavoritesTable? favoritesView,
  })  : _favoritesTable = favoritesTable ?? FavoritesTable(),
        _favoritesView = favoritesView ?? ViewUserFavoritesTable();

  final FavoritesTable _favoritesTable;
  final ViewUserFavoritesTable _favoritesView;

  @override
  Future<List<FavoriteParking>> listFavorites({
    required String userId,
  }) async {
    final rows = await _favoritesView.queryRows(
      queryFn: (q) => q.eqOrNull(
        'user_id',
        userId,
      ),
    );
    return rows.map(FavoriteParking.fromRow).toList();
  }

  @override
  Future<bool> isFavorite({
    required String parkingId,
    required String userId,
  }) async {
    final rows = await _favoritesTable.queryRows(
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
    await _favoritesTable.insert({
      'user_id': userId,
      'parking_id': parkingId,
    });
  }

  @override
  Future<void> removeFavorite({
    required String parkingId,
    required String userId,
  }) async {
    await _favoritesTable.delete(
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

  Future<List<FavoriteParking>> listFavorites({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return const [];
    }

    return _gateway.listFavorites(userId: normalizedUserId);
  }

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

class FavoriteParking {
  const FavoriteParking({
    required this.favoriteRecordId,
    required this.userId,
    required this.parkingId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewsCount,
    required this.photoUrls,
  });

  factory FavoriteParking.fromRow(ViewUserFavoritesRow row) {
    return FavoriteParking(
      favoriteRecordId: row.favoriteRecordId,
      userId: row.userId,
      parkingId: row.parkingId,
      address: row.address,
      latitude: row.latitude,
      longitude: row.longitude,
      rating: row.rating,
      reviewsCount: row.reviewsCount,
      photoUrls: _parsePhotoUrls(row.photos),
    );
  }

  final int? favoriteRecordId;
  final String? userId;
  final String? parkingId;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? reviewsCount;
  final List<String> photoUrls;

  String? get primaryPhotoUrl => photoUrls.isEmpty ? null : photoUrls.first;
}

List<String> _parsePhotoUrls(dynamic photos) {
  if (photos is! Iterable) {
    return const [];
  }

  return photos.whereType<String>().toList(growable: false);
}
