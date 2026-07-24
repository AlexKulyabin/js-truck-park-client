import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/favorites/application/favorites_controller.dart';
import 'package:j_s_truck_park/features/favorites/domain/favorite_parking_summary.dart';
import 'package:j_s_truck_park/features/favorites/domain/favorites_repository.dart';

class _FakeRepository implements FavoritesRepository {
  final userIds = <String>[];
  final completions = <Completer<List<FavoriteParkingSummary>>>[];
  List<FavoriteParkingSummary> result = [];
  Object? error;
  bool waitForCompletion = false;

  @override
  Future<List<FavoriteParkingSummary>> fetchOwnedFavorites(
    String userId,
  ) async {
    userIds.add(userId);
    if (waitForCompletion) {
      final completer = Completer<List<FavoriteParkingSummary>>();
      completions.add(completer);
      return completer.future;
    }
    if (error case final error?) {
      throw error;
    }
    return result;
  }
}

const _favorite = FavoriteParkingSummary(
  favoriteRecordId: 10,
  parkingId: 'parking-1',
  address: 'Test address',
  latitude: 52.1,
  longitude: 21.2,
);

void main() {
  test('loads an immutable list for the authenticated user', () async {
    final repository = _FakeRepository()..result = const [_favorite];
    final controller = FavoritesController(
      repository: repository,
      userId: 'user-1',
    );

    await controller.load();

    expect(repository.userIds, ['user-1']);
    expect(controller.state.phase, FavoritesLoadPhase.loaded);
    expect(controller.state.favorites, const [_favorite]);
    expect(
      () => controller.state.favorites.add(_favorite),
      throwsUnsupportedError,
    );
  });

  test('ignores a stale response after retry', () async {
    final repository = _FakeRepository()..waitForCompletion = true;
    final controller = FavoritesController(
      repository: repository,
      userId: 'user-1',
    );

    final first = controller.load();
    final second = controller.retry();
    repository.completions[1].complete(const [_favorite]);
    await second;
    repository.completions[0].complete(const []);
    await first;

    expect(controller.state.phase, FavoritesLoadPhase.loaded);
    expect(controller.state.favorites, const [_favorite]);
  });

  test('publishes a typed failure without retaining stale data', () async {
    final repository = _FakeRepository()
      ..error = const FavoritesReadException(
        FavoritesFailureKind.invalidData,
      );
    final controller = FavoritesController(
      repository: repository,
      userId: 'user-1',
    );

    await controller.load();

    expect(controller.state.phase, FavoritesLoadPhase.failure);
    expect(controller.state.favorites, isEmpty);
    expect(
      controller.state.failureKind,
      FavoritesFailureKind.invalidData,
    );
  });
}
