import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/reviews/data/supabase_user_reviews_repository.dart';
import 'package:j_s_truck_park/features/reviews/domain/user_complaint_summary.dart';
import 'package:j_s_truck_park/features/reviews/domain/user_review_summary.dart';
import 'package:j_s_truck_park/features/reviews/domain/user_reviews_repository.dart';

class _FakeDataSource implements UserReviewsDataSource {
  final reviewUserIds = <String>[];
  final complaintUserIds = <String>[];
  List<Map<String, dynamic>> reviewRows = [];
  List<Map<String, dynamic>> complaintRows = [];
  Object? reviewError;
  Object? complaintError;

  @override
  Future<List<Map<String, dynamic>>> fetchOwnedReviewRows(String userId) async {
    reviewUserIds.add(userId);
    if (reviewError case final error?) {
      throw error;
    }
    return reviewRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOwnedComplaintRows(
    String userId,
  ) async {
    complaintUserIds.add(userId);
    if (complaintError case final error?) {
      throw error;
    }
    return complaintRows;
  }
}

void main() {
  test('filters review rows by owner and maps bounded summaries', () async {
    final createdAt = DateTime(2026, 7, 24);
    final dataSource = _FakeDataSource()
      ..reviewRows = [
        {
          'id': 7,
          'user_id': 'user-1',
          'parking_address': 'Test parking',
          'created_at': createdAt,
          'average_score': 4.5,
          'comment': 'Good stop',
          'author_avatar': 'https://example.com/avatar.jpg',
          'review_photos': ['https://example.com/review.jpg'],
        },
      ];
    final repository = SupabaseUserReviewsRepository(dataSource: dataSource);

    final result = await repository.fetchOwnedReviews('user-1');

    expect(dataSource.reviewUserIds, ['user-1']);
    expect(
      result,
      [
        UserReviewSummary(
          id: 7,
          parkingAddress: 'Test parking',
          createdAt: createdAt,
          averageScore: 4.5,
          comment: 'Good stop',
          authorAvatarUrl: 'https://example.com/avatar.jpg',
          photoUrls: const ['https://example.com/review.jpg'],
        ),
      ],
    );
  });

  test('filters complaint rows by owner and maps photo navigation data',
      () async {
    final reportDate = DateTime(2026, 7, 24);
    final dataSource = _FakeDataSource()
      ..complaintRows = [
        {
          'report_id': 11,
          'reporter_id': 'user-1',
          'parking_address': 'Unsafe parking',
          'report_date': reportDate,
          'report_type': 'Report2',
          'report_comment': 'Needs attention',
          'parking_photos': ['https://example.com/parking.jpg'],
          'photos_count': 3,
        },
      ];
    final repository = SupabaseUserReviewsRepository(dataSource: dataSource);

    final result = await repository.fetchOwnedComplaints('user-1');

    expect(dataSource.complaintUserIds, ['user-1']);
    expect(
      result,
      [
        UserComplaintSummary(
          id: 11,
          parkingAddress: 'Unsafe parking',
          reportDate: reportDate,
          reportType: 'Report2',
          comment: 'Needs attention',
          parkingPhotoUrls: const ['https://example.com/parking.jpg'],
          photosCount: 3,
        ),
      ],
    );
  });

  test('does not perform unfiltered queries without an authenticated user',
      () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseUserReviewsRepository(dataSource: dataSource);

    final reviews = await repository.fetchOwnedReviews('');
    final complaints = await repository.fetchOwnedComplaints('');

    expect(reviews, isEmpty);
    expect(complaints, isEmpty);
    expect(dataSource.reviewUserIds, isEmpty);
    expect(dataSource.complaintUserIds, isEmpty);
  });

  test('rejects cross-user rows', () async {
    final dataSource = _FakeDataSource()
      ..reviewRows = [
        {
          'id': 7,
          'user_id': 'user-2',
          'average_score': 4,
          'review_photos': null,
        },
      ];
    final repository = SupabaseUserReviewsRepository(dataSource: dataSource);

    await expectLater(
      repository.fetchOwnedReviews('user-1'),
      throwsA(
        isA<UserReviewsReadException>().having(
          (error) => error.kind,
          'kind',
          UserReviewsFailureKind.invalidData,
        ),
      ),
    );
  });

  test('rejects malformed photo lists', () async {
    final dataSource = _FakeDataSource()
      ..complaintRows = [
        {
          'report_id': 11,
          'reporter_id': 'user-1',
          'parking_photos': [''],
        },
      ];
    final repository = SupabaseUserReviewsRepository(dataSource: dataSource);

    await expectLater(
      repository.fetchOwnedComplaints('user-1'),
      throwsA(
        isA<UserReviewsReadException>().having(
          (error) => error.kind,
          'kind',
          UserReviewsFailureKind.invalidData,
        ),
      ),
    );
  });

  test('redacts data-source failures', () async {
    final dataSource = _FakeDataSource()
      ..reviewError = StateError('raw database details');
    final repository = SupabaseUserReviewsRepository(dataSource: dataSource);

    await expectLater(
      repository.fetchOwnedReviews('user-1'),
      throwsA(
        isA<UserReviewsReadException>()
            .having(
              (error) => error.kind,
              'kind',
              UserReviewsFailureKind.unavailable,
            )
            .having(
              (error) => error.toString(),
              'redacted message',
              isNot(contains('raw database details')),
            ),
      ),
    );
  });
}
