import 'package:flutter/foundation.dart';

@immutable
class UserReviewSummary {
  const UserReviewSummary({
    required this.id,
    required this.parkingAddress,
    required this.createdAt,
    required this.averageScore,
    required this.comment,
    required this.authorAvatarUrl,
    required this.photoUrls,
  });

  final int id;
  final String parkingAddress;
  final DateTime? createdAt;
  final double averageScore;
  final String comment;
  final String? authorAvatarUrl;
  final List<String> photoUrls;

  @override
  bool operator ==(Object other) {
    return other is UserReviewSummary &&
        other.id == id &&
        other.parkingAddress == parkingAddress &&
        other.createdAt == createdAt &&
        other.averageScore == averageScore &&
        other.comment == comment &&
        other.authorAvatarUrl == authorAvatarUrl &&
        listEquals(other.photoUrls, photoUrls);
  }

  @override
  int get hashCode => Object.hash(
        id,
        parkingAddress,
        createdAt,
        averageScore,
        comment,
        authorAvatarUrl,
        Object.hashAll(photoUrls),
      );
}
