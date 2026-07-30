import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pay wall price loading', () {
    test('shows compact spinners until smart subscription prices load', () {
      final source = File('lib/subscription/pay_wall/pay_wall_widget.dart')
          .readAsStringSync();

      expect(source, contains('_buildSubscriptionPrice('));
      expect(source, contains('if (!_model.isPageload)'));
      expect(source, contains('CircularProgressIndicator'));
      expect(source, contains('strokeWidth: 2.0'));
      expect(
          source,
          isNot(contains('if (_model.isPageload)\n'
              '                                            Text(')));
    });
  });
}
