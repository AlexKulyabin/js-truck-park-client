import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/referrals/referral_links.dart';

void main() {
  group('referral hosting destination', () {
    test('uses the existing hosting relay and the splash route', () {
      final uri = buildReferralDestinationUri('CODE-123');

      expect(uri.scheme, 'https');
      expect(uri.host, 'js-truck-park.web.app');
      expect(uri.path, '/deeplink.html');
      expect(uri.queryParameters, <String, String>{
        'route': 'splash',
        'ref': 'CODE-123',
      });
    });

    test('encodes referral codes as query parameters', () {
      final uri = buildReferralDestinationUri('code + slash/value');

      expect(uri.queryParameters['ref'], 'code + slash/value');
    });
  });

  group('referral code parsing', () {
    test('reads a resolved Chottu destination', () {
      expect(
        referralCodeFromUrl(
          'https://js-truck-park.web.app/deeplink.html?route=splash&ref=ABC',
        ),
        'ABC',
      );
    });

    test('reads the existing custom-scheme hosting relay result', () {
      expect(
        referralCodeFromUrl(
          'jstrackpark://js-truck-park.web.app/splash?route=splash&ref=ABC',
        ),
        'ABC',
      );
    });

    test('ignores links without a referral code', () {
      expect(
        referralCodeFromUrl(
          'https://js-truck-park.web.app/deeplink.html?targetParkingId=42',
        ),
        isNull,
      );
    });

    test('uses a deferred destination when earlier candidates have no code',
        () {
      expect(
        referralCodeFromUrls([
          null,
          'https://js-truck-park.chottu.link/short-path',
          'https://js-truck-park.web.app/deeplink.html?route=splash&ref=DEFERRED',
        ]),
        'DEFERRED',
      );
    });
  });
}
