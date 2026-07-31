import '../../../backend/supabase/supabase.dart';
import '../domain/parking_details.dart';
import '../domain/parking_details_repository.dart';

abstract interface class ParkingDetailsDataSource {
  Future<List<Map<String, dynamic>>> fetchDetailsRows(String parkingId);

  Future<List<Map<String, dynamic>>> fetchReviewRows(String parkingId);
}

class GeneratedParkingDetailsDataSource implements ParkingDetailsDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchDetailsRows(String parkingId) async {
    final rows = await ViewFullParkingDetailsTable().queryRows(
      queryFn: (query) => query.eq('id', parkingId),
      limit: 1,
    );
    return rows
        .map((row) => Map<String, dynamic>.unmodifiable(row.data))
        .toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReviewRows(String parkingId) async {
    final rows = await ViewReviewsWithUsersTable().queryRows(
      queryFn: (query) => query.eq('parking_id', parkingId).order('created_at'),
    );
    return rows
        .map((row) => Map<String, dynamic>.unmodifiable(row.data))
        .toList(growable: false);
  }
}

class SupabaseParkingDetailsRepository implements ParkingDetailsRepository {
  SupabaseParkingDetailsRepository({ParkingDetailsDataSource? dataSource})
      : _dataSource = dataSource ?? GeneratedParkingDetailsDataSource();

  final ParkingDetailsDataSource _dataSource;

  @override
  Future<ParkingDetails?> fetchDetails(String parkingId) async {
    if (parkingId.isEmpty) {
      return null;
    }

    try {
      final rows = await _dataSource.fetchDetailsRows(parkingId);
      if (rows.isEmpty) {
        return null;
      }
      return _mapDetails(rows.first, expectedParkingId: parkingId);
    } on ParkingDetailsReadException {
      rethrow;
    } catch (_) {
      throw const ParkingDetailsReadException(
        ParkingDetailsFailureKind.unavailable,
      );
    }
  }

  @override
  Future<List<ParkingReview>> fetchReviews(String parkingId) async {
    if (parkingId.isEmpty) {
      return const [];
    }

    try {
      final rows = await _dataSource.fetchReviewRows(parkingId);
      return rows
          .map((row) => _mapReview(row, expectedParkingId: parkingId))
          .toList(growable: false);
    } on ParkingDetailsReadException {
      rethrow;
    } catch (_) {
      throw const ParkingDetailsReadException(
        ParkingDetailsFailureKind.unavailable,
      );
    }
  }

  ParkingDetails _mapDetails(
    Map<String, dynamic> row, {
    required String expectedParkingId,
  }) {
    final id = row['id'];
    if (id is! String || id.isEmpty || id != expectedParkingId) {
      throw const ParkingDetailsReadException(
        ParkingDetailsFailureKind.invalidData,
      );
    }

    return ParkingDetails(
      id: id,
      isFavorited: row['is_favorited'] == true,
      address: row['address'] as String?,
      latitude: _asDouble(row['latitude']),
      longitude: _asDouble(row['longitude']),
      totalSpaces: _asInt(row['total_spaces']),
      rating: _asDouble(row['rating']),
      stars1: _asInt(row['stars_1']),
      stars2: _asInt(row['stars_2']),
      stars3: _asInt(row['stars_3']),
      stars4: _asInt(row['stars_4']),
      stars5: _asInt(row['stars_5']),
      reviewsCount: _asInt(row['reviews_count']),
      photosCount: _asInt(row['photos_count']),
      photos: _mapPhotos(row['all_photos']),
      hasGasStation: _asBool(row['has_gas_station']),
      hasShower: _asBool(row['has_shower']),
      hasLaundry: _asBool(row['has_laundry']),
      hasHotel: _asBool(row['has_hotel']),
      hasShop: _asBool(row['has_shop']),
      hasRecreationArea: _asBool(row['has_recreation_area']),
    );
  }

  ParkingReview _mapReview(
    Map<String, dynamic> row, {
    required String expectedParkingId,
  }) {
    final id = _asInt(row['id']);
    final parkingId = row['parking_id'];
    if (id == null ||
        parkingId is! String ||
        parkingId.isEmpty ||
        parkingId != expectedParkingId) {
      throw const ParkingDetailsReadException(
        ParkingDetailsFailureKind.invalidData,
      );
    }

    return ParkingReview(
      id: id,
      parkingId: parkingId,
      createdAt: _asDateTime(row['created_at']),
      userId: row['user_id'] as String?,
      comment: row['comment'] as String?,
      averageScore: _asDouble(row['average_score']),
      authorName: row['author_name'] as String?,
      authorAvatar: row['author_avatar'] as String?,
      reviewPhotos: _mapReviewPhotos(row['review_photos']),
    );
  }

  List<ParkingDetailsPhoto>? _mapPhotos(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! List) {
      throw const ParkingDetailsReadException(
        ParkingDetailsFailureKind.invalidData,
      );
    }
    return List.unmodifiable(value.map((item) {
      if (item is! Map) {
        throw const ParkingDetailsReadException(
          ParkingDetailsFailureKind.invalidData,
        );
      }
      final url = item['url'];
      if (url is! String || url.isEmpty) {
        throw const ParkingDetailsReadException(
          ParkingDetailsFailureKind.invalidData,
        );
      }
      final photoDate = item['photo_date'];
      return ParkingDetailsPhoto(
        url: url,
        photoDate: photoDate is String ? photoDate : null,
      );
    }));
  }

  List<String>? _mapReviewPhotos(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! List || value.any((item) => item is! String)) {
      throw const ParkingDetailsReadException(
        ParkingDetailsFailureKind.invalidData,
      );
    }
    return List<String>.unmodifiable(value.cast<String>());
  }

  int? _asInt(Object? value) => value is num ? value.round() : null;

  double? _asDouble(Object? value) => value is num ? value.toDouble() : null;

  bool? _asBool(Object? value) => value is bool ? value : null;

  DateTime? _asDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
