import 'dart:typed_data';

import '/backend/supabase/database/database.dart';
import '/backend/supabase/storage/storage.dart';
import '/core/config/app_config.dart';

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
    this.bytes,
    this.width,
    this.height,
  });

  final String fileName;
  final int byteLength;
  final String? mimeType;
  final Uint8List? bytes;
  final double? width;
  final double? height;
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

abstract interface class ReviewPhotoStorageGateway {
  Future<String> uploadReviewPhoto({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
  });

  Future<void> deletePublicUrl(String publicUrl);
}

class SupabaseReviewPhotoStorageGateway implements ReviewPhotoStorageGateway {
  const SupabaseReviewPhotoStorageGateway();

  @override
  Future<String> uploadReviewPhoto({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final bucket = SupaFlow.client.storage.from(_parkingContentBucket);
    await bucket.uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(contentType: mimeType),
    );
    return bucket.getPublicUrl(storagePath);
  }

  @override
  Future<void> deletePublicUrl(String publicUrl) {
    return deleteSupabaseFileFromPublicUrl(publicUrl);
  }
}

class SupabaseReviewSubmissionGateway implements ReviewSubmissionGateway {
  SupabaseReviewSubmissionGateway({
    ReviewsTable? reviewsTable,
    ParkingPhotosTable? parkingPhotosTable,
    ReviewPhotoStorageGateway? photoStorage,
  })  : _reviewsTable = reviewsTable ?? ReviewsTable(),
        _parkingPhotosTable = parkingPhotosTable ?? ParkingPhotosTable(),
        _photoStorage =
            photoStorage ?? const SupabaseReviewPhotoStorageGateway();

  final ReviewsTable _reviewsTable;
  final ParkingPhotosTable _parkingPhotosTable;
  final ReviewPhotoStorageGateway _photoStorage;

  @override
  Future<ReviewSubmissionResult> submitAtomically({
    required PreparedReviewSubmission submission,
  }) async {
    ReviewsRow? reviewRow;
    final uploadedPhotoUrls = <String>[];
    var createdPhotoCount = 0;
    try {
      reviewRow = await _reviewsTable.insert({
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

      for (final indexedPhoto in submission.photos.indexed) {
        final photoIndex = indexedPhoto.$1;
        final photo = indexedPhoto.$2;
        final bytes = photo.bytes;
        if (bytes == null || bytes.isEmpty) {
          throw const ReviewSubmissionException(
            failure: ReviewSubmissionFailure.invalidPhoto,
            message: 'Every review photo must contain image data.',
          );
        }

        final mimeType = _normalizedImageMimeType(photo);
        final photoUrl = await _photoStorage.uploadReviewPhoto(
          storagePath: _reviewPhotoStoragePath(
            submission: submission,
            reviewId: reviewRow.id,
            photoIndex: photoIndex,
            photo: photo,
          ),
          bytes: bytes,
          mimeType: mimeType,
        );
        uploadedPhotoUrls.add(photoUrl);
        await _parkingPhotosTable.insert({
          'url': photoUrl,
          'parking_id': submission.parkingId,
          'created_at': supaSerialize<DateTime>(submission.createdAt),
          'user_id': submission.userId,
          'review_id': reviewRow.id,
        });
        createdPhotoCount += 1;
      }

      return ReviewSubmissionResult(
        reviewId: reviewRow.id,
        createdPhotoCount: createdPhotoCount,
      );
    } catch (_) {
      await _compensateFailedSubmission(
        reviewId: reviewRow?.id,
        userId: submission.userId,
        uploadedPhotoUrls: uploadedPhotoUrls,
      );
      rethrow;
    }
  }

  Future<void> _compensateFailedSubmission({
    required int? reviewId,
    required String userId,
    required List<String> uploadedPhotoUrls,
  }) async {
    if (reviewId != null) {
      try {
        await _reviewsTable.delete(
          matchingRows: (q) => q
              .eqOrNull(
                'id',
                reviewId,
              )
              .eqOrNull(
                'user_id',
                userId,
              ),
        );
      } catch (_) {}
    }

    for (final photoUrl in uploadedPhotoUrls) {
      try {
        await _photoStorage.deletePublicUrl(photoUrl);
      } catch (_) {}
    }
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

    if (command.photos.any((photo) => !_isValidReviewPhoto(photo))) {
      throw const ReviewSubmissionException(
        failure: ReviewSubmissionFailure.invalidPhoto,
        message: 'Every review photo must be a valid image under 5 MiB.',
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

const _parkingContentBucket = 'parking_content';
const _maxReviewPhotoBytes = 5 * 1024 * 1024;
const _maxReviewPhotoDimension = 1920.0;

const _allowedReviewPhotoMimeTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
};

bool _isValidReviewPhoto(ReviewPhotoDraft photo) {
  final fileName = photo.fileName.trim();
  if (fileName.isEmpty || photo.byteLength <= 0) {
    return false;
  }
  if (photo.byteLength > _maxReviewPhotoBytes) {
    return false;
  }
  if (photo.bytes != null && photo.bytes!.length != photo.byteLength) {
    return false;
  }
  if ((photo.width ?? 0) > _maxReviewPhotoDimension ||
      (photo.height ?? 0) > _maxReviewPhotoDimension) {
    return false;
  }
  return _allowedReviewPhotoMimeTypes.contains(_normalizedImageMimeType(photo));
}

String _normalizedImageMimeType(ReviewPhotoDraft photo) {
  final mimeType = photo.mimeType?.trim().toLowerCase();
  if (mimeType != null && mimeType.isNotEmpty) {
    return mimeType == 'image/jpg' ? 'image/jpeg' : mimeType;
  }

  final extension = _fileExtension(photo.fileName);
  return switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => '',
  };
}

String _reviewPhotoStoragePath({
  required PreparedReviewSubmission submission,
  required int reviewId,
  required int photoIndex,
  required ReviewPhotoDraft photo,
}) {
  final extension = switch (_normalizedImageMimeType(photo)) {
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => _fileExtension(photo.fileName),
  };
  final timestamp = submission.createdAt.microsecondsSinceEpoch;
  return 'parkings/${submission.parkingId}/reviews/$reviewId/$photoIndex/'
      '$timestamp.$extension';
}

String _fileExtension(String fileName) {
  final parts = fileName.trim().split('.');
  if (parts.length < 2) {
    return '';
  }
  return parts.last.toLowerCase();
}
