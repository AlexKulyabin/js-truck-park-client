import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_details/presentation/parking_details_dismissal.dart';

void main() {
  group('shouldDismissParkingDetails', () {
    test('dismisses a downward swipe', () {
      expect(
        shouldDismissParkingDetails(primaryVelocity: 500),
        isTrue,
      );
    });

    test('keeps the sheet open after an upward swipe', () {
      expect(
        shouldDismissParkingDetails(primaryVelocity: -500),
        isFalse,
      );
    });

    test('keeps the sheet open without downward velocity', () {
      expect(
        shouldDismissParkingDetails(primaryVelocity: 0),
        isFalse,
      );
      expect(
        shouldDismissParkingDetails(primaryVelocity: null),
        isFalse,
      );
    });
  });
}
