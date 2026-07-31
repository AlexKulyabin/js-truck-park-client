enum ParkingFavoriteFailureKind {
  unauthenticated,
  forbidden,
  invalidInput,
  unavailable,
}

class ParkingFavoriteMutationException implements Exception {
  const ParkingFavoriteMutationException(this.kind);

  final ParkingFavoriteFailureKind kind;
}

abstract interface class ParkingFavoriteRepository {
  Future<void> setFavorite({
    required String parkingId,
    required bool isFavorite,
  });
}
