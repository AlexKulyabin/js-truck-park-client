import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/flutter_flow/lat_lng.dart';
import 'package:j_s_truck_park/map/home_page/user_location_target.dart';

void main() {
  group('isUsableUserLocation', () {
    test('rejects missing and fallback origin coordinates', () {
      expect(isUsableUserLocation(null), isFalse);
      expect(isUsableUserLocation(const LatLng(0.0, 0.0)), isFalse);
    });

    test('rejects coordinates outside valid bounds', () {
      expect(isUsableUserLocation(const LatLng(91.0, 0.0)), isFalse);
      expect(isUsableUserLocation(const LatLng(0.0, -181.0)), isFalse);
    });

    test('accepts valid device coordinates', () {
      expect(isUsableUserLocation(const LatLng(52.2297, 21.0122)), isTrue);
    });
  });

  group('shouldApplyFreshUserLocation', () {
    test('ignores an invalid fresh fallback', () {
      expect(
        shouldApplyFreshUserLocation(
          previous: const LatLng(52.2297, 21.0122),
          fresh: const LatLng(0.0, 0.0),
        ),
        isFalse,
      );
    });

    test('applies a valid changed fresh coordinate', () {
      expect(
        shouldApplyFreshUserLocation(
          previous: const LatLng(52.2297, 21.0122),
          fresh: const LatLng(52.2300, 21.0130),
        ),
        isTrue,
      );
    });
  });
}
