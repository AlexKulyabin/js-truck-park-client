import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the hosted iOS fallback and preserves Android attribution', () {
    final source = File(
      'lib/custom_code/actions/create_referral_link.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('androidBehaviour: CLDynamicLinkBehaviour.app'),
    );
    expect(
      source,
      contains('iosBehaviour: CLDynamicLinkBehaviour.browser'),
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
}
