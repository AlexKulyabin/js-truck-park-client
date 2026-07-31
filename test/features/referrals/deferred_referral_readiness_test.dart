import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/referrals/deferred_referral_readiness.dart';

void main() {
  test('waits for native readiness with a bounded schedule', () async {
    var probes = 0;
    final pauses = <Duration>[];
    final readiness = DeferredReferralReadiness(
      probe: () async {
        probes += 1;
        return probes == 5;
      },
      pause: (duration) async => pauses.add(duration),
    );

    expect(await readiness.waitUntilReady(), isTrue);
    expect(probes, 5);
    expect(pauses, const [
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
    ]);
  });

  test('treats transient probe errors as not ready', () async {
    var probes = 0;
    final readiness = DeferredReferralReadiness(
      probe: () async {
        probes += 1;
        if (probes == 1) {
          throw StateError('native init in progress');
        }
        return true;
      },
      pause: (_) async {},
    );

    expect(await readiness.waitUntilReady(), isTrue);
    expect(probes, 2);
  });

  test('returns false when native SDK never becomes ready', () async {
    var probes = 0;
    final readiness = DeferredReferralReadiness(
      probe: () async {
        probes += 1;
        return false;
      },
      pause: (_) async {},
    );

    expect(await readiness.waitUntilReady(), isFalse);
    expect(probes, 5);
  });
}
