import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/app/router/integration_route_guard.dart';

void main() {
  group('integrationReadOnlyRedirect', () {
    test('does not affect production navigation', () {
      expect(
        integrationReadOnlyRedirect(
          enabled: false,
          loggedIn: true,
          requestedPath: '/createParking',
        ),
        isNull,
      );
    });

    test('allows the bounded read-only integration routes', () {
      for (final path in integrationReadOnlyAllowedPaths) {
        expect(
          integrationReadOnlyRedirect(
            enabled: true,
            loggedIn: true,
            requestedPath: path,
          ),
          isNull,
          reason: path,
        );
      }
    });

    test('allows read-only parking photo viewers', () {
      for (final path in ['/photoDetailed', '/photoDetailedReviews']) {
        expect(
          integrationReadOnlyRedirect(
            enabled: true,
            loggedIn: true,
            requestedPath: path,
          ),
          isNull,
          reason: path,
        );
      }
    });

    test('redirects authenticated users away from write-capable routes', () {
      for (final path in [
        '/registration',
        '/createParking',
        '/reviewCreate',
        '/editProfile',
        '/parkingDetails',
      ]) {
        expect(
          integrationReadOnlyRedirect(
            enabled: true,
            loggedIn: true,
            requestedPath: path,
          ),
          '/homePage',
          reason: path,
        );
      }
    });

    test('redirects signed-out users to authentication', () {
      expect(
        integrationReadOnlyRedirect(
          enabled: true,
          loggedIn: false,
          requestedPath: '/registration',
        ),
        '/enterPhoneNumber',
      );
    });
  });
}
