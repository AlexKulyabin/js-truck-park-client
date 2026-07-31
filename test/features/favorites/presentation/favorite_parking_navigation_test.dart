import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/favorites/domain/favorite_parking_summary.dart';
import 'package:j_s_truck_park/features/favorites/presentation/favorite_parking_navigation.dart';

void main() {
  test('preserves the map target query parameter contract', () {
    const favorite = FavoriteParkingSummary(
      favoriteRecordId: 10,
      parkingId: 'parking-1',
      address: 'Test address',
      latitude: 52.1,
      longitude: 21.2,
    );

    expect(
      buildFavoriteParkingQueryParameters(favorite),
      {
        'targetParkingId': 'parking-1',
        'targetLat': '52.1',
        'targetLng': '21.2',
      },
    );
  });
}
