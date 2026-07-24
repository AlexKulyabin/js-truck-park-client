import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/reviews/domain/user_complaint_summary.dart';
import 'package:j_s_truck_park/features/reviews/presentation/user_complaint_photo_navigation.dart';

void main() {
  test('keeps the legacy photo route query parameter contract', () {
    final reportDate = DateTime(2026, 7, 24, 12, 30);
    final params = buildComplaintPhotoQueryParameters(
      UserComplaintSummary(
        id: 4,
        parkingAddress: 'Photo parking',
        reportDate: reportDate,
        reportType: 'Report1',
        comment: 'Comment',
        parkingPhotoUrls: const ['https://example.com/parking.jpg'],
        photosCount: 5,
      ),
    );

    expect(params['photoPath'], 'https://example.com/parking.jpg');
    expect(params['index'], '0');
    expect(params['address'], 'Photo parking');
    expect(params['photoCount'], '5');
    expect(params['photoRef'], 'https://example.com/parking.jpg');
    expect(params['data'], reportDate.toString());
  });

  test('does not build photo params when the complaint has no photos', () {
    final params = buildComplaintPhotoQueryParameters(
      const UserComplaintSummary(
        id: 4,
        parkingAddress: 'Photo parking',
        reportDate: null,
        reportType: 'Report1',
        comment: 'Comment',
        parkingPhotoUrls: [],
        photosCount: null,
      ),
    );

    expect(params, isEmpty);
  });
}
