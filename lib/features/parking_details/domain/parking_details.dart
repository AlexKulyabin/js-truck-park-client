class ParkingDetailsPhoto {
  const ParkingDetailsPhoto({
    required this.url,
    this.photoDate,
  });

  final String url;
  final String? photoDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingDetailsPhoto &&
          url == other.url &&
          photoDate == other.photoDate;

  @override
  int get hashCode => Object.hash(url, photoDate);
}

class ParkingDetails {
  const ParkingDetails({
    required this.id,
    required this.isFavorited,
    this.address,
    this.latitude,
    this.longitude,
    this.totalSpaces,
    this.rating,
    this.stars1,
    this.stars2,
    this.stars3,
    this.stars4,
    this.stars5,
    this.reviewsCount,
    this.photosCount,
    this.photos,
    this.hasGasStation,
    this.hasShower,
    this.hasLaundry,
    this.hasHotel,
    this.hasShop,
    this.hasRecreationArea,
  });

  final String id;
  final bool isFavorited;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? totalSpaces;
  final double? rating;
  final int? stars1;
  final int? stars2;
  final int? stars3;
  final int? stars4;
  final int? stars5;
  final int? reviewsCount;
  final int? photosCount;
  final List<ParkingDetailsPhoto>? photos;
  final bool? hasGasStation;
  final bool? hasShower;
  final bool? hasLaundry;
  final bool? hasHotel;
  final bool? hasShop;
  final bool? hasRecreationArea;
}

class ParkingReview {
  const ParkingReview({
    required this.id,
    required this.parkingId,
    this.createdAt,
    this.userId,
    this.comment,
    this.averageScore,
    this.authorName,
    this.authorAvatar,
    this.reviewPhotos,
  });

  final int id;
  final String parkingId;
  final DateTime? createdAt;
  final String? userId;
  final String? comment;
  final double? averageScore;
  final String? authorName;
  final String? authorAvatar;
  final List<String>? reviewPhotos;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingReview &&
          id == other.id &&
          parkingId == other.parkingId &&
          createdAt == other.createdAt &&
          userId == other.userId &&
          comment == other.comment &&
          averageScore == other.averageScore &&
          authorName == other.authorName &&
          authorAvatar == other.authorAvatar &&
          _listsEqual(reviewPhotos, other.reviewPhotos);

  @override
  int get hashCode => Object.hash(
        id,
        parkingId,
        createdAt,
        userId,
        comment,
        averageScore,
        authorName,
        authorAvatar,
        Object.hashAll(reviewPhotos ?? const []),
      );
}

bool _listsEqual<T>(List<T>? left, List<T>? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
