import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/parkings_details/parkings_details/parking_sheet_route_controller.dart';

void main() {
  testWidgets('dismiss removes only the current bottom sheet route',
      (tester) async {
    final controller = ParkingSheetRouteController();
    bool? firstDismissResult;
    bool? repeatedDismissResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                const Text('Home', key: ValueKey<String>('home-content')),
                TextButton(
                  key: const ValueKey<String>('open-sheet'),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (sheetContext) => TextButton(
                        key: const ValueKey<String>('dismiss-sheet'),
                        onPressed: () {
                          firstDismissResult = controller.dismiss(sheetContext);
                          repeatedDismissResult =
                              controller.dismiss(sheetContext);
                        },
                        child: const Text('Close'),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('open-sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('dismiss-sheet')));
    await tester.pumpAndSettle();

    expect(firstDismissResult, isTrue);
    expect(repeatedDismissResult, isFalse);
    expect(find.byKey(const ValueKey<String>('dismiss-sheet')), findsNothing);
    expect(find.byKey(const ValueKey<String>('home-content')), findsOneWidget);
  });

  testWidgets('dismiss ignores a page route context', (tester) async {
    final controller = ParkingSheetRouteController();
    bool? dismissResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            key: const ValueKey<String>('dismiss-page'),
            onPressed: () => dismissResult = controller.dismiss(context),
            child: const Text('Dismiss'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('dismiss-page')));

    expect(dismissResult, isFalse);
    expect(find.byKey(const ValueKey<String>('dismiss-page')), findsOneWidget);
  });
}
