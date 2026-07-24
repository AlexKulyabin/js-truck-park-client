import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/backend/supabase/database/database.dart';
import 'package:j_s_truck_park/core/config/app_config.dart';
import 'package:j_s_truck_park/features/review_submission/data/review_submission_service.dart';

void main() {
  group('ReviewSubmissionService', () {
    test('prepares normalized immutable review data', () {
      final service = _service();

      final submission = service.prepare(
        _command(
          parkingId: ' parking-1 ',
          userId: ' user-1 ',
          comment: 'Good stop',
          photos: const [
            ReviewPhotoDraft(
              fileName: 'photo.jpg',
              byteLength: 128,
              mimeType: 'image/jpeg',
            ),
          ],
        ),
      );

      expect(submission.parkingId, 'parking-1');
      expect(submission.userId, 'user-1');
      expect(submission.comment, 'Good stop');
      expect(submission.requiresAtomicPhotoHandling, isTrue);
      expect(
        () => submission.photos.add(
          const ReviewPhotoDraft(fileName: 'other.jpg', byteLength: 1),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects incomplete identity', () {
      final service = _service();

      expect(
        () => service.prepare(_command(parkingId: ' ')),
        throwsA(
          isA<ReviewSubmissionException>().having(
            (error) => error.failure,
            'failure',
            ReviewSubmissionFailure.invalidIdentity,
          ),
        ),
      );
    });

    test('preserves current UI eligibility contract', () {
      final service = _service();

      expect(
        () => service.prepare(
          _command(
            comment: '',
            ratingImpression: 0,
            ratingArrival: 0,
            ratingSecurity: 0,
            ratingInfrastructure: 0,
            ratingComfort: 5,
          ),
        ),
        throwsA(
          isA<ReviewSubmissionException>().having(
            (error) => error.failure,
            'failure',
            ReviewSubmissionFailure.emptyContent,
          ),
        ),
      );
    });

    test('rejects invalid rating and empty photo payload', () {
      final service = _service();

      expect(
        () => service.prepare(_command(ratingArrival: 6)),
        throwsA(isA<ReviewSubmissionException>()),
      );
      expect(
        () => service.prepare(
          _command(
            photos: const [
              ReviewPhotoDraft(fileName: 'photo.jpg', byteLength: 0),
            ],
          ),
        ),
        throwsA(
          isA<ReviewSubmissionException>().having(
            (error) => error.failure,
            'failure',
            ReviewSubmissionFailure.invalidPhoto,
          ),
        ),
      );
    });

    test('disabled capability prevents every gateway write', () async {
      final gateway = _FakeReviewSubmissionGateway();
      final service = _service(gateway: gateway);

      await expectLater(
        service.submit(_command()),
        throwsA(
          isA<ReviewSubmissionException>().having(
            (error) => error.failure,
            'failure',
            ReviewSubmissionFailure.disabled,
          ),
        ),
      );
      expect(gateway.calls, 0);
    });

    test('enabled test capability submits prepared review data', () async {
      final gateway = _FakeReviewSubmissionGateway();
      final service = ReviewSubmissionService(
        gateway: gateway,
        config: AppConfig.resolve(
          isReleaseMode: false,
          supabaseUrlOverride: 'http://127.0.0.1:54321',
          testWritesOverride: 'true',
        ),
      );

      final result = await service.submit(
        _command(
          parkingId: ' parking-1 ',
          userId: ' user-1 ',
        ),
      );

      expect(result.reviewId, 1);
      expect(gateway.calls, 1);
      expect(gateway.lastSubmission?.parkingId, 'parking-1');
      expect(gateway.lastSubmission?.userId, 'user-1');
    });

    test('supabase gateway inserts a no-photo review payload', () async {
      final reviewsTable = _FakeReviewsTable();
      final gateway = SupabaseReviewSubmissionGateway(
        reviewsTable: reviewsTable,
      );

      final result = await gateway.submitAtomically(
        submission: _service().prepare(_command()),
      );

      expect(result.reviewId, 42);
      expect(result.createdPhotoCount, 0);
      expect(reviewsTable.insertedRows.single, {
        'parking_id': 'parking-1',
        'comment': 'Good stop',
        'rating_impression': 5,
        'rating_arrival': 4,
        'rating_security': 3,
        'rating_infrastructure': 2,
        'rating_comfort': 1,
        'created_at': '2026-07-24T00:00:00.000',
        'user_id': 'user-1',
      });
    });

    test('supabase gateway rejects photos until atomic photo flow exists',
        () async {
      final reviewsTable = _FakeReviewsTable();
      final gateway = SupabaseReviewSubmissionGateway(
        reviewsTable: reviewsTable,
      );

      await expectLater(
        gateway.submitAtomically(
          submission: _service().prepare(
            _command(
              photos: const [
                ReviewPhotoDraft(
                  fileName: 'photo.jpg',
                  byteLength: 128,
                  mimeType: 'image/jpeg',
                ),
              ],
            ),
          ),
        ),
        throwsA(
          isA<ReviewSubmissionException>().having(
            (error) => error.failure,
            'failure',
            ReviewSubmissionFailure.invalidPhoto,
          ),
        ),
      );
      expect(reviewsTable.insertedRows, isEmpty);
    });
  });
}

ReviewSubmissionService _service({_FakeReviewSubmissionGateway? gateway}) {
  return ReviewSubmissionService(
    gateway: gateway ?? _FakeReviewSubmissionGateway(),
    config: AppConfig.resolve(isReleaseMode: false),
  );
}

ReviewSubmissionCommand _command({
  String? parkingId = 'parking-1',
  String userId = 'user-1',
  String comment = 'Good stop',
  int ratingImpression = 5,
  int ratingArrival = 4,
  int ratingSecurity = 3,
  int ratingInfrastructure = 2,
  int ratingComfort = 1,
  List<ReviewPhotoDraft> photos = const [],
}) {
  return ReviewSubmissionCommand(
    parkingId: parkingId,
    userId: userId,
    comment: comment,
    ratingImpression: ratingImpression,
    ratingArrival: ratingArrival,
    ratingSecurity: ratingSecurity,
    ratingInfrastructure: ratingInfrastructure,
    ratingComfort: ratingComfort,
    createdAt: DateTime(2026, 7, 24),
    photos: photos,
  );
}

class _FakeReviewSubmissionGateway implements ReviewSubmissionGateway {
  int calls = 0;
  PreparedReviewSubmission? lastSubmission;

  @override
  Future<ReviewSubmissionResult> submitAtomically({
    required PreparedReviewSubmission submission,
  }) async {
    calls += 1;
    lastSubmission = submission;
    return ReviewSubmissionResult(
      reviewId: 1,
      createdPhotoCount: submission.photos.length,
    );
  }
}

class _FakeReviewsTable extends ReviewsTable {
  final insertedRows = <Map<String, dynamic>>[];

  @override
  Future<ReviewsRow> insert(Map<String, dynamic> data) async {
    insertedRows.add(data);
    return ReviewsRow({'id': 42});
  }
}
