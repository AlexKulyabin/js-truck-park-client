import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_details/data/legacy_parking_details_adapter.dart';
import 'package:j_s_truck_park/features/parking_details/data/supabase_parking_details_repository.dart';
import 'package:j_s_truck_park/features/parking_details/domain/parking_details.dart';
import 'package:j_s_truck_park/features/parking_details/domain/parking_details_repository.dart';

class _FakeDataSource implements ParkingDetailsDataSource {
  List<Map<String, dynamic>> detailsRows = [];
  List<Map<String, dynamic>> reviewRows = [];
  Object? detailsError;
  Object? reviewsError;
  final detailsParkingIds = <String>[];
  final reviewParkingIds = <String>[];

  @override
  Future<List<Map<String, dynamic>>> fetchDetailsRows(String parkingId) async {
    detailsParkingIds.add(parkingId);
    if (detailsError case final error?) {
      throw error;
    }
    return detailsRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReviewRows(String parkingId) async {
    reviewParkingIds.add(parkingId);
    if (reviewsError case final error?) {
      throw error;
    }
    return reviewRows;
  }
}

void main() {
  test('maps the bounded details view row into a typed model', () async {
    final dataSource = _FakeDataSource()
      ..detailsRows = [
        {
          'id': 'parking-1',
          'address': 'Test address',
          'latitude': 52.1,
          'longitude': 21.2,
          'total_spaces': 20,
          'rating': 4.5,
          'stars_5': 3,
          'reviews_count': 4,
          'photos_count': 1,
          'is_favorited': true,
          'has_shower': false,
          'all_photos': [
            {
              'url': 'https://example.com/photo.jpg',
              'photo_date': '23.07.2026'
            },
          ],
        },
      ];
    final repository = SupabaseParkingDetailsRepository(dataSource: dataSource);

    final details = await repository.fetchDetails('parking-1');

    expect(dataSource.detailsParkingIds, ['parking-1']);
    expect(details?.id, 'parking-1');
    expect(details?.address, 'Test address');
    expect(details?.latitude, 52.1);
    expect(details?.isFavorited, isTrue);
    expect(details?.hasShower, isFalse);
    expect(
      details?.photos,
      const [
        ParkingDetailsPhoto(
          url: 'https://example.com/photo.jpg',
          photoDate: '23.07.2026',
        ),
      ],
    );
  });

  test('maps reviews and preserves the selected parking id', () async {
    final dataSource = _FakeDataSource()
      ..reviewRows = [
        {
          'id': 7,
          'parking_id': 'parking-1',
          'created_at': '2026-07-23T12:00:00.000Z',
          'user_id': 'user-1',
          'comment': 'Safe',
          'average_score': 4.2,
          'author_name': 'Driver',
          'review_photos': ['https://example.com/review.jpg'],
        },
      ];
    final repository = SupabaseParkingDetailsRepository(dataSource: dataSource);

    final reviews = await repository.fetchReviews('parking-1');

    expect(dataSource.reviewParkingIds, ['parking-1']);
    expect(reviews.single.id, 7);
    expect(reviews.single.parkingId, 'parking-1');
    expect(reviews.single.authorName, 'Driver');
    expect(reviews.single.reviewPhotos, ['https://example.com/review.jpg']);
  });

  test('does not perform an unfiltered read for an empty parking id', () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseParkingDetailsRepository(dataSource: dataSource);

    expect(await repository.fetchDetails(''), isNull);
    expect(await repository.fetchReviews(''), isEmpty);
    expect(dataSource.detailsParkingIds, isEmpty);
    expect(dataSource.reviewParkingIds, isEmpty);
  });

  test('rejects rows that belong to another parking', () async {
    final dataSource = _FakeDataSource()
      ..detailsRows = [
        {'id': 'parking-2'},
      ]
      ..reviewRows = [
        {'id': 1, 'parking_id': 'parking-2'},
      ];
    final repository = SupabaseParkingDetailsRepository(dataSource: dataSource);

    for (final read in [
      repository.fetchDetails('parking-1'),
      repository.fetchReviews('parking-1'),
    ]) {
      await expectLater(
        read,
        throwsA(
          isA<ParkingDetailsReadException>().having(
            (error) => error.kind,
            'kind',
            ParkingDetailsFailureKind.invalidData,
          ),
        ),
      );
    }
  });

  test('rejects malformed photo data before it reaches presentation', () async {
    final dataSource = _FakeDataSource()
      ..detailsRows = [
        {
          'id': 'parking-1',
          'all_photos': [
            {'url': ''},
          ],
        },
      ];
    final repository = SupabaseParkingDetailsRepository(dataSource: dataSource);

    await expectLater(
      repository.fetchDetails('parking-1'),
      throwsA(
        isA<ParkingDetailsReadException>().having(
          (error) => error.kind,
          'kind',
          ParkingDetailsFailureKind.invalidData,
        ),
      ),
    );
  });

  test('redacts transport failures behind an unavailable category', () async {
    final dataSource = _FakeDataSource()
      ..detailsError = StateError('sensitive details payload')
      ..reviewsError = StateError('sensitive review payload');
    final repository = SupabaseParkingDetailsRepository(dataSource: dataSource);

    for (final read in [
      repository.fetchDetails('parking-1'),
      repository.fetchReviews('parking-1'),
    ]) {
      await expectLater(
        read,
        throwsA(
          isA<ParkingDetailsReadException>().having(
            (error) => error.kind,
            'kind',
            ParkingDetailsFailureKind.unavailable,
          ),
        ),
      );
    }
  });

  test('legacy adapters preserve photo and review viewer contracts', () {
    const details = ParkingDetails(
      id: 'parking-1',
      isFavorited: false,
      photos: [
        ParkingDetailsPhoto(
          url: 'https://example.com/photo.jpg',
          photoDate: '23.07.2026',
        ),
      ],
    );
    const review = ParkingReview(
      id: 1,
      parkingId: 'parking-1',
      reviewPhotos: ['https://example.com/review.jpg'],
    );

    final detailsRow = parkingDetailsToLegacyRow(details);
    final reviewRow = parkingReviewToLegacyRow(review);

    expect(detailsRow.allPhotos, [
      {
        'url': 'https://example.com/photo.jpg',
        'photo_date': '23.07.2026',
      },
    ]);
    expect(reviewRow.parkingId, 'parking-1');
    expect(reviewRow.reviewPhotos, ['https://example.com/review.jpg']);
  });
}
