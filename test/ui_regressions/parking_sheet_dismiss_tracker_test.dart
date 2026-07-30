import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/parkings_details/parkings_details/parking_sheet_dismiss_tracker.dart';

void main() {
  group('ParkingSheetDismissTracker', () {
    test('reaches the dismiss threshold across downward drag updates', () {
      final tracker = ParkingSheetDismissTracker(threshold: 72.0);

      expect(tracker.registerDragDelta(30.0), isFalse);
      expect(tracker.registerDragDelta(41.0), isFalse);
      expect(tracker.registerDragDelta(1.0), isTrue);
    });

    test('does not treat upward drag as a dismiss gesture', () {
      final tracker = ParkingSheetDismissTracker(threshold: 72.0);

      expect(tracker.registerDragDelta(-100.0), isFalse);
      expect(tracker.registerDragDelta(-1.0), isFalse);
    });

    test('reset starts a new gesture', () {
      final tracker = ParkingSheetDismissTracker(threshold: 72.0);

      expect(tracker.registerDragDelta(60.0), isFalse);
      tracker.reset();
      expect(tracker.registerDragDelta(20.0), isFalse);
    });
  });
}
