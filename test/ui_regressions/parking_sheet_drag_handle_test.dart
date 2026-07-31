import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/parkings_details/parkings_details/parking_sheet_drag_handle.dart';

void main() {
  testWidgets('handle detects downward drag inside a vertical scroll view',
      (tester) async {
    var dismissCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 200.0),
                ParkingSheetDragHandle(
                  backgroundColor: Colors.white,
                  handleColor: Colors.grey,
                  iconColor: Colors.black,
                  onDismiss: () => dismissCount += 1,
                ),
                const SizedBox(
                  key: ValueKey<String>('parking-sheet-content'),
                  height: 800.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byKey(parkingSheetDragHandleKey),
      const Offset(0.0, 64.0),
    );
    await tester.pump();
    expect(dismissCount, 1);

    dismissCount = 0;
    await tester.drag(
      find.byKey(parkingSheetDragHandleKey),
      const Offset(0.0, -100.0),
    );
    await tester.pump();
    expect(dismissCount, 0);

    await tester.dragFrom(
      const Offset(100.0, 320.0),
      const Offset(0.0, 100.0),
    );
    await tester.pump();
    expect(dismissCount, 0);
  });

  testWidgets('close button uses the same dismiss callback', (tester) async {
    var dismissCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParkingSheetDragHandle(
            backgroundColor: Colors.white,
            handleColor: Colors.grey,
            iconColor: Colors.black,
            onDismiss: () => dismissCount += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(parkingSheetCloseButtonKey));
    expect(dismissCount, 1);
  });
}
