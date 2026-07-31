import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('profile and parking details UI regressions', () {
    test('profile loading state reserves the final header height', () {
      final source =
          File('lib/profile/profile/profile_widget.dart').readAsStringSync();

      expect(source, contains('_buildProfileHeaderLoadingCard(context)'));
      expect(source, contains('height: 170.0'));
    });

    test('parking details keeps controller data stable across tab changes', () {
      final source = File(
        'lib/parkings_details/parkings_details/parkings_details_widget.dart',
      ).readAsStringSync();

      expect(
          source, contains('late final ParkingDetailsController _controller'));
      expect(source, contains('final state = _controller.state'));
      expect(source, isNot(contains('FutureBuilder<ParkingDetails?>')));
    });

    test('parking details shows an opaque stable loading sheet', () {
      final source = File(
        'lib/parkings_details/parkings_details/parkings_details_widget.dart',
      ).readAsStringSync();

      expect(source, contains('return _buildParkingDetailsLoading(context)'));
      expect(source, contains('color: theme.primaryBackground'));
      expect(source, contains('height: 180.0'));
      expect(source, contains('_buildSheetHandle(context)'));
    });

    test('parking details separates photo scrolling from handle dismissal', () {
      final source = File(
        'lib/parkings_details/parkings_details/parkings_details_widget.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('onVerticalDragEnd: (details) async {}')));
      expect(source, isNot(contains('onVerticalDragDown')));
      expect(source, contains('_handlePhotoVerticalDrag'));
      expect(source, contains('ParkingSheetDragHandle'));
    });

    test('parking details preserves sheet scroll position across tabs', () {
      final widgetSource = File(
        'lib/parkings_details/parkings_details/parkings_details_widget.dart',
      ).readAsStringSync();
      expect(widgetSource, contains('controller: _detailsScrollController'));
      expect(widgetSource, contains('_selectTab(TabsToggle.info)'));
      expect(widgetSource, contains('_selectTab(TabsToggle.review)'));
      expect(widgetSource, contains('_selectTab(TabsToggle.photo)'));
      expect(widgetSource, contains('_preservedSheetScrollOffset'));
      expect(
        widgetSource,
        contains('minHeight: MediaQuery.sizeOf(context).height'),
      );
      expect(
          widgetSource, contains('MediaQuery.sizeOf(context).height * 0.45'));
    });

    test('parking details only dismisses from the top handle area', () {
      final source = File(
        'lib/parkings_details/parkings_details/parkings_details_widget.dart',
      ).readAsStringSync();

      expect(source, contains('ParkingSheetDragHandle'));
      expect(source, contains('ParkingSheetRouteController'));
      expect(source, contains('_dismissSheet()'));
      expect(
        source,
        isNot(contains('NotificationListener<ScrollNotification>')),
      );
    });
  });
}
