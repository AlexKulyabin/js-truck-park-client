import '../../../backend/supabase/supabase.dart';
import '../domain/user_complaint_summary.dart';
import '../domain/user_review_summary.dart';
import '../domain/user_reviews_repository.dart';

abstract interface class UserReviewsDataSource {
  Future<List<Map<String, dynamic>>> fetchOwnedReviewRows(String userId);

  Future<List<Map<String, dynamic>>> fetchOwnedComplaintRows(String userId);
}

class GeneratedUserReviewsDataSource implements UserReviewsDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchOwnedReviewRows(String userId) async {
    final rows = await ViewReviewsWithUsersTable().queryRows(
      queryFn: (query) => query.eq('user_id', userId).order('created_at'),
    );
    return rows
        .map((row) => Map<String, dynamic>.unmodifiable(row.data))
        .toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOwnedComplaintRows(
    String userId,
  ) async {
    final rows = await ViewReportsDetailedTable().queryRows(
      queryFn: (query) => query.eq('reporter_id', userId).order('report_date'),
    );
    return rows
        .map((row) => Map<String, dynamic>.unmodifiable(row.data))
        .toList(growable: false);
  }
}

class SupabaseUserReviewsRepository implements UserReviewsRepository {
  SupabaseUserReviewsRepository({UserReviewsDataSource? dataSource})
      : _dataSource = dataSource ?? GeneratedUserReviewsDataSource();

  final UserReviewsDataSource _dataSource;

  @override
  Future<List<UserReviewSummary>> fetchOwnedReviews(String userId) async {
    if (userId.isEmpty) {
      return const [];
    }

    try {
      final rows = await _dataSource.fetchOwnedReviewRows(userId);
      return rows
          .map((row) => _mapReview(row, expectedUserId: userId))
          .toList(growable: false);
    } on UserReviewsReadException {
      rethrow;
    } catch (_) {
      throw const UserReviewsReadException(
        UserReviewsFailureKind.unavailable,
      );
    }
  }

  @override
  Future<List<UserComplaintSummary>> fetchOwnedComplaints(String userId) async {
    if (userId.isEmpty) {
      return const [];
    }

    try {
      final rows = await _dataSource.fetchOwnedComplaintRows(userId);
      return rows
          .map((row) => _mapComplaint(row, expectedUserId: userId))
          .toList(growable: false);
    } on UserReviewsReadException {
      rethrow;
    } catch (_) {
      throw const UserReviewsReadException(
        UserReviewsFailureKind.unavailable,
      );
    }
  }

  UserReviewSummary _mapReview(
    Map<String, dynamic> row, {
    required String expectedUserId,
  }) {
    final id = _asInt(row['id']);
    final userId = row['user_id'];
    final averageScore = _asDouble(row['average_score']);

    if (id == null ||
        id <= 0 ||
        userId is! String ||
        userId != expectedUserId ||
        averageScore == null) {
      throw const UserReviewsReadException(
        UserReviewsFailureKind.invalidData,
      );
    }

    return UserReviewSummary(
      id: id,
      parkingAddress: _stringOrDefault(row['parking_address'], 'No address'),
      createdAt: _asDateTime(row['created_at']),
      averageScore: averageScore,
      comment: _stringOrDefault(row['comment'], ''),
      authorAvatarUrl: _optionalNonEmptyString(row['author_avatar']),
      photoUrls: _stringList(row['review_photos']),
    );
  }

  UserComplaintSummary _mapComplaint(
    Map<String, dynamic> row, {
    required String expectedUserId,
  }) {
    final id = _asInt(row['report_id']);
    final reporterId = row['reporter_id'];
    final photosCount = _nullableNonNegativeInt(row['photos_count']);

    if (id == null ||
        id <= 0 ||
        reporterId is! String ||
        reporterId != expectedUserId ||
        photosCount == -1) {
      throw const UserReviewsReadException(
        UserReviewsFailureKind.invalidData,
      );
    }

    return UserComplaintSummary(
      id: id,
      parkingAddress: _stringOrDefault(row['parking_address'], 'No address'),
      reportDate: _asDateTime(row['report_date']),
      reportType: _optionalNonEmptyString(row['report_type']),
      comment: _stringOrDefault(row['report_comment'], ''),
      parkingPhotoUrls: _stringList(row['parking_photos']),
      photosCount: photosCount,
    );
  }

  List<String> _stringList(Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is! List ||
        value.any((item) => item is! String || item.isEmpty)) {
      throw const UserReviewsReadException(
        UserReviewsFailureKind.invalidData,
      );
    }
    return List<String>.unmodifiable(value.cast<String>());
  }

  String _stringOrDefault(Object? value, String fallback) {
    if (value == null) {
      return fallback;
    }
    if (value is String) {
      return value;
    }
    throw const UserReviewsReadException(UserReviewsFailureKind.invalidData);
  }

  String? _optionalNonEmptyString(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    throw const UserReviewsReadException(UserReviewsFailureKind.invalidData);
  }

  DateTime? _asDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    throw const UserReviewsReadException(UserReviewsFailureKind.invalidData);
  }

  int? _nullableNonNegativeInt(Object? value) {
    final parsed = _asInt(value);
    if (value != null && parsed == null) {
      return -1;
    }
    if (parsed != null && parsed < 0) {
      return -1;
    }
    return parsed;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    return null;
  }

  double? _asDouble(Object? value) {
    if (value == null) {
      return 3.0;
    }
    if (value is! num) {
      return null;
    }
    final result = value.toDouble();
    return result.isFinite ? result : null;
  }
}
