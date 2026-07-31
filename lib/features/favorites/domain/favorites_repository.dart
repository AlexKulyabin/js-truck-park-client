import 'favorite_parking_summary.dart';

enum FavoritesFailureKind { unavailable, invalidData }

class FavoritesReadException implements Exception {
  const FavoritesReadException(this.kind);

  final FavoritesFailureKind kind;
}

abstract interface class FavoritesRepository {
  Future<List<FavoriteParkingSummary>> fetchOwnedFavorites(String userId);
}
