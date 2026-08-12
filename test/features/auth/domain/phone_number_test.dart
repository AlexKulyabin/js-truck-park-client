import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/auth/domain/phone_number.dart';

void main() {
  group('normalizePhoneNumberToE164', () {
    test('normalizes a formatted international number', () {
      expect(
        normalizePhoneNumberToE164('+7 700 000 00 00'),
        '+77000000000',
      );
    });

    test('converts the local leading eight convention', () {
      expect(
        normalizePhoneNumberToE164('8 999 123 45 67'),
        '+79991234567',
      );
    });

    test('converts an international 00 prefix', () {
      expect(normalizePhoneNumberToE164('0044 7700 900123'), '+447700900123');
    });

    test('rejects numbers outside E.164 length bounds', () {
      expect(normalizePhoneNumberToE164('123'), isNull);
      expect(normalizePhoneNumberToE164('1234567890123456'), isNull);
    });
  });
}
