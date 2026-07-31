import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/flutter_flow/custom_functions.dart';

void main() {
  test('accepts an already decoded successful RPC response', () {
    expect(isReferralApiSuccess(<String, dynamic>{'success': true}), isTrue);
  });

  test('accepts a JSON encoded successful RPC response', () {
    expect(isReferralApiSuccess('{"success":true}'), isTrue);
  });

  test('rejects unsuccessful and malformed responses', () {
    expect(isReferralApiSuccess(<String, dynamic>{'success': false}), isFalse);
    expect(isReferralApiSuccess('not-json'), isFalse);
    expect(isReferralApiSuccess(null), isFalse);
  });
}
