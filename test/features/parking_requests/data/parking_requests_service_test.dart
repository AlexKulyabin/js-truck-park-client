import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/backend/schema/enums/enums.dart';
import 'package:j_s_truck_park/backend/supabase/database/database.dart';
import 'package:j_s_truck_park/features/parking_requests/data/parking_requests_service.dart';

void main() {
  group('ParkingRequestsService', () {
    test('returns empty list without querying when user id is empty', () async {
      final gateway = _FakeParkingRequestsGateway();
      final service = ParkingRequestsService(gateway: gateway);

      final result = await service.listUserRequests(
        userId: ' ',
        status: StatusParking.pending,
      );

      expect(result, isEmpty);
      expect(gateway.calls, isEmpty);
    });

    test('loads requests for normalized user id and requested status',
        () async {
      final gateway = _FakeParkingRequestsGateway(
        requests: [
          ParkingsRow({
            'id': 'parking-1',
            'created_by': 'user-1',
            'status': StatusParking.approved.name,
          }),
        ],
      );
      final service = ParkingRequestsService(gateway: gateway);

      final result = await service.listUserRequests(
        userId: ' user-1 ',
        status: StatusParking.approved,
      );

      expect(result.single.id, 'parking-1');
      expect(gateway.calls, ['user-1:approved']);
    });
  });
}

class _FakeParkingRequestsGateway implements ParkingRequestsGateway {
  _FakeParkingRequestsGateway({
    this.requests = const [],
  });

  final List<ParkingsRow> requests;
  final calls = <String>[];

  @override
  Future<List<ParkingsRow>> listUserRequests({
    required String userId,
    required StatusParking status,
  }) async {
    calls.add('$userId:${status.name}');
    return requests;
  }
}
