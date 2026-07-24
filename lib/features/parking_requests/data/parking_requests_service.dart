import '/backend/schema/enums/enums.dart';
import '/backend/supabase/database/database.dart';

abstract interface class ParkingRequestsGateway {
  Future<List<ParkingsRow>> listUserRequests({
    required String userId,
    required StatusParking status,
  });
}

class SupabaseParkingRequestsGateway implements ParkingRequestsGateway {
  SupabaseParkingRequestsGateway({
    ParkingsTable? parkingsTable,
  }) : _parkingsTable = parkingsTable ?? ParkingsTable();

  final ParkingsTable _parkingsTable;

  @override
  Future<List<ParkingsRow>> listUserRequests({
    required String userId,
    required StatusParking status,
  }) {
    return _parkingsTable.queryRows(
      queryFn: (q) => q
          .eqOrNull(
            'created_by',
            userId,
          )
          .eqOrNull(
            'status',
            status.name,
          ),
    );
  }
}

class ParkingRequestsService {
  ParkingRequestsService({
    ParkingRequestsGateway? gateway,
  }) : _gateway = gateway ?? SupabaseParkingRequestsGateway();

  final ParkingRequestsGateway _gateway;

  Future<List<ParkingsRow>> listUserRequests({
    required String? userId,
    required StatusParking status,
  }) {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      return Future.value(const []);
    }

    return _gateway.listUserRequests(
      userId: normalizedUserId,
      status: status,
    );
  }
}
