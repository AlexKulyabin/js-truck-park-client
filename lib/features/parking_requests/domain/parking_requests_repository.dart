import 'parking_request_summary.dart';

enum ParkingRequestsFailureKind {
  unavailable,
  invalidData,
}

class ParkingRequestsReadException implements Exception {
  const ParkingRequestsReadException(this.kind);

  final ParkingRequestsFailureKind kind;
}

abstract interface class ParkingRequestsRepository {
  Future<List<ParkingRequestSummary>> fetchOwnedRequests({
    required String userId,
    required ParkingRequestStatus status,
  });
}
