import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/deep_links/application/incoming_app_link_coordinator.dart';

void main() {
  test('opens legacy links and persists referral codes', () async {
    final links = StreamController<Uri>();
    addTearDown(links.close);
    final locations = <String>[];
    final referralCodes = <String>[];
    final coordinator = IncomingAppLinkCoordinator(
      links: links.stream,
      openLocation: locations.add,
      persistReferralCode: referralCodes.add,
    );
    addTearDown(coordinator.dispose);

    coordinator.start();
    links.add(
      Uri.parse(
        'jstrackpark://js-truck-park.web.app/splash?ref=REF-1',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(locations, ['/splash?ref=REF-1']);
    expect(referralCodes, ['REF-1']);
  });

  test('ignores Chottu and foreign links', () async {
    final links = StreamController<Uri>();
    addTearDown(links.close);
    final locations = <String>[];
    final coordinator = IncomingAppLinkCoordinator(
      links: links.stream,
      openLocation: locations.add,
      persistReferralCode: (_) {},
    );
    addTearDown(coordinator.dispose);

    coordinator.start();
    coordinator.start();
    links
      ..add(Uri.parse('https://js-truck-park.chottu.link/referral'))
      ..add(Uri.parse('https://example.com/homePage'));
    await Future<void>.delayed(Duration.zero);

    expect(locations, isEmpty);
  });

  test('opens a cold-start initial link', () async {
    final links = StreamController<Uri>();
    addTearDown(links.close);
    final initialLink = Completer<Uri?>();
    final locations = <String>[];
    final coordinator = IncomingAppLinkCoordinator(
      links: links.stream,
      initialLink: initialLink.future,
      openLocation: locations.add,
      persistReferralCode: (_) {},
    );
    addTearDown(coordinator.dispose);

    coordinator.start();
    initialLink.complete(
      Uri.parse(
        'jstrackpark://js-truck-park.web.app/homePage'
        '?targetParkingId=parking-1&targetLat=52.1&targetLng=21.2',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      locations,
      ['/homePage?targetParkingId=parking-1&targetLat=52.1&targetLng=21.2'],
    );
  });

  test('does not open the same initial and stream link twice', () async {
    final links = StreamController<Uri>();
    addTearDown(links.close);
    final initialLink = Completer<Uri?>();
    final locations = <String>[];
    final coordinator = IncomingAppLinkCoordinator(
      links: links.stream,
      initialLink: initialLink.future,
      openLocation: locations.add,
      persistReferralCode: (_) {},
    );
    addTearDown(coordinator.dispose);
    final uri = Uri.parse(
      'jstrackpark://js-truck-park.web.app/sharedPhotoView'
      '?photoUrl=https%3A%2F%2Fexample.com%2Fphoto.jpg',
    );

    coordinator.start();
    links.add(uri);
    await Future<void>.delayed(Duration.zero);
    initialLink.complete(uri);
    await Future<void>.delayed(Duration.zero);

    expect(
      locations,
      ['/sharedPhotoView?photoUrl=https%3A%2F%2Fexample.com%2Fphoto.jpg'],
    );
  });
}
