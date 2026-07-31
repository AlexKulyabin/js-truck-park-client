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

  test('refreshes the platform device id before referral processing', () {
    final source = File(
      'lib/auth/registration/registration_widget.dart',
    ).readAsStringSync();

    final deviceLookup = source.indexOf(
      'final freshDeviceId = await actions.getDeviceId()',
    );
    final processCall = source.indexOf(
      'await ProcessReferralCall.call(',
      deviceLookup,
    );

    expect(deviceLookup, greaterThanOrEqualTo(0));
    expect(processCall, greaterThan(deviceLookup));
    expect(
      source.substring(deviceLookup, processCall),
      contains("'last_device_id': registrationDeviceId"),
    );
  });

  test('waits for an in-flight short-link capture before recovery', () {
    final source = File(
      'lib/custom_code/actions/listen_chottu_link.dart',
    ).readAsStringSync();

    final pendingCapture = source.indexOf(
      'final pendingCapture = _referralLinkCaptureInFlight',
    );
    final recoveryGuard = source.indexOf(
      'if (!shouldAttemptDeferredReferralRecovery(',
      pendingCapture,
    );

    expect(pendingCapture, greaterThanOrEqualTo(0));
    expect(recoveryGuard, greaterThan(pendingCapture));
    expect(
      source.substring(pendingCapture, recoveryGuard),
      contains('await pendingCapture'),
    );
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
