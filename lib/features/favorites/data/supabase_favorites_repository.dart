import '../../../backend/supabase/supabase.dart';
import '../domain/favorite_parking_summary.dart';
import '../domain/favorites_repository.dart';

abstract interface class FavoritesDataSource {
  Future<List<Map<String, dynamic>>> fetchOwnedRows(String userId);
}

class GeneratedFavoritesDataSource implements FavoritesDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchOwnedRows(String userId) async {
    final rows = await ViewUserFavoritesTable().queryRows(
      queryFn: (query) => query.eq('user_id', userId),
    );
    return rows
        .map((row) => Map<String, dynamic>.unmodifiable(row.data))
        .toList(growable: false);
  }
}

class SupabaseFavoritesRepository implements FavoritesRepository {
  SupabaseFavoritesRepository({FavoritesDataSource? dataSource})
      : _dataSource = dataSource ?? GeneratedFavoritesDataSource();

  final FavoritesDataSource _dataSource;

  @override
  Future<List<FavoriteParkingSummary>> fetchOwnedFavorites(
    String userId,
  ) async {
    if (userId.isEmpty) {
      return const [];
    }

    try {
      final rows = await _dataSource.fetchOwnedRows(userId);
      return rows
          .map((row) => _mapRow(row, expectedUserId: userId))
          .toList(growable: false);
    } on FavoritesReadException {
      rethrow;
    } catch (_) {
      throw const FavoritesReadException(FavoritesFailureKind.unavailable);
    }
  }

  FavoriteParkingSummary _mapRow(
    Map<String, dynamic> row, {
    required String expectedUserId,
  }) {
    final favoriteRecordId = _asInt(row['favorite_record_id']);
    final userId = row['user_id'];
    final parkingId = row['parking_id'];
    final address = row['address'];
    final latitude = _asDouble(row['latitude']);
    final longitude = _asDouble(row['longitude']);

    if (favoriteRecordId == null ||
        favoriteRecordId <= 0 ||
        userId is! String ||
        userId != expectedUserId ||
        parkingId is! String ||
        parkingId.isEmpty ||
        address is! String ||
        latitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude == null ||
        longitude < -180 ||
        longitude > 180) {
      throw const FavoritesReadException(FavoritesFailureKind.invalidData);
    }

    return FavoriteParkingSummary(
      favoriteRecordId: favoriteRecordId,
      parkingId: parkingId,
      address: address,
      latitude: latitude,
      longitude: longitude,
      thumbnailUrl: _firstPhotoUrl(row['photos']),
    );
  }

  String? _firstPhotoUrl(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! List ||
        value.any((item) => item is! String || item.isEmpty)) {
      throw const FavoritesReadException(FavoritesFailureKind.invalidData);
    }
    return value.isEmpty ? null : value.first as String;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    return null;
  }

  double? _asDouble(Object? value) {
    if (value is! num) {
      return null;
    }
    final result = value.toDouble();
    return result.isFinite ? result : null;
  }
}
