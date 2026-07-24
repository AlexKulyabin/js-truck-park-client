import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/create_parking2/create_parking/create_parking_widget.dart';
import 'package:j_s_truck_park/features/parking_submission/domain/parking_submission_draft.dart';
import 'package:j_s_truck_park/features/parking_submission/domain/parking_submission_repository.dart';

class _FakeParkingSubmissionRepository implements ParkingSubmissionRepository {
  @override
  Future<ParkingSubmissionResult> submit(ParkingSubmissionDraft draft) async {
    return const ParkingSubmissionResult(parkingId: 'parking-1');
  }
}

void main() {
  test('CreateParking exposes an injectable submission write boundary', () {
    final repository = _FakeParkingSubmissionRepository();

    final widget = CreateParkingWidget(
      parkingSubmissionRepository: repository,
    );

    expect(widget.parkingSubmissionRepository, same(repository));
    expect(CreateParkingWidget.routeName, 'CreateParking');
    expect(CreateParkingWidget.routePath, '/createParking');
  });

  test('CreateParking does not call generated parking writes directly',
      () async {
    final source = await File(
      'lib/create_parking2/create_parking/create_parking_widget.dart',
    ).readAsString();

    expect(source, contains('ParkingSubmissionDraft.fromLegacyForm'));
    expect(source, contains('_parkingSubmissionRepository.submit'));
    expect(source, contains('SubmittedModerationWidget'));
    expect(source, isNot(contains('ParkingsTable().insert')));
    expect(source, isNot(contains('ParkingPhotosTable().insert')));
    expect(source, isNot(contains('uploadSupabaseStorageFiles')));
    expect(source, isNot(contains('StatusParking.pending.name')));
    expect(source, isNot(contains('currentUserUid')));
    expect(source, isNot(contains('supaSerialize<DateTime>')));
  });
}
