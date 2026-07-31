import '../../../backend/supabase/supabase.dart';
import '../domain/parking_request_summary.dart';
import '../domain/parking_requests_repository.dart';

abstract interface class ParkingRequestsDataSource {
  Future<List<Map<String, dynamic>>> fetchOwnedRows({
    required String userId,
    required String status,
  });
}

class GeneratedParkingRequestsDataSource implements ParkingRequestsDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchOwnedRows({
    required String userId,
    required String status,
  }) async {
    final rows = await ParkingsTable().queryRows(
      queryFn: (query) =>
          query.eqOrNull('created_by', userId).eqOrNull('status', status),
    );

    return rows
        .map((row) => Map<String, dynamic>.unmodifiable(row.data))
        .toList(growable: false);
  }
}

class SupabaseParkingRequestsRepository implements ParkingRequestsRepository {
  SupabaseParkingRequestsRepository({ParkingRequestsDataSource? dataSource})
      : _dataSource = dataSource ?? GeneratedParkingRequestsDataSource();

  final ParkingRequestsDataSource _dataSource;

  @override
  Future<List<ParkingRequestSummary>> fetchOwnedRequests({
    required String userId,
    required ParkingRequestStatus status,
  }) async {
    if (userId.isEmpty) {
      return const [];
    }

    try {
      final rows = await _dataSource.fetchOwnedRows(
        userId: userId,
        status: status.storageValue,
      );
      return rows
          .map((row) => _mapRow(row, expectedStatus: status))
          .toList(growable: false);
    } on ParkingRequestsReadException {
      rethrow;
    } catch (_) {
      throw const ParkingRequestsReadException(
        ParkingRequestsFailureKind.unavailable,
      );
    }
  }

  ParkingRequestSummary _mapRow(
    Map<String, dynamic> row, {
    required ParkingRequestStatus expectedStatus,
  }) {
    final id = row['id'];
    final rawStatus = row['status'];
    final status = ParkingRequestStatus.tryParse(
      rawStatus is String ? rawStatus : null,
    );

    if (id is! String || id.isEmpty || status != expectedStatus) {
      throw const ParkingRequestsReadException(
        ParkingRequestsFailureKind.invalidData,
      );
    }

    return ParkingRequestSummary(
      id: id,
      status: status!,
      address: row['address'] as String?,
      totalSpaces: _asInt(row['total_spaces']),
      rating: _asDouble(row['rating']),
      hasGasStation: row['has_gas_station'] == true,
      hasShower: row['has_shower'] == true,
      hasLaundry: row['has_laundry'] == true,
      hasHotel: row['has_hotel'] == true,
      hasShop: row['has_shop'] == true,
      hasRecreationArea: row['has_recreation_area'] == true,
    );
  }

  int? _asInt(Object? value) => value is num ? value.round() : null;

  double? _asDouble(Object? value) => value is num ? value.toDouble() : null;
}
