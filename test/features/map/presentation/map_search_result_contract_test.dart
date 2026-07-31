import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/map/presentation/map_search_result_item.dart';

void main() {
  test('search result exposes only the typed presentation contract', () {
    const result = MapSearchResultItem(
      id: 'parking-1',
      latitude: 52.1,
      longitude: 21.2,
      address: 'Test address',
    );

    expect(result.id, 'parking-1');
    expect(result.latitude, 52.1);
    expect(result.longitude, 21.2);
    expect(result.address, 'Test address');
  });

  test('map screen models no longer store dynamic search results', () {
    final homeModel = File(
      'lib/map/home_page/home_page_model.dart',
    ).readAsStringSync();
    final selectModel = File(
      'lib/create_parking2/select_parking/select_parking_model.dart',
    ).readAsStringSync();

    for (final source in [homeModel, selectModel]) {
      expect(source, contains('List<MapSearchResultItem> searchResults'));
      expect(source, isNot(contains('List<dynamic> searchResults')));
      expect(source, isNot(contains('Function(dynamic)')));
    }
  });
}
