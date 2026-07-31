import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/referrals/referral_device_identity.dart';

void main() {
  group('referral device identity', () {
    test('accepts an Android app-scoped Android ID', () {
      expect(
        normalizeReferralDeviceId(
          platform: ReferralDevicePlatform.android,
          value: 'a1b2c3d4e5f60718',
        ),
        'a1b2c3d4e5f60718',
      );
    });

    test('rejects Android firmware build IDs', () {
      expect(
        normalizeReferralDeviceId(
          platform: ReferralDevicePlatform.android,
          value: 'TKQ1.221114.001',
        ),
        isEmpty,
      );
    });

    test('accepts an iOS identifier for vendor', () {
      expect(
        normalizeReferralDeviceId(
          platform: ReferralDevicePlatform.ios,
          value: 'A0B1C2D3-E4F5-4678-9ABC-DEF012345678',
        ),
        'A0B1C2D3-E4F5-4678-9ABC-DEF012345678',
      );
    });

    test('rejects cross-platform and fallback values', () {
      expect(
        normalizeReferralDeviceId(
          platform: ReferralDevicePlatform.ios,
          value: 'TKQ1.221114.001',
        ),
        isEmpty,
      );
      expect(
        normalizeReferralDeviceId(
          platform: ReferralDevicePlatform.android,
          value: 'error_getting_id',
        ),
        isEmpty,
      );
    });
  });
}
