import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/referrals/deferred_referral_recovery.dart';

void main() {
  test('attempts recovery on Android and iOS only when no code exists', () {
    expect(
      shouldAttemptDeferredReferralRecovery(
        isAndroid: true,
        isIOS: false,
        hasReferralCode: false,
      ),
      isTrue,
    );
    expect(
      shouldAttemptDeferredReferralRecovery(
        isAndroid: false,
        isIOS: true,
        hasReferralCode: false,
      ),
      isTrue,
    );
    expect(
      shouldAttemptDeferredReferralRecovery(
        isAndroid: false,
        isIOS: true,
        hasReferralCode: true,
      ),
      isFalse,
    );
    expect(
      shouldAttemptDeferredReferralRecovery(
        isAndroid: false,
        isIOS: false,
        hasReferralCode: false,
      ),
      isFalse,
    );
  });

  test('retries attribution with the bounded recovery schedule', () async {
    var reads = 0;
    final pauses = <Duration>[];
    final recovery = DeferredReferralRecovery(
      readAttribution: () async {
        reads += 1;
        if (reads < 5) {
          return null;
        }
        return const DeferredReferralAttribution(
          isAttributed: true,
          matchFound: true,
          destinationUrl:
              'https://js-truck-park.web.app/deeplink.html?route=splash&ref=RETRY-CODE',
        );
      },
      resolveShortLink: (_) async => null,
      pause: (duration) async => pauses.add(duration),
    );

    expect(await recovery.recover(), 'RETRY-CODE');
    expect(reads, 5);
    expect(pauses, const [
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ]);
  });

  test('keeps checking after an early organic attribution result', () async {
    var reads = 0;
    final recovery = DeferredReferralRecovery(
      readAttribution: () async {
        reads += 1;
        if (reads == 3) {
          return const DeferredReferralAttribution(
            isAttributed: true,
            matchFound: true,
            destinationUrl:
                'https://js-truck-park.web.app/deeplink.html?route=splash&ref=LATE-CODE',
          );
        }
        return const DeferredReferralAttribution(
          isAttributed: false,
          matchFound: false,
        );
      },
      resolveShortLink: (_) async => null,
      pause: (_) async {},
    );

    expect(await recovery.recover(), 'LATE-CODE');
    expect(reads, 3);
  });

  test('resolves the attributed short link when destination is absent',
      () async {
    final resolvedUrls = <String>[];
    final recovery = DeferredReferralRecovery(
      readAttribution: () async => const DeferredReferralAttribution(
        isAttributed: true,
        matchFound: true,
        clickedShortUrl: 'https://js-truck-park.chottu.link/invite',
      ),
      resolveShortLink: (shortUrl) async {
        resolvedUrls.add(shortUrl);
        return const DeferredReferralResolvedLink(
          link:
              'https://js-truck-park.web.app/deeplink.html?route=splash&ref=RESOLVED',
        );
      },
      pause: (_) async {},
    );

    expect(await recovery.recover(), 'RESOLVED');
    expect(resolvedUrls, ['https://js-truck-park.chottu.link/invite']);
  });

  test('returns null after the bounded retry schedule', () async {
    var reads = 0;
    final recovery = DeferredReferralRecovery(
      readAttribution: () async {
        reads += 1;
        return null;
      },
      resolveShortLink: (_) async => null,
      pause: (_) async {},
    );

    expect(await recovery.recover(), isNull);
    expect(reads, 5);
  });
}
