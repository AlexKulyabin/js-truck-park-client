import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/user_complaint_summary.dart';
import '../domain/user_review_summary.dart';
import '../domain/user_reviews_repository.dart';

enum UserReviewsTab { reviews, complaints }

enum UserReviewsLoadPhase { idle, loading, loaded, failure }

@immutable
class UserReviewsListState<T> {
  const UserReviewsListState({
    required this.phase,
    required this.items,
    this.failureKind,
  });

  const UserReviewsListState.initial()
      : phase = UserReviewsLoadPhase.idle,
        items = const [],
        failureKind = null;

  final UserReviewsLoadPhase phase;
  final List<T> items;
  final UserReviewsFailureKind? failureKind;
}

@immutable
class UserReviewsState {
  const UserReviewsState({
    required this.selectedTab,
    required this.reviews,
    required this.complaints,
  });

  const UserReviewsState.initial()
      : selectedTab = UserReviewsTab.reviews,
        reviews = const UserReviewsListState<UserReviewSummary>.initial(),
        complaints = const UserReviewsListState<UserComplaintSummary>.initial();

  final UserReviewsTab selectedTab;
  final UserReviewsListState<UserReviewSummary> reviews;
  final UserReviewsListState<UserComplaintSummary> complaints;

  UserReviewsState copyWith({
    UserReviewsTab? selectedTab,
    UserReviewsListState<UserReviewSummary>? reviews,
    UserReviewsListState<UserComplaintSummary>? complaints,
  }) =>
      UserReviewsState(
        selectedTab: selectedTab ?? this.selectedTab,
        reviews: reviews ?? this.reviews,
        complaints: complaints ?? this.complaints,
      );
}

class UserReviewsController extends ChangeNotifier {
  UserReviewsController({
    required UserReviewsRepository repository,
    required String userId,
    Duration loadTimeout = const Duration(seconds: 15),
  })  : _repository = repository,
        _userId = userId,
        _loadTimeout = loadTimeout;

  final UserReviewsRepository _repository;
  final String _userId;
  final Duration _loadTimeout;

  UserReviewsState _state = const UserReviewsState.initial();
  int _reviewsGeneration = 0;
  int _complaintsGeneration = 0;
  bool _disposed = false;

  UserReviewsState get state => _state;

  Future<void> loadSelected() {
    return switch (_state.selectedTab) {
      UserReviewsTab.reviews => loadReviews(),
      UserReviewsTab.complaints => loadComplaints(),
    };
  }

  Future<void> selectTab(UserReviewsTab tab) async {
    if (_state.selectedTab != tab) {
      _publish(_state.copyWith(selectedTab: tab));
    }

    final listState = switch (tab) {
      UserReviewsTab.reviews => _state.reviews,
      UserReviewsTab.complaints => _state.complaints,
    };

    if (listState.phase == UserReviewsLoadPhase.idle) {
      await loadSelected();
    }
  }

  Future<void> loadReviews() async {
    final generation = ++_reviewsGeneration;
    _publish(
      _state.copyWith(
        reviews: const UserReviewsListState<UserReviewSummary>(
          phase: UserReviewsLoadPhase.loading,
          items: [],
        ),
      ),
    );

    try {
      final reviews =
          await _repository.fetchOwnedReviews(_userId).timeout(_loadTimeout);
      if (_disposed || generation != _reviewsGeneration) {
        return;
      }
      _publish(
        _state.copyWith(
          reviews: UserReviewsListState<UserReviewSummary>(
            phase: UserReviewsLoadPhase.loaded,
            items: List.unmodifiable(reviews),
          ),
        ),
      );
    } on UserReviewsReadException catch (error) {
      _publishReviewsFailure(generation, error.kind);
    } catch (_) {
      _publishReviewsFailure(
        generation,
        UserReviewsFailureKind.unavailable,
      );
    }
  }

  Future<void> loadComplaints() async {
    final generation = ++_complaintsGeneration;
    _publish(
      _state.copyWith(
        complaints: const UserReviewsListState<UserComplaintSummary>(
          phase: UserReviewsLoadPhase.loading,
          items: [],
        ),
      ),
    );

    try {
      final complaints =
          await _repository.fetchOwnedComplaints(_userId).timeout(_loadTimeout);
      if (_disposed || generation != _complaintsGeneration) {
        return;
      }
      _publish(
        _state.copyWith(
          complaints: UserReviewsListState<UserComplaintSummary>(
            phase: UserReviewsLoadPhase.loaded,
            items: List.unmodifiable(complaints),
          ),
        ),
      );
    } on UserReviewsReadException catch (error) {
      _publishComplaintsFailure(generation, error.kind);
    } catch (_) {
      _publishComplaintsFailure(
        generation,
        UserReviewsFailureKind.unavailable,
      );
    }
  }

  Future<void> retrySelected() => loadSelected();

  void _publishReviewsFailure(
    int generation,
    UserReviewsFailureKind kind,
  ) {
    if (_disposed || generation != _reviewsGeneration) {
      return;
    }
    _publish(
      _state.copyWith(
        reviews: UserReviewsListState<UserReviewSummary>(
          phase: UserReviewsLoadPhase.failure,
          items: const [],
          failureKind: kind,
        ),
      ),
    );
  }

  void _publishComplaintsFailure(
    int generation,
    UserReviewsFailureKind kind,
  ) {
    if (_disposed || generation != _complaintsGeneration) {
      return;
    }
    _publish(
      _state.copyWith(
        complaints: UserReviewsListState<UserComplaintSummary>(
          phase: UserReviewsLoadPhase.failure,
          items: const [],
          failureKind: kind,
        ),
      ),
    );
  }

  void _publish(UserReviewsState state) {
    if (_disposed) {
      return;
    }
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _reviewsGeneration++;
    _complaintsGeneration++;
    super.dispose();
  }
}
