import '/backend/supabase/database/database.dart';

abstract interface class ReviewsGateway {
  Future<int> countParkingReviews({
    required String parkingId,
  });

  Future<List<ParkingReview>> listParkingReviews({
    required String parkingId,
  });

  Future<List<ParkingReview>> listUserReviews({
    required String userId,
  });
}

class SupabaseReviewsGateway implements ReviewsGateway {
  SupabaseReviewsGateway({
    ReviewsTable? reviewsTable,
    ViewReviewsWithUsersTable? reviewsView,
  })  : _reviewsTable = reviewsTable ?? ReviewsTable(),
        _reviewsView = reviewsView ?? ViewReviewsWithUsersTable();

  final ReviewsTable _reviewsTable;
  final ViewReviewsWithUsersTable _reviewsView;

  @override
  Future<int> countParkingReviews({
    required String parkingId,
  }) async {
    final rows = await _reviewsTable.queryRows(
      queryFn: (q) => q.eqOrNull(
        'parking_id',
        parkingId,
      ),
    );
    return rows.length;
  }

  @override
  Future<List<ParkingReview>> listParkingReviews({
    required String parkingId,
  }) async {
    final rows = await _reviewsView.queryRows(
      queryFn: (q) => q
          .eqOrNull(
            'parking_id',
            parkingId,
          )
          .order('created_at'),
    );
    return rows.map(ParkingReview.fromRow).toList();
  }

  @override
  Future<List<ParkingReview>> listUserReviews({
    required String userId,
  }) async {
    final rows = await _reviewsView.queryRows(
      queryFn: (q) => q
          .eqOrNull(
            'user_id',
            userId,
          )
          .order('created_at'),
    );
    return rows.map(ParkingReview.fromRow).toList();
  }
}

class ReviewsService {
  ReviewsService({
    ReviewsGateway? gateway,
  }) : _gateway = gateway ?? SupabaseReviewsGateway();

  final ReviewsGateway _gateway;

  Future<int> countParkingReviews({
    required String? parkingId,
  }) async {
    final normalizedParkingId = parkingId?.trim();
    if (normalizedParkingId == null || normalizedParkingId.isEmpty) {
      return 0;
    }

    return _gateway.countParkingReviews(parkingId: normalizedParkingId);
  }

  Future<List<ParkingReview>> listParkingReviews({
    required String? parkingId,
  }) async {
    final normalizedParkingId = parkingId?.trim();
    if (normalizedParkingId == null || normalizedParkingId.isEmpty) {
      return const [];
    }

    return _gateway.listParkingReviews(parkingId: normalizedParkingId);
  }

  Future<List<ParkingReview>> listUserReviews({
    required String? userId,
  }) async {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      return const [];
    }

    return _gateway.listUserReviews(userId: normalizedUserId);
  }
}

class ParkingReview {
  const ParkingReview({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.parkingId,
    required this.comment,
    required this.ratingImpression,
    required this.ratingArrival,
    required this.ratingSecurity,
    required this.ratingInfrastructure,
    required this.ratingComfort,
    required this.averageScore,
    required this.parkingAddress,
    required this.authorName,
    required this.authorAvatar,
    required this.photoUrls,
    required this.hasPhotoPayload,
  });

  factory ParkingReview.fromRow(ViewReviewsWithUsersRow row) {
    return ParkingReview(
      id: row.id,
      createdAt: row.createdAt,
      userId: row.userId,
      parkingId: row.parkingId,
      comment: row.comment,
      ratingImpression: row.ratingImpression,
      ratingArrival: row.ratingArrival,
      ratingSecurity: row.ratingSecurity,
      ratingInfrastructure: row.ratingInfrastructure,
      ratingComfort: row.ratingComfort,
      averageScore: row.averageScore,
      parkingAddress: row.parkingAddress,
      authorName: row.authorName,
      authorAvatar: row.authorAvatar,
      photoUrls: _parsePhotoUrls(row.reviewPhotos),
      hasPhotoPayload: row.reviewPhotos != null,
    );
  }

  final int? id;
  final DateTime? createdAt;
  final String? userId;
  final String? parkingId;
  final String? comment;
  final int? ratingImpression;
  final int? ratingArrival;
  final int? ratingSecurity;
  final int? ratingInfrastructure;
  final int? ratingComfort;
  final double? averageScore;
  final String? parkingAddress;
  final String? authorName;
  final String? authorAvatar;
  final List<String> photoUrls;
  final bool hasPhotoPayload;
}

List<String> _parsePhotoUrls(dynamic photos) {
  if (photos is! Iterable) {
    return const [];
  }

  return photos.whereType<String>().toList(growable: false);
}
