import 'package:flutter_test/flutter_test.dart';
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
  });
}

class _FakeReviewsGateway implements ReviewsGateway {
  _FakeReviewsGateway({
    this.reviewCount = 0,
    this.reviews = const [],
  });

  final int reviewCount;
  final List<ParkingReview> reviews;
  final calls = <String>[];

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
}
