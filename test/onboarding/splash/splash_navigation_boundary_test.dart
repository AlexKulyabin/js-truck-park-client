import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('replaces splash with Home for an already authenticated user', () {
    final source = File(
      'lib/onboarding/splash/splash_widget.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('context.goNamed(HomePageWidget.routeName);'),
    );
    expect(
      source,
      isNot(contains('context.pushNamed(HomePageWidget.routeName);')),
    );
  });
}
