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

    test('parking details keeps data future stable across tab changes', () {
      final source = File(
        'lib/parkings_details/parkings_details/parkings_details_widget.dart',
      ).readAsStringSync();

      expect(source, contains('future: _model.parkingDetailsFuture'));
      expect(source, isNot(contains('future: _parkingDetailsService')));
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

    test('parking details photo/header zones do not close on vertical drags',
        () {
      final source = File(
        'lib/parkings_details/parkings_details/parkings_details_widget.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('onVerticalDragEnd: (details) async {}')));
      expect(source, isNot(contains('onVerticalDragDown')));
      expect(
        source,
        isNot(contains('onVerticalDragEnd: (details) async {\n'
            '                                Navigator.pop(context);')),
      );
    });

    test('parking details preserves sheet scroll position across tabs', () {
      final widgetSource = File(
        'lib/parkings_details/parkings_details/parkings_details_widget.dart',
      ).readAsStringSync();
      final modelSource = File(
        'lib/parkings_details/parkings_details/parkings_details_model.dart',
      ).readAsStringSync();

      expect(
          widgetSource, contains('controller: _model.sheetScrollController'));
      expect(widgetSource, contains('_selectTab(TabsToggle.info)'));
      expect(widgetSource, contains('_selectTab(TabsToggle.review)'));
      expect(widgetSource, contains('_selectTab(TabsToggle.photo)'));
      expect(widgetSource, contains('preservedSheetScrollOffset'));
      expect(
          widgetSource, contains('MediaQuery.sizeOf(context).height * 0.45'));
      expect(modelSource, contains('ScrollController? sheetScrollController'));
    });

    test('parking details only dismisses from the top handle area', () {
      final source = File(
        'lib/parkings_details/parkings_details/parkings_details_widget.dart',
      ).readAsStringSync();

      expect(source, contains('ParkingSheetDragHandle('));
      expect(source, contains('_sheetRouteController.dismiss(context)'));
      expect(source, contains('_dismissSheet()'));
      expect(
        source,
        isNot(contains('NotificationListener<ScrollNotification>')),
      );
      expect(source, isNot(contains('Navigator.pop(context)')));
    });
  });
}
