import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/backend/api_requests/api_calls.dart';
import 'package:j_s_truck_park/flutter_flow/custom_functions.dart' as functions;

void main() {
  test('preserves the five existing nearest-radius slider values', () {
    expect(functions.getMetersFromIndex(0), 5000);
    expect(functions.getMetersFromIndex(1), 10000);
    expect(functions.getMetersFromIndex(2), 50000);
    expect(functions.getMetersFromIndex(3), 100000);
    expect(functions.getMetersFromIndex(4), 150000);
    expect(functions.getMetersFromIndex(99), 5000);
  });

  test('documents dormant viewport accessor misalignment for cluster ids', () {
    final response = [
      {
        'lat': 52.0,
        'lng': 21.0,
        'count': 5,
        'id': null,
        'is_cluster': true,
      },
      {
        'lat': 52.1,
        'lng': 21.1,
        'count': 1,
        'id': 'parking-1',
        'is_cluster': false,
      },
    ];

    expect(GetParkingsByViewportCall.lat(response), [52.0, 52.1]);
    expect(GetParkingsByViewportCall.lng(response), [21.0, 21.1]);
    expect(GetParkingsByViewportCall.count(response), [5, 1]);
    expect(GetParkingsByViewportCall.iscluster(response), [true, false]);
    expect(GetParkingsByViewportCall.id(response), ['parking-1']);
  });
}
