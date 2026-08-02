import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses native app routing for Android and iOS attribution', () {
    final source = File(
      'lib/custom_code/actions/create_referral_link.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('androidBehaviour: CLDynamicLinkBehaviour.app'),
    );
    expect(
      source,
      contains('iosBehaviour: CLDynamicLinkBehaviour.app'),
    );
    expect(source, isNot(contains('linkName:')));
    expect(source, contains('isUsableReferralCode(referralCode)'));
    expect(source, contains('isValidReferralShortLink(link)'));
  });

  test('recovers a Chottu URL seen by the independent app-link channel', () {
    final listener = File(
      'lib/custom_code/actions/listen_chottu_link.dart',
    ).readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();

    expect(listener, contains('Future<bool> captureChottuReferralUrl'));
    expect(listener, contains('await _resolveShortUrl(url)'));
    expect(main, contains('openReferralLink: (uri)'));
    expect(
      main,
      contains('actions.captureChottuReferralUrl(uri.toString())'),
    );
  });

  test('starts Chottu attribution before other asynchronous services', () {
    final main = File('lib/main.dart').readAsStringSync();

    final chottuInit = main.indexOf('await actions.initChottuLink()');
    final supabaseInit = main.indexOf('await SupaFlow.initialize()');
    final appStateInit =
        main.indexOf('await appState.initializePersistedState()');
    final listenerInit = main.indexOf('await actions.listenChottuLink()');

    expect(chottuInit, greaterThanOrEqualTo(0));
    expect(chottuInit, lessThan(supabaseInit));
    expect(listenerInit, greaterThan(appStateInit));
    expect(main, contains('referral-ios-early-init-v1'));
  });
}
