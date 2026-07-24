import 'package:flutter/foundation.dart';

@immutable
class UserComplaintSummary {
  const UserComplaintSummary({
    required this.id,
    required this.parkingAddress,
    required this.reportDate,
    required this.reportType,
    required this.comment,
    required this.parkingPhotoUrls,
    required this.photosCount,
  });

  final int id;
  final String parkingAddress;
  final DateTime? reportDate;
  final String? reportType;
  final String comment;
  final List<String> parkingPhotoUrls;
  final int? photosCount;

  String? get firstParkingPhotoUrl =>
      parkingPhotoUrls.isEmpty ? null : parkingPhotoUrls.first;

  @override
  bool operator ==(Object other) {
    return other is UserComplaintSummary &&
        other.id == id &&
        other.parkingAddress == parkingAddress &&
        other.reportDate == reportDate &&
        other.reportType == reportType &&
        other.comment == comment &&
        listEquals(other.parkingPhotoUrls, parkingPhotoUrls) &&
        other.photosCount == photosCount;
  }

  @override
  int get hashCode => Object.hash(
        id,
        parkingAddress,
        reportDate,
        reportType,
        comment,
        Object.hashAll(parkingPhotoUrls),
        photosCount,
      );
}
