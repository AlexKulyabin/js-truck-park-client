import 'parking_submission_draft.dart';

enum ParkingSubmissionFailureKind {
  invalidInput,
  unauthenticated,
  forbidden,
  invalidData,
  unavailable,
  partialFailure,
}

class ParkingSubmissionException implements Exception {
  const ParkingSubmissionException(this.kind);

  final ParkingSubmissionFailureKind kind;
}

class ParkingSubmissionResult {
  const ParkingSubmissionResult({
    required this.parkingId,
    this.photoUrls = const [],
  });

  final String parkingId;
  final List<String> photoUrls;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingSubmissionResult &&
          parkingId == other.parkingId &&
          _listEquals(photoUrls, other.photoUrls);

  @override
  int get hashCode => Object.hash(parkingId, Object.hashAll(photoUrls));
}

abstract interface class ParkingSubmissionRepository {
  Future<ParkingSubmissionResult> submit(ParkingSubmissionDraft draft);
}

bool _listEquals<T>(List<T> first, List<T> second) {
  if (identical(first, second)) {
    return true;
  }
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}
