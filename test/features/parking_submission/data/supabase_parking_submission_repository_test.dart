import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_submission/data/supabase_parking_submission_repository.dart';
import 'package:j_s_truck_park/features/parking_submission/domain/parking_submission_draft.dart';
import 'package:j_s_truck_park/features/parking_submission/domain/parking_submission_repository.dart';
import 'package:postgrest/postgrest.dart';

class _FakeDataSource implements ParkingSubmissionDataSource {
  final parkingPayloads = <Map<String, dynamic>>[];
  final uploadCalls = <({
    String bucketName,
    ParkingSubmissionPhoto photo,
    String storagePath,
  })>[];
  final photoPayloads = <Map<String, dynamic>>[];
  final uploadUrls = <String>[];

  String parkingId = 'parking-1';
  Object? insertParkingError;
  Object? uploadError;
  Object? insertPhotoError;

  @override
  Future<String> insertParking(Map<String, dynamic> values) async {
    parkingPayloads.add(Map<String, dynamic>.unmodifiable(values));
    if (insertParkingError case final error?) {
      throw error;
    }
    return parkingId;
  }

  @override
  Future<String> uploadPhoto({
    required String bucketName,
    required ParkingSubmissionPhoto photo,
    required String storagePath,
  }) async {
    uploadCalls.add((
      bucketName: bucketName,
      photo: photo,
      storagePath: storagePath,
    ));
    if (uploadError case final error?) {
      throw error;
    }
    if (uploadUrls.isNotEmpty) {
      return uploadUrls.removeAt(0);
    }
    return 'https://cdn.example/$storagePath';
  }

  @override
  Future<void> insertParkingPhoto(Map<String, dynamic> values) async {
    photoPayloads.add(Map<String, dynamic>.unmodifiable(values));
    if (insertPhotoError case final error?) {
      throw error;
    }
  }
}

final _createdAt = DateTime.utc(2026, 7, 24, 12, 30);

ParkingSubmissionDraft _draft({
  List<ParkingSubmissionPhoto> photos = const [],
}) =>
    ParkingSubmissionDraft.fromLegacyForm(
      capacityText: '42',
      address: 'Warszawska 21, Poland',
      latitude: 52.1,
      longitude: 21.2,
      hasGasStation: true,
      hasShower: false,
      hasLaundry: true,
      hasHotel: false,
      hasShop: true,
      hasRecreationArea: false,
      photos: photos,
    );

ParkingSubmissionPhoto _photo(String name, int byte) => ParkingSubmissionPhoto(
      name: name,
      originalFilename: name,
      bytes: Uint8List.fromList([byte]),
    );

void main() {
  test('inserts the parking with the existing generated table payload',
      () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseParkingSubmissionRepository(
      dataSource: dataSource,
      userIdProvider: () => 'user-1',
      clock: () => _createdAt,
    );

    final result = await repository.submit(_draft());

    expect(result, const ParkingSubmissionResult(parkingId: 'parking-1'));
    expect(dataSource.parkingPayloads, [
      {
        'total_spaces': 42,
        'has_gas_station': true,
        'has_shower': false,
        'has_laundry': true,
        'has_hotel': false,
        'has_shop': true,
        'has_recreation_area': false,
        'address': 'Warszawska 21, Poland',
        'latitude': 52.1,
        'longitude': 21.2,
        'address_lower': 'warszawska 21, poland',
        'created_by': 'user-1',
        'created_at': '2026-07-24T12:30:00.000Z',
        'status': 'pending',
      },
    ]);
    expect(dataSource.uploadCalls, isEmpty);
    expect(dataSource.photoPayloads, isEmpty);
  });

  test('uploads photos and inserts photo rows after parking creation',
      () async {
    final dataSource = _FakeDataSource()
      ..uploadUrls.addAll([
        'https://cdn.example/parkings/parking-1/0/1784896200000000.jpg',
        'https://cdn.example/parkings/parking-1/1/1784896200000000.jpg',
      ]);
    final repository = SupabaseParkingSubmissionRepository(
      dataSource: dataSource,
      userIdProvider: () => 'user-1',
      clock: () => _createdAt,
    );

    final result = await repository.submit(
      _draft(photos: [_photo('first.jpg', 1), _photo('second.jpg', 2)]),
    );

    expect(
      result,
      const ParkingSubmissionResult(
        parkingId: 'parking-1',
        photoUrls: [
          'https://cdn.example/parkings/parking-1/0/1784896200000000.jpg',
          'https://cdn.example/parkings/parking-1/1/1784896200000000.jpg',
        ],
      ),
    );
    expect(dataSource.uploadCalls.map((call) => call.bucketName), [
      SupabaseParkingSubmissionRepository.parkingPhotoBucket,
      SupabaseParkingSubmissionRepository.parkingPhotoBucket,
    ]);
    expect(dataSource.uploadCalls.map((call) => call.storagePath), [
      'parkings/parking-1/0/1784896200000000.jpg',
      'parkings/parking-1/1/1784896200000000.jpg',
    ]);
    expect(dataSource.photoPayloads, [
      {
        'url': 'https://cdn.example/parkings/parking-1/0/1784896200000000.jpg',
        'parking_id': 'parking-1',
        'user_id': 'user-1',
      },
      {
        'url': 'https://cdn.example/parkings/parking-1/1/1784896200000000.jpg',
        'parking_id': 'parking-1',
        'user_id': 'user-1',
      },
    ]);
  });

  test('rejects invalid drafts before any write call', () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseParkingSubmissionRepository(
      dataSource: dataSource,
      userIdProvider: () => 'user-1',
      clock: () => _createdAt,
    );

    await expectLater(
      repository.submit(
        ParkingSubmissionDraft.fromLegacyForm(
          capacityText: '',
          address: 'null',
          latitude: null,
          longitude: null,
        ),
      ),
      throwsA(
        isA<ParkingSubmissionException>().having(
          (error) => error.kind,
          'kind',
          ParkingSubmissionFailureKind.invalidInput,
        ),
      ),
    );
    expect(dataSource.parkingPayloads, isEmpty);
  });

  test('rejects an empty authenticated user before any write call', () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseParkingSubmissionRepository(
      dataSource: dataSource,
      userIdProvider: () => '',
      clock: () => _createdAt,
    );

    await expectLater(
      repository.submit(_draft()),
      throwsA(
        isA<ParkingSubmissionException>().having(
          (error) => error.kind,
          'kind',
          ParkingSubmissionFailureKind.unauthenticated,
        ),
      ),
    );
    expect(dataSource.parkingPayloads, isEmpty);
  });

  test('rejects empty photo bytes before creating a parking row', () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseParkingSubmissionRepository(
      dataSource: dataSource,
      userIdProvider: () => 'user-1',
      clock: () => _createdAt,
    );

    await expectLater(
      repository.submit(
        _draft(
          photos: [
            ParkingSubmissionPhoto(name: 'empty.jpg', bytes: Uint8List(0)),
          ],
        ),
      ),
      throwsA(
        isA<ParkingSubmissionException>().having(
          (error) => error.kind,
          'kind',
          ParkingSubmissionFailureKind.invalidInput,
        ),
      ),
    );
    expect(dataSource.parkingPayloads, isEmpty);
  });

  test('maps an RLS rejection before parking creation to forbidden', () async {
    final dataSource = _FakeDataSource()
      ..insertParkingError = const PostgrestException(
        message: 'raw policy details',
        code: '42501',
      );
    final repository = SupabaseParkingSubmissionRepository(
      dataSource: dataSource,
      userIdProvider: () => 'user-1',
      clock: () => _createdAt,
    );

    await expectLater(
      repository.submit(_draft()),
      throwsA(
        isA<ParkingSubmissionException>()
            .having(
              (error) => error.kind,
              'kind',
              ParkingSubmissionFailureKind.forbidden,
            )
            .having(
              (error) => error.toString(),
              'redacted message',
              isNot(contains('raw policy details')),
            ),
      ),
    );
  });

  test('maps photo failures after parking creation to partialFailure',
      () async {
    final dataSource = _FakeDataSource()
      ..uploadError = StateError('raw storage details');
    final repository = SupabaseParkingSubmissionRepository(
      dataSource: dataSource,
      userIdProvider: () => 'user-1',
      clock: () => _createdAt,
    );

    await expectLater(
      repository.submit(_draft(photos: [_photo('first.jpg', 1)])),
      throwsA(
        isA<ParkingSubmissionException>()
            .having(
              (error) => error.kind,
              'kind',
              ParkingSubmissionFailureKind.partialFailure,
            )
            .having(
              (error) => error.toString(),
              'redacted message',
              isNot(contains('raw storage details')),
            ),
      ),
    );
    expect(dataSource.parkingPayloads, hasLength(1));
    expect(dataSource.photoPayloads, isEmpty);
  });
}
