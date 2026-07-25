import '/backend/supabase/database/database.dart';

abstract interface class ParkingPhotosGateway {
  Future<List<ParkingPhoto>> listParkingPhotos({
    required String parkingId,
    required bool orderByCreatedAt,
  });
}

class SupabaseParkingPhotosGateway implements ParkingPhotosGateway {
  SupabaseParkingPhotosGateway({
    ParkingPhotosTable? table,
  }) : _table = table ?? ParkingPhotosTable();

  final ParkingPhotosTable _table;

  @override
  Future<List<ParkingPhoto>> listParkingPhotos({
    required String parkingId,
    required bool orderByCreatedAt,
  }) async {
    final rows = await _table.queryRows(
      queryFn: (q) {
        final filtered = q.eqOrNull(
          'parking_id',
          parkingId,
        );
        if (orderByCreatedAt) {
          return filtered.order('created_at');
        }
        return filtered;
      },
    );
    return rows.map(ParkingPhoto.fromRow).toList();
  }
}

class ParkingPhotosService {
  ParkingPhotosService({
    ParkingPhotosGateway? gateway,
  }) : _gateway = gateway ?? SupabaseParkingPhotosGateway();

  final ParkingPhotosGateway _gateway;

  Future<List<ParkingPhoto>> listParkingPhotos({
    required String? parkingId,
    bool orderByCreatedAt = false,
  }) async {
    final normalizedParkingId = parkingId?.trim();
    if (normalizedParkingId == null || normalizedParkingId.isEmpty) {
      return const [];
    }

    return _gateway.listParkingPhotos(
      parkingId: normalizedParkingId,
      orderByCreatedAt: orderByCreatedAt,
    );
  }
}

class ParkingPhoto {
  const ParkingPhoto({
    required this.id,
    required this.createdAt,
    required this.url,
    required this.parkingId,
    required this.userId,
    required this.reviewId,
  });

  factory ParkingPhoto.fromRow(ParkingPhotosRow row) {
    return ParkingPhoto(
      id: row.id,
      createdAt: row.createdAt,
      url: row.url,
      parkingId: row.parkingId,
      userId: row.userId,
      reviewId: row.reviewId,
    );
  }

  final String? id;
  final DateTime? createdAt;
  final String url;
  final String parkingId;
  final String? userId;
  final int? reviewId;
}
