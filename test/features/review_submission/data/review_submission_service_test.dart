import 'package:flutter_test/flutter_test.dart';
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

  @override
  Future<ReviewSubmissionResult> submitAtomically({
    required PreparedReviewSubmission submission,
  }) async {
    calls += 1;
    return ReviewSubmissionResult(
      reviewId: 1,
      createdPhotoCount: submission.photos.length,
    );
  }
}
