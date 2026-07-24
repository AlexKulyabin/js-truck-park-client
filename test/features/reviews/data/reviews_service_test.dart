import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/core/config/app_config.dart';
import 'package:j_s_truck_park/features/reviews/data/reviews_service.dart';

void main() {
  group('ReviewsService', () {
    test('returns zero count without querying when parking id is empty',
        () async {
      final gateway = _FakeReviewsGateway();
      final service = ReviewsService(gateway: gateway);

      final result = await service.countParkingReviews(parkingId: ' ');

      expect(result, 0);
      expect(gateway.calls, isEmpty);
    });

    test('loads count for normalized parking id', () async {
      final gateway = _FakeReviewsGateway(reviewCount: 3);
      final service = ReviewsService(gateway: gateway);

      final result =
          await service.countParkingReviews(parkingId: ' parking-1 ');

      expect(result, 3);
      expect(gateway.calls, [
        'count:parking-1',
      ]);
    });

    test('returns empty review list without querying when parking id is empty',
        () async {
      final gateway = _FakeReviewsGateway();
      final service = ReviewsService(gateway: gateway);

      final result = await service.listParkingReviews(parkingId: null);

      expect(result, isEmpty);
      expect(gateway.calls, isEmpty);
    });

    test('loads parking reviews for normalized parking id', () async {
      final gateway = _FakeReviewsGateway(
        reviews: [
          ParkingReview(
            id: 1,
            createdAt: DateTime(2026, 1, 1),
            userId: 'user-1',
            parkingId: 'parking-1',
            comment: 'Good',
            ratingImpression: 5,
            ratingArrival: 4,
            ratingSecurity: 4,
            ratingInfrastructure: 3,
            ratingComfort: 5,
            averageScore: 4.2,
            parkingAddress: 'Address 1',
            authorName: 'Driver',
            authorAvatar: null,
            photoUrls: const ['https://example.test/review.jpg'],
            hasPhotoPayload: true,
          ),
        ],
      );
      final service = ReviewsService(gateway: gateway);

      final result = await service.listParkingReviews(parkingId: ' parking-1 ');

      expect(result.single.authorName, 'Driver');
      expect(result.single.photoUrls.single, 'https://example.test/review.jpg');
      expect(gateway.calls, [
        'list:parking-1',
      ]);
    });

    test(
        'returns empty user review list without querying when user id is empty',
        () async {
      final gateway = _FakeReviewsGateway();
      final service = ReviewsService(gateway: gateway);

      final result = await service.listUserReviews(userId: ' ');

      expect(result, isEmpty);
      expect(gateway.calls, isEmpty);
    });

    test('loads user reviews for normalized user id', () async {
      final gateway = _FakeReviewsGateway(
        reviews: [
          ParkingReview(
            id: 1,
            createdAt: DateTime(2026, 1, 1),
            userId: 'user-1',
            parkingId: 'parking-1',
            comment: 'Good',
            ratingImpression: 5,
            ratingArrival: 4,
            ratingSecurity: 4,
            ratingInfrastructure: 3,
            ratingComfort: 5,
            averageScore: 4.2,
            parkingAddress: 'Address 1',
            authorName: 'Driver',
            authorAvatar: null,
            photoUrls: const ['https://example.test/review.jpg'],
            hasPhotoPayload: true,
          ),
        ],
      );
      final service = ReviewsService(gateway: gateway);

      final result = await service.listUserReviews(userId: ' user-1 ');

      expect(result.single.parkingAddress, 'Address 1');
      expect(gateway.calls, [
        'listUser:user-1',
      ]);
    });

    test('rejects review updates when capability is disabled', () async {
      final gateway = _FakeReviewsGateway();
      final service = ReviewsService(gateway: gateway);

      await expectLater(
        service.updateReview(_updateRequest()),
        throwsA(isA<ReviewMutationException>()),
      );
      expect(gateway.calls, isEmpty);
    });

    test('rejects invalid review update payloads without querying', () async {
      final gateway = _FakeReviewsGateway();
      final service = _writeEnabledService(gateway);

      await expectLater(
        service.updateReview(_updateRequest(reviewId: 0)),
        throwsA(isA<ReviewMutationException>()),
      );
      await expectLater(
        service.updateReview(_updateRequest(userId: ' ')),
        throwsA(isA<ReviewMutationException>()),
      );
      await expectLater(
        service.updateReview(_updateRequest(ratingComfort: 6)),
        throwsA(isA<ReviewMutationException>()),
      );
      await expectLater(
        service.updateReview(
          _updateRequest(
            comment: '',
            ratingImpression: 0,
            ratingArrival: 0,
            ratingSecurity: 0,
            ratingInfrastructure: 0,
            ratingComfort: 0,
          ),
        ),
        throwsA(isA<ReviewMutationException>()),
      );
      expect(gateway.calls, isEmpty);
    });

    test('updates mutable review content for normalized owner identity',
        () async {
      final gateway = _FakeReviewsGateway(
        updatedReview: const UpdatedReview(
          id: 7,
          comment: 'Updated review',
          ratingImpression: 5,
          ratingArrival: 4,
          ratingSecurity: 3,
          ratingInfrastructure: 2,
          ratingComfort: 1,
          averageScore: 3,
        ),
      );
      final service = _writeEnabledService(gateway);

      final result = await service.updateReview(
        _updateRequest(userId: ' user-1 '),
      );

      expect(result.id, 7);
      expect(gateway.lastUpdateRequest?.userId, 'user-1');
      expect(gateway.calls, ['update:7:user-1']);
    });

    test('rejects review deletes when capability is disabled', () async {
      final gateway = _FakeReviewsGateway();
      final service = ReviewsService(gateway: gateway);

      await expectLater(
        service.deleteReview(_deleteRequest()),
        throwsA(isA<ReviewMutationException>()),
      );
      expect(gateway.calls, isEmpty);
    });

    test('rejects invalid review delete payloads without querying', () async {
      final gateway = _FakeReviewsGateway();
      final service = _writeEnabledService(gateway);

      await expectLater(
        service.deleteReview(_deleteRequest(reviewId: 0)),
        throwsA(isA<ReviewMutationException>()),
      );
      await expectLater(
        service.deleteReview(_deleteRequest(userId: ' ')),
        throwsA(isA<ReviewMutationException>()),
      );
      expect(gateway.calls, isEmpty);
    });

    test('deletes owner review for normalized owner identity', () async {
      final gateway = _FakeReviewsGateway(
        deletedReview: const DeletedReview(
          id: 7,
          deletedStorageObjectCount: 2,
          storageCleanupFailedCount: 0,
        ),
      );
      final service = _writeEnabledService(gateway);

      final result = await service.deleteReview(
        _deleteRequest(userId: ' user-1 '),
      );

      expect(result.deletedStorageObjectCount, 2);
      expect(gateway.lastDeleteRequest?.userId, 'user-1');
      expect(gateway.calls, ['delete:7:user-1']);
    });
  });
}

ReviewsService _writeEnabledService(_FakeReviewsGateway gateway) {
  return ReviewsService(
    gateway: gateway,
    config: AppConfig.resolve(
      isReleaseMode: false,
      supabaseUrlOverride: 'http://127.0.0.1:54321',
      testWritesOverride: 'true',
    ),
  );
}

UpdateReviewRequest _updateRequest({
  int? reviewId = 7,
  String userId = 'user-1',
  String comment = 'Updated review',
  int ratingImpression = 5,
  int ratingArrival = 4,
  int ratingSecurity = 3,
  int ratingInfrastructure = 2,
  int ratingComfort = 1,
}) {
  return UpdateReviewRequest(
    reviewId: reviewId,
    userId: userId,
    comment: comment,
    ratingImpression: ratingImpression,
    ratingArrival: ratingArrival,
    ratingSecurity: ratingSecurity,
    ratingInfrastructure: ratingInfrastructure,
    ratingComfort: ratingComfort,
  );
}

DeleteReviewRequest _deleteRequest({
  int? reviewId = 7,
  String userId = 'user-1',
}) {
  return DeleteReviewRequest(
    reviewId: reviewId,
    userId: userId,
  );
}

class _FakeReviewsGateway implements ReviewsGateway {
  _FakeReviewsGateway({
    this.reviewCount = 0,
    this.reviews = const [],
    this.updatedReview,
    this.deletedReview,
  });

  final int reviewCount;
  final List<ParkingReview> reviews;
  final UpdatedReview? updatedReview;
  final DeletedReview? deletedReview;
  final calls = <String>[];
  UpdateReviewRequest? lastUpdateRequest;
  DeleteReviewRequest? lastDeleteRequest;

  @override
  Future<int> countParkingReviews({
    required String parkingId,
  }) async {
    calls.add('count:$parkingId');
    return reviewCount;
  }

  @override
  Future<List<ParkingReview>> listParkingReviews({
    required String parkingId,
  }) async {
    calls.add('list:$parkingId');
    return reviews;
  }

  @override
  Future<List<ParkingReview>> listUserReviews({
    required String userId,
  }) async {
    calls.add('listUser:$userId');
    return reviews;
  }

  @override
  Future<UpdatedReview> updateReview({
    required UpdateReviewRequest request,
  }) async {
    calls.add('update:${request.reviewId}:${request.userId}');
    lastUpdateRequest = request;
    return updatedReview ??
        UpdatedReview(
          id: request.reviewId!,
          comment: request.comment,
          ratingImpression: request.ratingImpression,
          ratingArrival: request.ratingArrival,
          ratingSecurity: request.ratingSecurity,
          ratingInfrastructure: request.ratingInfrastructure,
          ratingComfort: request.ratingComfort,
          averageScore: 3,
        );
  }

  @override
  Future<DeletedReview> deleteReview({
    required DeleteReviewRequest request,
  }) async {
    calls.add('delete:${request.reviewId}:${request.userId}');
    lastDeleteRequest = request;
    return deletedReview ??
        DeletedReview(
          id: request.reviewId!,
          deletedStorageObjectCount: 0,
          storageCleanupFailedCount: 0,
        );
  }
}
