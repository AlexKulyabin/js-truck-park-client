import 'package:flutter/foundation.dart';

import '../domain/parking_submission_draft.dart';
import '../domain/parking_submission_repository.dart';

enum ParkingSubmissionPhase { idle, submitting, success, failure }

enum ParkingSubmissionOutcome { submitted, ignored, failed }

@immutable
class ParkingSubmissionState {
  const ParkingSubmissionState({
    required this.phase,
    this.result,
    this.failureKind,
  });

  const ParkingSubmissionState.initial()
      : phase = ParkingSubmissionPhase.idle,
        result = null,
        failureKind = null;

  final ParkingSubmissionPhase phase;
  final ParkingSubmissionResult? result;
  final ParkingSubmissionFailureKind? failureKind;

  bool get isSubmitting => phase == ParkingSubmissionPhase.submitting;
}

class ParkingSubmissionController extends ChangeNotifier {
  ParkingSubmissionController({
    required ParkingSubmissionRepository repository,
  }) : _repository = repository;

  final ParkingSubmissionRepository _repository;

  ParkingSubmissionState _state = const ParkingSubmissionState.initial();
  bool _disposed = false;
  int _submissionGeneration = 0;

  ParkingSubmissionState get state => _state;

  Future<ParkingSubmissionOutcome> submit(ParkingSubmissionDraft draft) async {
    if (_disposed || _state.isSubmitting) {
      return ParkingSubmissionOutcome.ignored;
    }

    final generation = ++_submissionGeneration;
    _publish(
      const ParkingSubmissionState(
        phase: ParkingSubmissionPhase.submitting,
      ),
    );

    try {
      final result = await _repository.submit(draft);
      if (!_isCurrent(generation)) {
        return ParkingSubmissionOutcome.ignored;
      }
      _publish(
        ParkingSubmissionState(
          phase: ParkingSubmissionPhase.success,
          result: result,
        ),
      );
      return ParkingSubmissionOutcome.submitted;
    } on ParkingSubmissionException catch (error) {
      return _publishFailure(
        generation: generation,
        kind: error.kind,
      );
    } catch (_) {
      return _publishFailure(
        generation: generation,
        kind: ParkingSubmissionFailureKind.unavailable,
      );
    }
  }

  ParkingSubmissionOutcome _publishFailure({
    required int generation,
    required ParkingSubmissionFailureKind kind,
  }) {
    if (!_isCurrent(generation)) {
      return ParkingSubmissionOutcome.ignored;
    }
    _publish(
      ParkingSubmissionState(
        phase: ParkingSubmissionPhase.failure,
        failureKind: kind,
      ),
    );
    return ParkingSubmissionOutcome.failed;
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _submissionGeneration;

  void _publish(ParkingSubmissionState state) {
    if (_disposed) {
      return;
    }
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _submissionGeneration++;
    super.dispose();
  }
}
