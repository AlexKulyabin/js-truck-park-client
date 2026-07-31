import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_submission/application/parking_submission_controller.dart';
import 'package:j_s_truck_park/features/parking_submission/domain/parking_submission_draft.dart';
import 'package:j_s_truck_park/features/parking_submission/domain/parking_submission_repository.dart';

class _FakeRepository implements ParkingSubmissionRepository {
  final calls = <ParkingSubmissionDraft>[];
  final completions = <Completer<ParkingSubmissionResult>>[];
  Object? error;
  bool waitForCompletion = false;

  @override
  Future<ParkingSubmissionResult> submit(ParkingSubmissionDraft draft) async {
    calls.add(draft);
    if (waitForCompletion) {
      final completer = Completer<ParkingSubmissionResult>();
      completions.add(completer);
      return completer.future;
    }
    if (error case final error?) {
      throw error;
    }
    return const ParkingSubmissionResult(parkingId: 'parking-1');
  }
}

ParkingSubmissionDraft _draft() => ParkingSubmissionDraft.fromLegacyForm(
      capacityText: '12',
      address: 'A38',
      latitude: 52,
      longitude: 21,
    );

void main() {
  test('publishes success state after a submission completes', () async {
    final repository = _FakeRepository()..waitForCompletion = true;
    final controller = ParkingSubmissionController(repository: repository);

    final future = controller.submit(_draft());

    expect(controller.state.phase, ParkingSubmissionPhase.submitting);
    expect(repository.calls, hasLength(1));

    const result = ParkingSubmissionResult(parkingId: 'parking-1');
    repository.completions.single.complete(result);

    expect(await future, ParkingSubmissionOutcome.submitted);
    expect(controller.state.phase, ParkingSubmissionPhase.success);
    expect(controller.state.result, result);
    expect(controller.state.failureKind, isNull);
  });

  test('ignores repeated submits while a submission is in progress', () async {
    final repository = _FakeRepository()..waitForCompletion = true;
    final controller = ParkingSubmissionController(repository: repository);

    final first = controller.submit(_draft());
    final second = await controller.submit(_draft());

    expect(second, ParkingSubmissionOutcome.ignored);
    expect(repository.calls, hasLength(1));

    repository.completions.single.complete(
      const ParkingSubmissionResult(parkingId: 'parking-1'),
    );
    expect(await first, ParkingSubmissionOutcome.submitted);
  });

  test('publishes typed failure state from repository exceptions', () async {
    final repository = _FakeRepository()
      ..error = const ParkingSubmissionException(
        ParkingSubmissionFailureKind.forbidden,
      );
    final controller = ParkingSubmissionController(repository: repository);

    final outcome = await controller.submit(_draft());

    expect(outcome, ParkingSubmissionOutcome.failed);
    expect(controller.state.phase, ParkingSubmissionPhase.failure);
    expect(
      controller.state.failureKind,
      ParkingSubmissionFailureKind.forbidden,
    );
    expect(controller.state.result, isNull);
  });

  test('redacts unexpected errors behind unavailable failure state', () async {
    final repository = _FakeRepository()..error = StateError('raw failure');
    final controller = ParkingSubmissionController(repository: repository);

    final outcome = await controller.submit(_draft());

    expect(outcome, ParkingSubmissionOutcome.failed);
    expect(controller.state.phase, ParkingSubmissionPhase.failure);
    expect(
      controller.state.failureKind,
      ParkingSubmissionFailureKind.unavailable,
    );
  });
}
