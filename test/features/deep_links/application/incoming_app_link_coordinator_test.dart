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
      openReferralLink: (_) {},
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

  test('hands Chottu links to the referral owner and ignores foreign links',
      () async {
    final links = StreamController<Uri>();
    addTearDown(links.close);
    final locations = <String>[];
    final referralLinks = <Uri>[];
    final coordinator = IncomingAppLinkCoordinator(
      links: links.stream,
      openLocation: locations.add,
      openReferralLink: referralLinks.add,
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
    expect(referralLinks, [
      Uri.parse('https://js-truck-park.chottu.link/referral'),
    ]);
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
      openReferralLink: (_) {},
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

  test('hands a cold-start Chottu link to the referral owner', () async {
    final links = StreamController<Uri>();
    addTearDown(links.close);
    final initialLink = Completer<Uri?>();
    final referralLinks = <Uri>[];
    final coordinator = IncomingAppLinkCoordinator(
      links: links.stream,
      initialLink: initialLink.future,
      openLocation: (_) {},
      openReferralLink: referralLinks.add,
      persistReferralCode: (_) {},
    );
    addTearDown(coordinator.dispose);

    coordinator.start();
    initialLink.complete(
      Uri.parse('https://js-truck-park.chottu.link/cold-start'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(referralLinks, [
      Uri.parse('https://js-truck-park.chottu.link/cold-start'),
    ]);
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
      openReferralLink: (_) {},
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
