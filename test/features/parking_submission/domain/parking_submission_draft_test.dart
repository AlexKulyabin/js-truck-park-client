import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_submission/domain/parking_submission_draft.dart';

void main() {
  test('captures the legacy create parking form fields as a typed draft', () {
    final draft = ParkingSubmissionDraft.fromLegacyForm(
      capacityText: '42',
      address: 'Warszawska 21, Poland',
      latitude: 52.1,
      longitude: 21.2,
      hasGasStation: true,
      hasShower: null,
      hasLaundry: true,
      hasHotel: null,
      hasShop: false,
      hasRecreationArea: true,
      photos: [
        ParkingSubmissionPhoto(
          name: 'first.jpg',
          bytes: Uint8List.fromList([1, 2, 3]),
          originalFilename: 'camera.jpg',
        ),
      ],
    );

    expect(draft.totalSpaces, 42);
    expect(draft.addressLower, 'warszawska 21, poland');
    expect(draft.latitude, 52.1);
    expect(draft.longitude, 21.2);
    expect(
      draft.services,
      const ParkingSubmissionServices(
        hasGasStation: true,
        hasLaundry: true,
        hasRecreationArea: true,
      ),
    );
    expect(draft.photos.single.name, 'first.jpg');
    expect(draft.photos.single.hasBytes, isTrue);
    expect(draft.isValid, isTrue);
  });

  test('keeps the legacy capacity parsing semantics', () {
    expect(
      ParkingSubmissionDraft.fromLegacyForm(
        capacityText: '12',
        address: 'A38',
        latitude: 52,
        longitude: 21,
      ).totalSpaces,
      12,
    );
    expect(
      ParkingSubmissionDraft.fromLegacyForm(
        capacityText: '',
        address: 'A38',
        latitude: 52,
        longitude: 21,
      ).totalSpaces,
      isNull,
    );
    expect(
      ParkingSubmissionDraft.fromLegacyForm(
        capacityText: '12.5',
        address: 'A38',
        latitude: 52,
        longitude: 21,
      ).totalSpaces,
      isNull,
    );
  });

  test('preserves the legacy lowercase address fallback', () {
    expect(
      ParkingSubmissionDraft.fromLegacyForm(
        capacityText: '',
        address: null,
        latitude: 52,
        longitude: 21,
      ).addressLower,
      '',
    );
    expect(
      ParkingSubmissionDraft.fromLegacyForm(
        capacityText: '',
        address: '',
        latitude: 52,
        longitude: 21,
      ).addressLower,
      '',
    );
    expect(
      ParkingSubmissionDraft.fromLegacyForm(
        capacityText: '',
        address: 'NULL',
        latitude: 52,
        longitude: 21,
      ).addressLower,
      'null',
    );
  });

  test('reports missing legacy location state before any write boundary', () {
    final draft = ParkingSubmissionDraft.fromLegacyForm(
      capacityText: '',
      address: 'null',
      latitude: null,
      longitude: null,
    );

    expect(
      draft.validationIssues,
      const [
        ParkingSubmissionValidationIssue.missingAddress,
        ParkingSubmissionValidationIssue.missingLatitude,
        ParkingSubmissionValidationIssue.missingLongitude,
      ],
    );
    expect(draft.isValid, isFalse);
  });

  test('reports impossible coordinates before any write boundary', () {
    final draft = ParkingSubmissionDraft.fromLegacyForm(
      capacityText: '',
      address: 'A38',
      latitude: 91,
      longitude: -181,
    );

    expect(
      draft.validationIssues,
      const [
        ParkingSubmissionValidationIssue.latitudeOutOfRange,
        ParkingSubmissionValidationIssue.longitudeOutOfRange,
      ],
    );
  });

  test('keeps the existing parking photo storage path convention', () {
    final photo = ParkingSubmissionPhoto(
      name: 'first.jpg',
      bytes: Uint8List.fromList([1]),
    );

    expect(
      photo.storagePath(
        parkingId: 'parking-123',
        index: 2,
        timestampMicros: 123456,
      ),
      'parkings/parking-123/2/123456.jpg',
    );
  });
}
