import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_requests/data/legacy_parking_request_route_adapter.dart';
import 'package:j_s_truck_park/features/parking_requests/data/supabase_parking_requests_repository.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_summary.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_requests_repository.dart';

class _FakeDataSource implements ParkingRequestsDataSource {
  List<Map<String, dynamic>> rows = [];
  Object? error;
  String? requestedUserId;
  String? requestedStatus;

  @override
  Future<List<Map<String, dynamic>>> fetchOwnedRows({
    required String userId,
    required String status,
  }) async {
    requestedUserId = userId;
    requestedStatus = status;
    if (error case final error?) {
      throw error;
    }
    return rows;
  }
}

void main() {
  test('preserves the owner and status filters and maps a typed summary',
      () async {
    final dataSource = _FakeDataSource()
      ..rows = [
        {
          'id': 'parking-1',
          'status': 'pending',
          'address': 'Test address',
          'total_spaces': 12,
          'rating': 4,
          'has_gas_station': true,
          'has_shower': false,
          'has_laundry': true,
          'has_hotel': false,
          'has_shop': true,
          'has_recreation_area': true,
        },
      ];
    final repository = SupabaseParkingRequestsRepository(
      dataSource: dataSource,
    );

    final result = await repository.fetchOwnedRequests(
      userId: 'user-1',
      status: ParkingRequestStatus.pending,
    );

    expect(dataSource.requestedUserId, 'user-1');
    expect(dataSource.requestedStatus, 'pending');
    expect(
      result,
      const [
        ParkingRequestSummary(
          id: 'parking-1',
          status: ParkingRequestStatus.pending,
          address: 'Test address',
          totalSpaces: 12,
          rating: 4.0,
          hasGasStation: true,
          hasLaundry: true,
          hasShop: true,
          hasRecreationArea: true,
        ),
      ],
    );
  });

  test('does not query Supabase when there is no authenticated user id',
      () async {
    final dataSource = _FakeDataSource();
    final repository = SupabaseParkingRequestsRepository(
      dataSource: dataSource,
    );

    final result = await repository.fetchOwnedRequests(
      userId: '',
      status: ParkingRequestStatus.pending,
    );

    expect(result, isEmpty);
    expect(dataSource.requestedUserId, isNull);
  });

  test('rejects a row whose status does not match the requested contract',
      () async {
    final dataSource = _FakeDataSource()
      ..rows = [
        {'id': 'parking-1', 'status': 'approved'},
      ];
    final repository = SupabaseParkingRequestsRepository(
      dataSource: dataSource,
    );

    await expectLater(
      repository.fetchOwnedRequests(
        userId: 'user-1',
        status: ParkingRequestStatus.pending,
      ),
      throwsA(
        isA<ParkingRequestsReadException>().having(
          (error) => error.kind,
          'kind',
          ParkingRequestsFailureKind.invalidData,
        ),
      ),
    );
  });

  test('redacts data-source errors behind a typed unavailable failure',
      () async {
    final dataSource = _FakeDataSource()
      ..error = StateError('sensitive backend payload');
    final repository = SupabaseParkingRequestsRepository(
      dataSource: dataSource,
    );

    await expectLater(
      repository.fetchOwnedRequests(
        userId: 'user-1',
        status: ParkingRequestStatus.pending,
      ),
      throwsA(
        isA<ParkingRequestsReadException>().having(
          (error) => error.kind,
          'kind',
          ParkingRequestsFailureKind.unavailable,
        ),
      ),
    );
  });

  test('legacy route adapter keeps only fields used by detail screens', () {
    const request = ParkingRequestSummary(
      id: 'parking-1',
      status: ParkingRequestStatus.rejected,
      address: 'Test address',
      totalSpaces: 7,
      rating: 3.5,
      hasShower: true,
    );

    final row = parkingRequestToLegacyRow(request);

    expect(row.id, request.id);
    expect(row.status, 'rejected');
    expect(row.address, request.address);
    expect(row.totalSpaces, request.totalSpaces);
    expect(row.rating, request.rating);
    expect(row.hasShower, isTrue);
  });
}
