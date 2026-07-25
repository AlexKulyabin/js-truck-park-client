import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/parkings_details/shared_photo_view/shared_photo_view_widget.dart';

void main() {
  group('sharedPhotoViewDateText', () {
    test('hides missing placeholder dates', () {
      expect(sharedPhotoViewDateText(null), isNull);
      expect(sharedPhotoViewDateText(''), isNull);
      expect(sharedPhotoViewDateText('   '), isNull);
      expect(sharedPhotoViewDateText('null'), isNull);
      expect(sharedPhotoViewDateText(' NULL '), isNull);
    });

    test('keeps real date text', () {
      expect(sharedPhotoViewDateText(' 24.07.2026 '), '24.07.2026');
    });
  });
}
