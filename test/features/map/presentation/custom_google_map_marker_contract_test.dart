import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/custom_code/widgets/custom_google_map.dart';
import 'package:j_s_truck_park/features/map/presentation/map_marker_item.dart';

void main() {
  test('CustomGoogleMap exposes an immutable typed marker boundary', () {
    const markers = [
      MapMarkerItem(
        id: 'parking-1',
        latitude: 52.1,
        longitude: 21.2,
        count: 1,
        isCluster: false,
      ),
    ];

    const widget = CustomGoogleMap(
      initialLat: 52,
      initialLng: 21,
      initialZoom: 13,
      markers: markers,
    );

    expect(widget.markers, same(markers));
    expect(widget.markers.single.id, 'parking-1');
  });

  test('CustomGoogleMap no longer parses dynamic marker maps', () {
    final source = File(
      'lib/custom_code/widgets/custom_google_map.dart',
    ).readAsStringSync();

    expect(source, contains('final List<MapMarkerItem> markers'));
    expect(source, isNot(contains('List<dynamic>? markerData')));
    expect(source, isNot(contains("item['lat']")));
    expect(source, isNot(contains("item['is_cluster']")));
  });
}
