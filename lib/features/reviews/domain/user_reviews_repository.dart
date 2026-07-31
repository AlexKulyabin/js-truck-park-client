import 'user_complaint_summary.dart';
import 'user_review_summary.dart';

enum UserReviewsFailureKind { unavailable, invalidData }

class UserReviewsReadException implements Exception {
  const UserReviewsReadException(this.kind);

  final UserReviewsFailureKind kind;
}

abstract interface class UserReviewsRepository {
  Future<List<UserReviewSummary>> fetchOwnedReviews(String userId);

  Future<List<UserComplaintSummary>> fetchOwnedComplaints(String userId);
}
