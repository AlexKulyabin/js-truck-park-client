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
  });
}
