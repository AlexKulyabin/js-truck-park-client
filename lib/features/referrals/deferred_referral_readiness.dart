typedef DeferredReferralReadinessProbe = Future<bool> Function();
typedef DeferredReferralReadinessPause = Future<void> Function(
  Duration duration,
);

class DeferredReferralReadiness {
  DeferredReferralReadiness({
    required DeferredReferralReadinessProbe probe,
    DeferredReferralReadinessPause pause = Future<void>.delayed,
    List<Duration> attemptDelays = defaultAttemptDelays,
  })  : _probe = probe,
        _pause = pause,
        _attemptDelays = List<Duration>.unmodifiable(attemptDelays);

  static const defaultAttemptDelays = <Duration>[
    Duration.zero,
    Duration(milliseconds: 250),
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];

  final DeferredReferralReadinessProbe _probe;
  final DeferredReferralReadinessPause _pause;
  final List<Duration> _attemptDelays;

  Future<bool> waitUntilReady() async {
    for (final delay in _attemptDelays) {
      if (delay > Duration.zero) {
        await _pause(delay);
      }

      try {
        if (await _probe()) {
          return true;
        }
      } catch (_) {
        // The native SDK can reject calls while Install Referrer initializes.
      }
    }

    return false;
  }
}
