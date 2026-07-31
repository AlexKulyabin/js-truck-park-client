import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rechecks deferred attribution before processing registration', () {
    final source = File(
      'lib/auth/registration/registration_widget.dart',
    ).readAsStringSync();

    final emptyCheck = source.indexOf(
      'if (FFAppState().tempReferralCode.isEmpty)',
    );
    final recoveryCall = source.indexOf(
      'await actions.recoverChottuReferral()',
      emptyCheck,
    );
    final processCall = source.indexOf(
      'await ProcessReferralCall.call(',
      recoveryCall,
    );

    expect(emptyCheck, greaterThanOrEqualTo(0));
    expect(recoveryCall, greaterThan(emptyCheck));
    expect(processCall, greaterThan(recoveryCall));
  });

  test('splash allows the bounded deferred recovery to finish', () {
    final source = File(
      'lib/onboarding/splash/splash_widget.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('await actions.waitForReferralCode(\n          4,'),
    );
  });
}
