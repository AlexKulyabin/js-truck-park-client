import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/reviews/application/user_reviews_controller.dart';
import 'package:j_s_truck_park/features/reviews/domain/user_complaint_summary.dart';
import 'package:j_s_truck_park/features/reviews/domain/user_review_summary.dart';
import 'package:j_s_truck_park/features/reviews/domain/user_reviews_repository.dart';

const _review = UserReviewSummary(
  id: 1,
  parkingAddress: 'Review parking',
  createdAt: null,
  averageScore: 4,
  comment: 'Nice',
  authorAvatarUrl: null,
  photoUrls: [],
);

const _complaint = UserComplaintSummary(
  id: 2,
  parkingAddress: 'Complaint parking',
  reportDate: null,
  reportType: 'Report1',
  comment: 'Missing',
  parkingPhotoUrls: [],
  photosCount: null,
);

class _FakeRepository implements UserReviewsRepository {
  final reviewUserIds = <String>[];
  final complaintUserIds = <String>[];
  final reviewCompleters = <Completer<List<UserReviewSummary>>>[];
  final complaintCompleters = <Completer<List<UserComplaintSummary>>>[];
  UserReviewsReadException? reviewError;

  @override
  Future<List<UserReviewSummary>> fetchOwnedReviews(String userId) {
    reviewUserIds.add(userId);
    if (reviewError case final error?) {
      throw error;
    }
    final completer = Completer<List<UserReviewSummary>>();
    reviewCompleters.add(completer);
    return completer.future;
  }

  @override
  Future<List<UserComplaintSummary>> fetchOwnedComplaints(String userId) {
    complaintUserIds.add(userId);
    final completer = Completer<List<UserComplaintSummary>>();
    complaintCompleters.add(completer);
    return completer.future;
  }
}

void main() {
  test('loads owned reviews into immutable state', () async {
    final repository = _FakeRepository();
    final controller = UserReviewsController(
      repository: repository,
      userId: 'user-1',
    );

    final load = controller.loadReviews();
    expect(controller.state.reviews.phase, UserReviewsLoadPhase.loading);
    repository.reviewCompleters.single.complete(const [_review]);
    await load;

    expect(repository.reviewUserIds, ['user-1']);
    expect(controller.state.reviews.phase, UserReviewsLoadPhase.loaded);
    expect(controller.state.reviews.items, const [_review]);
    expect(
      () => controller.state.reviews.items.add(_review),
      throwsUnsupportedError,
    );

    controller.dispose();
  });

  test('switches to complaints and lazy-loads that tab once', () async {
    final repository = _FakeRepository();
    final controller = UserReviewsController(
      repository: repository,
      userId: 'user-1',
    );

    final select = controller.selectTab(UserReviewsTab.complaints);
    expect(controller.state.selectedTab, UserReviewsTab.complaints);
    expect(controller.state.complaints.phase, UserReviewsLoadPhase.loading);
    repository.complaintCompleters.single.complete(const [_complaint]);
    await select;

    await controller.selectTab(UserReviewsTab.complaints);

    expect(repository.complaintUserIds, ['user-1']);
    expect(controller.state.complaints.items, const [_complaint]);

    controller.dispose();
  });

  test('ignores stale review responses after retry', () async {
    final repository = _FakeRepository();
    final controller = UserReviewsController(
      repository: repository,
      userId: 'user-1',
    );

    final firstLoad = controller.loadReviews();
    final secondLoad = controller.loadReviews();
    repository.reviewCompleters.first.complete(const []);
    repository.reviewCompleters.last.complete(const [_review]);
    await Future.wait([firstLoad, secondLoad]);

    expect(controller.state.reviews.items, const [_review]);

    controller.dispose();
  });

  test('stores only redacted failure kind', () async {
    final repository = _FakeRepository()
      ..reviewError = const UserReviewsReadException(
        UserReviewsFailureKind.unavailable,
      );
    final controller = UserReviewsController(
      repository: repository,
      userId: 'user-1',
    );

    await controller.loadReviews();

    expect(controller.state.reviews.phase, UserReviewsLoadPhase.failure);
    expect(
      controller.state.reviews.failureKind,
      UserReviewsFailureKind.unavailable,
    );

    controller.dispose();
  });
}
