import '/backend/supabase/database/database.dart';
import '/backend/supabase/storage/storage.dart';
import '/core/config/app_config.dart';

class ReviewMutationException implements Exception {
  const ReviewMutationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UpdateReviewRequest {
  const UpdateReviewRequest({
    required this.reviewId,
    required this.userId,
    required this.comment,
    required this.ratingImpression,
    required this.ratingArrival,
    required this.ratingSecurity,
    required this.ratingInfrastructure,
    required this.ratingComfort,
  });

  final int? reviewId;
  final String userId;
  final String comment;
  final int ratingImpression;
  final int ratingArrival;
  final int ratingSecurity;
  final int ratingInfrastructure;
  final int ratingComfort;
}

class DeleteReviewRequest {
  const DeleteReviewRequest({
    required this.reviewId,
    required this.userId,
  });

  final int? reviewId;
  final String userId;
}

class UpdatedReview {
  const UpdatedReview({
    required this.id,
    required this.comment,
    required this.ratingImpression,
    required this.ratingArrival,
    required this.ratingSecurity,
    required this.ratingInfrastructure,
    required this.ratingComfort,
    required this.averageScore,
  });

  factory UpdatedReview.fromRow(ReviewsRow row) {
    return UpdatedReview(
      id: row.id,
      comment: row.comment,
      ratingImpression: row.ratingImpression,
      ratingArrival: row.ratingArrival,
      ratingSecurity: row.ratingSecurity,
      ratingInfrastructure: row.ratingInfrastructure,
      ratingComfort: row.ratingComfort,
      averageScore: row.averageScore,
    );
  }

  final int id;
  final String? comment;
  final int ratingImpression;
  final int ratingArrival;
  final int ratingSecurity;
  final int ratingInfrastructure;
  final int ratingComfort;
  final double? averageScore;
}

class DeletedReview {
  const DeletedReview({
    required this.id,
    required this.deletedStorageObjectCount,
    required this.storageCleanupFailedCount,
  });

  final int id;
  final int deletedStorageObjectCount;
  final int storageCleanupFailedCount;
}

typedef PublicUrlDelete = Future<void> Function(String publicUrl);

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

  Future<UpdatedReview> updateReview({
    required UpdateReviewRequest request,
  });

  Future<DeletedReview> deleteReview({
    required DeleteReviewRequest request,
  });
}

class SupabaseReviewsGateway implements ReviewsGateway {
  SupabaseReviewsGateway({
    ReviewsTable? reviewsTable,
    ViewReviewsWithUsersTable? reviewsView,
    ParkingPhotosTable? parkingPhotosTable,
    PublicUrlDelete? deletePublicUrl,
  })  : _reviewsTable = reviewsTable ?? ReviewsTable(),
        _reviewsView = reviewsView ?? ViewReviewsWithUsersTable(),
        _parkingPhotosTable = parkingPhotosTable ?? ParkingPhotosTable(),
        _deletePublicUrl = deletePublicUrl ?? deleteSupabaseFileFromPublicUrl;

  final ReviewsTable _reviewsTable;
  final ViewReviewsWithUsersTable _reviewsView;
  final ParkingPhotosTable _parkingPhotosTable;
  final PublicUrlDelete _deletePublicUrl;

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

  @override
  Future<UpdatedReview> updateReview({
    required UpdateReviewRequest request,
  }) async {
    final rows = await _reviewsTable.update(
      data: {
        'comment': request.comment,
        'rating_impression': request.ratingImpression,
        'rating_arrival': request.ratingArrival,
        'rating_security': request.ratingSecurity,
        'rating_infrastructure': request.ratingInfrastructure,
        'rating_comfort': request.ratingComfort,
      },
      matchingRows: (q) => q
          .eqOrNull(
            'id',
            request.reviewId,
          )
          .eqOrNull(
            'user_id',
            request.userId,
          ),
      returnRows: true,
    );
    if (rows.isEmpty) {
      throw const ReviewMutationException('Review was not updated.');
    }
    return UpdatedReview.fromRow(rows.first);
  }

  @override
  Future<DeletedReview> deleteReview({
    required DeleteReviewRequest request,
  }) async {
    final photoRows = await _parkingPhotosTable.queryRows(
      queryFn: (q) => q
          .eqOrNull(
            'review_id',
            request.reviewId,
          )
          .eqOrNull(
            'user_id',
            request.userId,
          ),
    );
    final photoUrls = photoRows.map((photo) => photo.url).toList();
    final deletedRows = await _reviewsTable.delete(
      matchingRows: (q) => q
          .eqOrNull(
            'id',
            request.reviewId,
          )
          .eqOrNull(
            'user_id',
            request.userId,
          ),
      returnRows: true,
    );
    if (deletedRows.isEmpty) {
      throw const ReviewMutationException('Review was not deleted.');
    }

    var deletedStorageObjectCount = 0;
    var storageCleanupFailedCount = 0;
    for (final photoUrl in photoUrls) {
      try {
        await _deletePublicUrl(photoUrl);
        deletedStorageObjectCount += 1;
      } catch (_) {
        storageCleanupFailedCount += 1;
      }
    }

    return DeletedReview(
      id: deletedRows.first.id,
      deletedStorageObjectCount: deletedStorageObjectCount,
      storageCleanupFailedCount: storageCleanupFailedCount,
    );
  }
}

class ReviewsService {
  ReviewsService({
    ReviewsGateway? gateway,
    AppConfig? config,
  })  : _gateway = gateway ?? SupabaseReviewsGateway(),
        _config = config ?? AppConfig.current;

  final ReviewsGateway _gateway;
  final AppConfig _config;

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

  Future<UpdatedReview> updateReview(UpdateReviewRequest request) async {
    if (!_config.canPerformWrite(AppWriteOperation.reviewUpdate)) {
      throw const ReviewMutationException(
        'Review updates are disabled for this build.',
      );
    }

    final normalizedReviewId = request.reviewId;
    final normalizedUserId = request.userId.trim();
    if (normalizedReviewId == null ||
        normalizedReviewId <= 0 ||
        normalizedUserId.isEmpty) {
      throw const ReviewMutationException(
        'Sign in again before updating a review.',
      );
    }

    final ratings = [
      request.ratingImpression,
      request.ratingArrival,
      request.ratingSecurity,
      request.ratingInfrastructure,
      request.ratingComfort,
    ];
    if (ratings.any((rating) => rating < 0 || rating > 5)) {
      throw const ReviewMutationException(
        'Review ratings must be between 0 and 5.',
      );
    }

    if (request.comment.isEmpty && ratings.every((rating) => rating == 0)) {
      throw const ReviewMutationException(
        'Add a comment or rating before updating a review.',
      );
    }

    return _gateway.updateReview(
      request: UpdateReviewRequest(
        reviewId: normalizedReviewId,
        userId: normalizedUserId,
        comment: request.comment,
        ratingImpression: request.ratingImpression,
        ratingArrival: request.ratingArrival,
        ratingSecurity: request.ratingSecurity,
        ratingInfrastructure: request.ratingInfrastructure,
        ratingComfort: request.ratingComfort,
      ),
    );
  }

  Future<DeletedReview> deleteReview(DeleteReviewRequest request) async {
    if (!_config.canPerformWrite(AppWriteOperation.reviewDelete)) {
      throw const ReviewMutationException(
        'Review deletion is disabled for this build.',
      );
    }

    final normalizedReviewId = request.reviewId;
    final normalizedUserId = request.userId.trim();
    if (normalizedReviewId == null ||
        normalizedReviewId <= 0 ||
        normalizedUserId.isEmpty) {
      throw const ReviewMutationException(
        'Sign in again before deleting a review.',
      );
    }

    return _gateway.deleteReview(
      request: DeleteReviewRequest(
        reviewId: normalizedReviewId,
        userId: normalizedUserId,
      ),
    );
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
