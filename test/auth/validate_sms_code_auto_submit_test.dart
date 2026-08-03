import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('submits a complete SMS code through the shared verification path', () {
    final source = File(
      'lib/auth/validate_sms_code/validate_sms_code_widget.dart',
    ).readAsStringSync();

    expect(source, contains('onCompleted: _verifyCode'));
    expect(source, contains('Future<void> _verifyCode(String code)'));
    expect(source, contains("if (_isVerifying || code.length != 6)"));
    expect(RegExp(r'actions\.verifyOtp\(').allMatches(source), hasLength(1));
  });
}
