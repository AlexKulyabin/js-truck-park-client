import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone entry navigates only after OTP request succeeds', () {
    final source = File(
      'lib/auth/enter_phone_number/enter_phone_number_widget.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('final isSent = await actions.sendOtp(phoneNumber)'),
    );
    expect(source, contains('if (!isSent)'));
    expect(
      source,
      contains('context.pushNamed(ValidateSmsCodeWidget.routeName)'),
    );
  });

  test('OTP actions use the shared E.164 normalization', () {
    final sendSource =
        File('lib/custom_code/actions/send_otp.dart').readAsStringSync();
    final verifySource =
        File('lib/custom_code/actions/verify_otp.dart').readAsStringSync();

    expect(sendSource, contains('normalizePhoneNumberToE164(rawPhoneNumber)'));
    expect(
      verifySource,
      contains('normalizePhoneNumberToE164(rawPhoneNumber)'),
    );
    expect(sendSource, isNot(contains(r'$formattedPhone')));
  });
}
