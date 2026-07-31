import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_requests/domain/parking_request_summary.dart';

void main() {
  test('maps only the confirmed Supabase status values', () {
    expect(
      ParkingRequestStatus.tryParse('pending'),
      ParkingRequestStatus.pending,
    );
    expect(
      ParkingRequestStatus.tryParse('approved'),
      ParkingRequestStatus.approved,
    );
    expect(
      ParkingRequestStatus.tryParse('rejected'),
      ParkingRequestStatus.rejected,
    );
    expect(ParkingRequestStatus.tryParse('unknown'), isNull);
    expect(ParkingRequestStatus.tryParse(null), isNull);
  });

  test('keeps status storage values aligned with the database enum', () {
    expect(
      ParkingRequestStatus.values.map((status) => status.storageValue),
      ['pending', 'approved', 'rejected'],
    );
  });
}
