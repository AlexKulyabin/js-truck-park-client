import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/backend/supabase/database/tables/parkings.dart';
import 'package:j_s_truck_park/features/parking_requests/data/legacy_parking_request_route_adapter.dart';
import 'package:j_s_truck_park/features/parking_requests/data/supabase_parking_request_details_repository.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_details.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_summary.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_requests_repository.dart';

class _FakeDataSource implements ParkingRequestDetailsDataSource {
  List<Map<String, dynamic>> photoRows = [];
  int reviewCount = 0;
  Object? photosError;
  Object? reviewsError;
  final photoParkingIds = <String>[];
  final reviewParkingIds = <String>[];

  @override
  Future<List<Map<String, dynamic>>> fetchPhotoRows(String parkingId) async {
    photoParkingIds.add(parkingId);
    if (photosError case final error?) {
      throw error;
    }
    return photoRows;
  }

  @override
  Future<int> fetchReviewCount(String parkingId) async {
    reviewParkingIds.add(parkingId);
    if (reviewsError case final error?) {
      throw error;
    }
    return reviewCount;
  }
}

void main() {
  test('maps ordered photo rows and preserves the parking id filter', () async {
    final dataSource = _FakeDataSource()
      ..photoRows = [
        {'id': 'photo-1', 'url': 'https://example.com/photo.jpg'},
      ];
    final repository = SupabaseParkingRequestDetailsRepository(
      dataSource: dataSource,
    );

    final photos = await repository.fetchPhotos('parking-1');

    expect(dataSource.photoParkingIds, ['parking-1']);
    expect(
      photos,
      const [
        ParkingRequestPhoto(
          id: 'photo-1',
          url: 'https://example.com/photo.jpg',
        ),
      ],
    );
  });

  test('returns the review count from the isolated read source', () async {
    final dataSource = _FakeDataSource()..reviewCount = 4;
    final repository = SupabaseParkingRequestDetailsRepository(
      dataSource: dataSource,
    );

    final count = await repository.fetchReviewCount('parking-1');

    expect(count, 4);
    expect(dataSource.reviewParkingIds, ['parking-1']);
  });

  test('never performs an unfiltered read for an empty parking id', () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseParkingRequestDetailsRepository(
      dataSource: dataSource,
    );

    expect(await repository.fetchPhotos(''), isEmpty);
    expect(await repository.fetchReviewCount(''), 0);
    expect(dataSource.photoParkingIds, isEmpty);
    expect(dataSource.reviewParkingIds, isEmpty);
  });

  test('rejects an invalid photo without exposing its payload', () async {
    final dataSource = _FakeDataSource()
      ..photoRows = [
        {'id': 'photo-1', 'url': ''},
      ];
    final repository = SupabaseParkingRequestDetailsRepository(
      dataSource: dataSource,
    );

    await expectLater(
      repository.fetchPhotos('parking-1'),
      throwsA(
        isA<ParkingRequestsReadException>().having(
          (error) => error.kind,
          'kind',
          ParkingRequestsFailureKind.invalidData,
        ),
      ),
    );
  });

  test('redacts source failures as unavailable', () async {
    final dataSource = _FakeDataSource()
      ..photosError = StateError('sensitive photo response')
      ..reviewsError = StateError('sensitive review response');
    final repository = SupabaseParkingRequestDetailsRepository(
      dataSource: dataSource,
    );

    for (final read in [
      repository.fetchPhotos('parking-1'),
      repository.fetchReviewCount('parking-1'),
    ]) {
      await expectLater(
        read,
        throwsA(
          isA<ParkingRequestsReadException>().having(
            (error) => error.kind,
            'kind',
            ParkingRequestsFailureKind.unavailable,
          ),
        ),
      );
    }
  });

  test('legacy input adapter preserves detail fields and fallback semantics',
      () {
    final row = ParkingsRow({
      'id': 'parking-1',
      'address': 'Test address',
      'total_spaces': 10,
      'rating': 4.5,
      'has_gas_station': false,
      'has_shower': true,
    });

    final details = parkingRequestFromLegacyRow(
      row,
      expectedStatus: ParkingRequestStatus.pending,
    );

    expect(details.id, 'parking-1');
    expect(details.status, ParkingRequestStatus.pending);
    expect(details.address, 'Test address');
    expect(details.totalSpaces, 10);
    expect(details.rating, 4.5);
    expect(details.hasGasStation, isFalse);
    expect(details.hasShower, isTrue);
    expect(details.hasHotel, isTrue);
  });
}
