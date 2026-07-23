import 'parking_request_details.dart';

abstract interface class ParkingRequestDetailsRepository {
  Future<List<ParkingRequestPhoto>> fetchPhotos(String parkingId);

  Future<int> fetchReviewCount(String parkingId);
}
