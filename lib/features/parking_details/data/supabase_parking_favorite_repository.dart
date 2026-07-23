import '../../../auth/supabase_auth/auth_util.dart';
import '../../../backend/supabase/supabase.dart';
import '../domain/parking_favorite_repository.dart';

typedef AuthenticatedUserIdProvider = String Function();

abstract interface class ParkingFavoriteDataSource {
  Future<void> insert({
    required String userId,
    required String parkingId,
  });

  Future<void> delete({
    required String userId,
    required String parkingId,
  });
}

class GeneratedSupabaseParkingFavoriteDataSource
    implements ParkingFavoriteDataSource {
  @override
  Future<void> insert({
    required String userId,
    required String parkingId,
  }) async {
    await FavoritesTable().insert({
      'user_id': userId,
      'parking_id': parkingId,
    });
  }

  @override
  Future<void> delete({
    required String userId,
    required String parkingId,
  }) async {
    await FavoritesTable().delete(
      matchingRows: (rows) =>
          rows.eq('parking_id', parkingId).eq('user_id', userId),
    );
  }
}

class SupabaseParkingFavoriteRepository implements ParkingFavoriteRepository {
  SupabaseParkingFavoriteRepository({
    ParkingFavoriteDataSource? dataSource,
    AuthenticatedUserIdProvider? userIdProvider,
  })  : _dataSource =
            dataSource ?? GeneratedSupabaseParkingFavoriteDataSource(),
        _userIdProvider = userIdProvider ?? _currentUserId;

  final ParkingFavoriteDataSource _dataSource;
  final AuthenticatedUserIdProvider _userIdProvider;

  @override
  Future<void> setFavorite({
    required String parkingId,
    required bool isFavorite,
  }) async {
    if (parkingId.isEmpty) {
      throw const ParkingFavoriteMutationException(
        ParkingFavoriteFailureKind.invalidInput,
      );
    }

    final userId = _userIdProvider();
    if (userId.isEmpty) {
      throw const ParkingFavoriteMutationException(
        ParkingFavoriteFailureKind.unauthenticated,
      );
    }

    try {
      if (isFavorite) {
        await _dataSource.insert(userId: userId, parkingId: parkingId);
      } else {
        await _dataSource.delete(userId: userId, parkingId: parkingId);
      }
    } on PostgrestException catch (error) {
      if (isFavorite && error.code == '23505') {
        return;
      }
      if (error.code == '42501') {
        throw const ParkingFavoriteMutationException(
          ParkingFavoriteFailureKind.forbidden,
        );
      }
      throw const ParkingFavoriteMutationException(
        ParkingFavoriteFailureKind.unavailable,
      );
    } on ParkingFavoriteMutationException {
      rethrow;
    } catch (_) {
      throw const ParkingFavoriteMutationException(
        ParkingFavoriteFailureKind.unavailable,
      );
    }
  }
}

String _currentUserId() => currentUserUid;
