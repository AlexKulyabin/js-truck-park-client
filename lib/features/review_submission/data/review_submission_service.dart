import '/core/config/app_config.dart';
import '/backend/supabase/database/database.dart';

enum ReviewSubmissionFailure {
  disabled,
  invalidIdentity,
  emptyContent,
  invalidRating,
  invalidPhoto,
}

class ReviewSubmissionException implements Exception {
  const ReviewSubmissionException({
    required this.failure,
    required this.message,
  });

  final ReviewSubmissionFailure failure;
  final String message;

  @override
  String toString() => message;
}

class ReviewSubmissionCommand {
  const ReviewSubmissionCommand({
    required this.parkingId,
    required this.userId,
    required this.comment,
    required this.ratingImpression,
    required this.ratingArrival,
    required this.ratingSecurity,
    required this.ratingInfrastructure,
    required this.ratingComfort,
    required this.createdAt,
    this.photos = const [],
  });

  final String? parkingId;
  final String userId;
  final String comment;
  final int ratingImpression;
  final int ratingArrival;
  final int ratingSecurity;
  final int ratingInfrastructure;
  final int ratingComfort;
  final DateTime createdAt;
  final List<ReviewPhotoDraft> photos;
}

class ReviewPhotoDraft {
  const ReviewPhotoDraft({
    required this.fileName,
    required this.byteLength,
    this.mimeType,
  });

  final String fileName;
  final int byteLength;
  final String? mimeType;
}

class PreparedReviewSubmission {
  const PreparedReviewSubmission({
    required this.parkingId,
    required this.userId,
    required this.comment,
    required this.ratingImpression,
    required this.ratingArrival,
    required this.ratingSecurity,
    required this.ratingInfrastructure,
    required this.ratingComfort,
    required this.createdAt,
    required this.photos,
  });

  final String parkingId;
  final String userId;
  final String comment;
  final int ratingImpression;
  final int ratingArrival;
  final int ratingSecurity;
  final int ratingInfrastructure;
  final int ratingComfort;
  final DateTime createdAt;
  final List<ReviewPhotoDraft> photos;

  bool get requiresAtomicPhotoHandling => photos.isNotEmpty;
}

class ReviewSubmissionResult {
  const ReviewSubmissionResult({
    required this.reviewId,
    required this.createdPhotoCount,
  });

  final int reviewId;
  final int createdPhotoCount;
}

abstract interface class ReviewSubmissionGateway {
  // Implementations must commit the review, objects and photo rows as one
  // server-owned operation, or compensate every completed step before failing.
  Future<ReviewSubmissionResult> submitAtomically({
    required PreparedReviewSubmission submission,
  });
}

class SupabaseReviewSubmissionGateway implements ReviewSubmissionGateway {
  SupabaseReviewSubmissionGateway({
    ReviewsTable? reviewsTable,
  }) : _reviewsTable = reviewsTable ?? ReviewsTable();

  final ReviewsTable _reviewsTable;

  @override
  Future<ReviewSubmissionResult> submitAtomically({
    required PreparedReviewSubmission submission,
  }) async {
    if (submission.requiresAtomicPhotoHandling) {
      throw const ReviewSubmissionException(
        failure: ReviewSubmissionFailure.invalidPhoto,
        message: 'Review photos are not enabled for this write path yet.',
      );
    }

    final row = await _reviewsTable.insert({
      'parking_id': submission.parkingId,
      'comment': submission.comment,
      'rating_impression': submission.ratingImpression,
      'rating_arrival': submission.ratingArrival,
      'rating_security': submission.ratingSecurity,
      'rating_infrastructure': submission.ratingInfrastructure,
      'rating_comfort': submission.ratingComfort,
      'created_at': supaSerialize<DateTime>(submission.createdAt),
      'user_id': submission.userId,
    });

    return ReviewSubmissionResult(
      reviewId: row.id,
      createdPhotoCount: 0,
    );
  }
}

class ReviewSubmissionService {
  ReviewSubmissionService({
    ReviewSubmissionGateway? gateway,
    AppConfig? config,
  })  : _gateway = gateway,
        _config = config ?? AppConfig.current;

  final ReviewSubmissionGateway? _gateway;
  final AppConfig _config;

  PreparedReviewSubmission prepare(ReviewSubmissionCommand command) {
    final parkingId = command.parkingId?.trim();
    final userId = command.userId.trim();
    if (parkingId == null || parkingId.isEmpty || userId.isEmpty) {
      throw const ReviewSubmissionException(
        failure: ReviewSubmissionFailure.invalidIdentity,
        message: 'Sign in again before creating a review.',
      );
    }

    final ratings = [
      command.ratingImpression,
      command.ratingArrival,
      command.ratingSecurity,
      command.ratingInfrastructure,
      command.ratingComfort,
    ];
    if (ratings.any((rating) => rating < 0 || rating > 5)) {
      throw const ReviewSubmissionException(
        failure: ReviewSubmissionFailure.invalidRating,
        message: 'Review ratings must be between 0 and 5.',
      );
    }

    final hasCurrentUiContent = command.comment.isNotEmpty ||
        command.ratingImpression > 0 ||
        command.ratingArrival > 0 ||
        command.ratingSecurity > 0 ||
        command.ratingInfrastructure > 0;
    if (!hasCurrentUiContent) {
      throw const ReviewSubmissionException(
        failure: ReviewSubmissionFailure.emptyContent,
        message: 'Add a comment or rating before creating a review.',
      );
    }

    if (command.photos.any(
      (photo) => photo.fileName.trim().isEmpty || photo.byteLength <= 0,
    )) {
      throw const ReviewSubmissionException(
        failure: ReviewSubmissionFailure.invalidPhoto,
        message: 'Every review photo must contain a file name and data.',
      );
    }

    return PreparedReviewSubmission(
      parkingId: parkingId,
      userId: userId,
      comment: command.comment,
      ratingImpression: command.ratingImpression,
      ratingArrival: command.ratingArrival,
      ratingSecurity: command.ratingSecurity,
      ratingInfrastructure: command.ratingInfrastructure,
      ratingComfort: command.ratingComfort,
      createdAt: command.createdAt,
      photos: List.unmodifiable(command.photos),
    );
  }

  Future<ReviewSubmissionResult> submit(
    ReviewSubmissionCommand command,
  ) async {
    if (!_config.canPerformWrite(AppWriteOperation.reviewCreate)) {
      throw const ReviewSubmissionException(
        failure: ReviewSubmissionFailure.disabled,
        message: 'Review creation is not enabled for this build.',
      );
    }

    final gateway = _gateway ?? SupabaseReviewSubmissionGateway();
    return gateway.submitAtomically(submission: prepare(command));
  }
}
