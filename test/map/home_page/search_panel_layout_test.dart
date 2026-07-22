import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/map/home_page/search_panel_layout.dart';

void main() {
  group('searchPanelMaxHeight', () {
    test('uses 80 percent of the screen when the keyboard is closed', () {
      expect(
        searchPanelMaxHeight(screenHeight: 800, keyboardInset: 0),
        640,
      );
    });

    test('uses only visible height when the keyboard is open', () {
      expect(
        searchPanelMaxHeight(screenHeight: 800, keyboardInset: 300),
        500,
      );
    });

    test('never returns a negative height', () {
      expect(
        searchPanelMaxHeight(screenHeight: 800, keyboardInset: 900),
        0,
      );
    });
  });
}
