import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/deep_links/domain/incoming_app_link.dart';

void main() {
  group('legacy custom-scheme links', () {
    test('routes a parking link and keeps only the public route contract', () {
      final link = resolveIncomingAppLink(
        Uri.parse(
          'jstrackpark://js-truck-park.web.app/homePage'
          '?targetParkingId=parking-1&targetLat=52.1&targetLng=21.2'
          '&unexpected=private',
        ),
      );

      expect(
        link?.location,
        '/homePage?targetParkingId=parking-1&targetLat=52.1&targetLng=21.2',
      );
      expect(link?.referralCode, isNull);
    });

    test('routes shared photo parameters without changing their values', () {
      final source = Uri(
        scheme: 'jstrackpark',
        host: 'js-truck-park.web.app',
        path: '/sharedPhotoView',
        queryParameters: const {
          'photoUrl': 'https://example.com/photo 1.jpg?size=large',
          'address': 'Warszawska 1',
          'date': '2026-07-29',
        },
      );

      final link = resolveIncomingAppLink(source);
      final routed = Uri.parse(link!.location);

      expect(routed.path, '/sharedPhotoView');
      expect(routed.queryParameters, source.queryParameters);
    });

    test('persists referral data before opening splash', () {
      final link = resolveIncomingAppLink(
        Uri.parse(
          'jstrackpark://js-truck-park.web.app/splash'
          '?route=splash&ref=CODE-123',
        ),
      );

      expect(link?.location, '/splash?ref=CODE-123');
      expect(link?.referralCode, 'CODE-123');
    });
  });

  group('hosting relay links', () {
    test('infers the parking route used by existing shared links', () {
      final link = resolveIncomingAppLink(
        Uri.parse(
          'https://js-truck-park.web.app/deeplink.html'
          '?targetParkingId=parking-2&targetLat=50&targetLng=19',
        ),
      );

      expect(
        link?.location,
        '/homePage?targetParkingId=parking-2&targetLat=50&targetLng=19',
      );
    });

    test('uses the explicit shared photo route', () {
      final link = resolveIncomingAppLink(
        Uri.parse(
          'https://js-truck-park.web.app/deeplink.html'
          '?route=sharedPhotoView&photoUrl=https%3A%2F%2Fexample.com%2Fp.jpg',
        ),
      );

      expect(
        link?.location,
        '/sharedPhotoView?photoUrl=https%3A%2F%2Fexample.com%2Fp.jpg',
      );
    });
  });

  group('link ownership', () {
    test('leaves Chottu links to the ChottuLink SDK', () {
      final uri = Uri.parse('https://js-truck-park.chottu.link/referral-path');

      expect(isChottuReferralLink(uri), isTrue);
      expect(
        resolveIncomingAppLink(uri),
        isNull,
      );
    });

    test('rejects foreign domains and unsupported routes', () {
      expect(
        resolveIncomingAppLink(
          Uri.parse('jstrackpark://example.com/homePage?targetParkingId=1'),
        ),
        isNull,
      );
      expect(
        resolveIncomingAppLink(
          Uri.parse('jstrackpark://js-truck-park.web.app/admin'),
        ),
        isNull,
      );
    });
  });
}
