class FavoriteParkingSummary {
  const FavoriteParkingSummary({
    required this.favoriteRecordId,
    required this.parkingId,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.thumbnailUrl,
  });

  final int favoriteRecordId;
  final String parkingId;
  final String address;
  final double latitude;
  final double longitude;
  final String? thumbnailUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteParkingSummary &&
          favoriteRecordId == other.favoriteRecordId &&
          parkingId == other.parkingId &&
          address == other.address &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          thumbnailUrl == other.thumbnailUrl;

  @override
  int get hashCode => Object.hash(
        favoriteRecordId,
        parkingId,
        address,
        latitude,
        longitude,
        thumbnailUrl,
      );
}
