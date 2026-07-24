import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/geocoding/domain/reverse_geocoding_repository.dart';

void main() {
  test('exposes only the formatted address at the domain boundary', () {
    const address = ReverseGeocodedAddress(
      formattedAddress: 'Warszawska 1, Poland',
    );

    expect(address.formattedAddress, 'Warszawska 1, Poland');
  });

  test('keeps failure kinds redacted and transport independent', () {
    const error = ReverseGeocodingException(
      ReverseGeocodingFailureKind.unavailable,
    );

    expect(error.kind, ReverseGeocodingFailureKind.unavailable);
    expect(error.toString(), isNot(contains('Google')));
  });
}
