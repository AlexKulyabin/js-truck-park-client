import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/parking_details/domain/parking_details.dart';
import 'package:j_s_truck_park/features/parking_details/presentation/parking_details_links.dart';
import 'package:j_s_truck_park/map/home_page/home_page_widget.dart';
import 'package:j_s_truck_park/parkings_details/photo_detailed/photo_detailed_widget.dart';
import 'package:j_s_truck_park/parkings_details/photo_detailed_reviews/photo_detailed_reviews_widget.dart';
import 'package:j_s_truck_park/parkings_details/shared_photo_view/shared_photo_view_widget.dart';

void main() {
  test('preserves the hosted parking deep-link contract', () {
    const details = ParkingDetails(
      id: 'parking-1',
      isFavorited: false,
      latitude: 52.1,
      longitude: 21.2,
    );

    expect(
      buildParkingShareUrl(details),
      'https://js-truck-park.web.app/deeplink.html'
      '?targetParkingId=parking-1&targetLat=52.1&targetLng=21.2',
    );
    expect(HomePageWidget.routeName, 'HomePage');
    expect(HomePageWidget.routePath, '/homePage');
  });

  test('preserves all existing photo viewer routes', () {
    expect(PhotoDetailedWidget.routeName, 'PhotoDetailed');
    expect(PhotoDetailedWidget.routePath, '/photoDetailed');
    expect(PhotoDetailedReviewsWidget.routeName, 'PhotoDetailedReviews');
    expect(PhotoDetailedReviewsWidget.routePath, '/photoDetailedReviews');
    expect(SharedPhotoViewWidget.routeName, 'SharedPhotoView');
    expect(SharedPhotoViewWidget.routePath, '/sharedPhotoView');
  });

  test('preserves and safely encodes the hosted photo deep-link contract', () {
    expect(
      buildSharedPhotoUrl(
        photoUrl: 'https://example.com/photo 1.jpg?size=large',
        address: 'A&B Street',
        date: '23.07.2026',
      ),
      'https://js-truck-park.web.app/deeplink.html'
      '?route=sharedPhotoView'
      '&photoUrl=https%3A%2F%2Fexample.com%2Fphoto%201.jpg%3Fsize%3Dlarge'
      '&address=A%26B%20Street'
      '&date=23.07.2026',
    );
  });
}
