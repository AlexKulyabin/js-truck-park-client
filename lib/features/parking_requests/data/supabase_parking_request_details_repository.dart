import '../../../backend/supabase/supabase.dart';
import '../domain/parking_request_details.dart';
import '../domain/parking_request_details_repository.dart';
import '../domain/parking_requests_repository.dart';

abstract interface class ParkingRequestDetailsDataSource {
  Future<List<Map<String, dynamic>>> fetchPhotoRows(String parkingId);

  Future<int> fetchReviewCount(String parkingId);
}

class GeneratedParkingRequestDetailsDataSource
    implements ParkingRequestDetailsDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchPhotoRows(String parkingId) async {
    final rows = await ParkingPhotosTable().queryRows(
      queryFn: (query) => query.eq('parking_id', parkingId).order('created_at'),
    );
    return rows
        .map((row) => Map<String, dynamic>.unmodifiable(row.data))
        .toList(growable: false);
  }

  @override
  Future<int> fetchReviewCount(String parkingId) async {
    final rows = await ReviewsTable().queryRows(
      queryFn: (query) => query.eq('parking_id', parkingId),
    );
    return rows.length;
  }
}

class SupabaseParkingRequestDetailsRepository
    implements ParkingRequestDetailsRepository {
  SupabaseParkingRequestDetailsRepository({
    ParkingRequestDetailsDataSource? dataSource,
  }) : _dataSource = dataSource ?? GeneratedParkingRequestDetailsDataSource();

  final ParkingRequestDetailsDataSource _dataSource;

  @override
  Future<List<ParkingRequestPhoto>> fetchPhotos(String parkingId) async {
    if (parkingId.isEmpty) {
      return const [];
    }

    try {
      final rows = await _dataSource.fetchPhotoRows(parkingId);
      return rows.map(_mapPhoto).toList(growable: false);
    } on ParkingRequestsReadException {
      rethrow;
    } catch (_) {
      throw const ParkingRequestsReadException(
        ParkingRequestsFailureKind.unavailable,
      );
    }
  }

  @override
  Future<int> fetchReviewCount(String parkingId) async {
    if (parkingId.isEmpty) {
      return 0;
    }

    try {
      final count = await _dataSource.fetchReviewCount(parkingId);
      if (count < 0) {
        throw const ParkingRequestsReadException(
          ParkingRequestsFailureKind.invalidData,
        );
      }
      return count;
    } on ParkingRequestsReadException {
      rethrow;
    } catch (_) {
      throw const ParkingRequestsReadException(
        ParkingRequestsFailureKind.unavailable,
      );
    }
  }

  ParkingRequestPhoto _mapPhoto(Map<String, dynamic> row) {
    final id = row['id'];
    final url = row['url'];
    if (id is! String || id.isEmpty || url is! String || url.isEmpty) {
      throw const ParkingRequestsReadException(
        ParkingRequestsFailureKind.invalidData,
      );
    }
    return ParkingRequestPhoto(id: id, url: url);
  }
}
