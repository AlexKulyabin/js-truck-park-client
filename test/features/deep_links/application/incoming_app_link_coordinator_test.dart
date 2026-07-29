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
}
