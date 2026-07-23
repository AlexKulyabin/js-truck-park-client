import 'parking_details.dart';

enum ParkingDetailsFailureKind { unavailable, invalidData }

class ParkingDetailsReadException implements Exception {
  const ParkingDetailsReadException(this.kind);

  final ParkingDetailsFailureKind kind;
}

abstract interface class ParkingDetailsRepository {
  Future<ParkingDetails?> fetchDetails(String parkingId);

  Future<List<ParkingReview>> fetchReviews(String parkingId);
}
