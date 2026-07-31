import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_details/application/parking_favorite_controller.dart';
import 'package:j_s_truck_park/features/parking_details/domain/parking_favorite_repository.dart';

class _FakeRepository implements ParkingFavoriteRepository {
  final calls = <({String parkingId, bool isFavorite})>[];
  final completions = <Completer<void>>[];
  Object? error;
  bool waitForCompletion = false;

  @override
  Future<void> setFavorite({
    required String parkingId,
    required bool isFavorite,
  }) async {
    calls.add((parkingId: parkingId, isFavorite: isFavorite));
    if (waitForCompletion) {
      final completer = Completer<void>();
      completions.add(completer);
      await completer.future;
    }
    if (error case final error?) {
      throw error;
    }
  }
}

void main() {
  test('initializes once from the server read model', () {
    final controller = ParkingFavoriteController(
      repository: _FakeRepository(),
      parkingId: 'parking-1',
    );

    controller.initialize(true);
    controller.initialize(false);

    expect(controller.state.isFavorite, isTrue);
    expect(controller.state.phase, ParkingFavoriteMutationPhase.idle);
  });

  test('optimistically adds a favorite and commits successful state', () async {
    final repository = _FakeRepository()..waitForCompletion = true;
    final controller = ParkingFavoriteController(
      repository: repository,
      parkingId: 'parking-1',
    )..initialize(false);

    final future = controller.toggle();

    expect(controller.state.isFavorite, isTrue);
    expect(controller.state.phase, ParkingFavoriteMutationPhase.updating);
    expect(
      repository.calls,
      [(parkingId: 'parking-1', isFavorite: true)],
    );

    repository.completions.single.complete();
    expect(await future, ParkingFavoriteToggleOutcome.updated);
    expect(controller.state.isFavorite, isTrue);
    expect(controller.state.phase, ParkingFavoriteMutationPhase.idle);
  });

  test('ignores repeated taps while a mutation is in progress', () async {
    final repository = _FakeRepository()..waitForCompletion = true;
    final controller = ParkingFavoriteController(
      repository: repository,
      parkingId: 'parking-1',
    )..initialize(false);

    final first = controller.toggle();
    final second = await controller.toggle();

    expect(second, ParkingFavoriteToggleOutcome.ignored);
    expect(repository.calls, hasLength(1));

    repository.completions.single.complete();
    expect(await first, ParkingFavoriteToggleOutcome.updated);
  });

  test('rolls back an optimistic add after a typed failure', () async {
    final repository = _FakeRepository()
      ..error = const ParkingFavoriteMutationException(
        ParkingFavoriteFailureKind.forbidden,
      );
    final controller = ParkingFavoriteController(
      repository: repository,
      parkingId: 'parking-1',
    )..initialize(false);

    final outcome = await controller.toggle();

    expect(outcome, ParkingFavoriteToggleOutcome.failed);
    expect(controller.state.isFavorite, isFalse);
    expect(controller.state.phase, ParkingFavoriteMutationPhase.failure);
    expect(
      controller.state.failureKind,
      ParkingFavoriteFailureKind.forbidden,
    );
  });

  test('rolls back an optimistic delete after an unknown failure', () async {
    final repository = _FakeRepository()..error = StateError('raw error');
    final controller = ParkingFavoriteController(
      repository: repository,
      parkingId: 'parking-1',
    )..initialize(true);

    final outcome = await controller.toggle();

    expect(outcome, ParkingFavoriteToggleOutcome.failed);
    expect(controller.state.isFavorite, isTrue);
    expect(controller.state.phase, ParkingFavoriteMutationPhase.failure);
    expect(
      controller.state.failureKind,
      ParkingFavoriteFailureKind.unavailable,
    );
  });

  test('does not mutate before server state has initialized the controller',
      () async {
    final repository = _FakeRepository();
    final controller = ParkingFavoriteController(
      repository: repository,
      parkingId: 'parking-1',
    );

    final outcome = await controller.toggle();

    expect(outcome, ParkingFavoriteToggleOutcome.ignored);
    expect(repository.calls, isEmpty);
  });
}
