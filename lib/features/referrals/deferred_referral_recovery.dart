import 'referral_links.dart';

const deferredReferralReleaseMarker = 'referral-deferred-recovery-v4';

bool shouldAttemptDeferredReferralRecovery({
  required bool isAndroid,
  required bool isIOS,
  required bool hasReferralCode,
}) =>
    (isAndroid || isIOS) && !hasReferralCode;

class DeferredReferralAttribution {
  const DeferredReferralAttribution({
    required this.isAttributed,
    required this.matchFound,
    this.destinationWithUtm,
    this.destinationUrl,
    this.clickedShortUrl,
    this.shortUrl,
  });

  final bool isAttributed;
  final bool matchFound;
  final String? destinationWithUtm;
  final String? destinationUrl;
  final String? clickedShortUrl;
  final String? shortUrl;
}

class DeferredReferralResolvedLink {
  const DeferredReferralResolvedLink({
    this.link,
    this.shortLink,
    this.shortLinkRaw,
  });

  final String? link;
  final String? shortLink;
  final String? shortLinkRaw;
}

typedef DeferredAttributionReader = Future<DeferredReferralAttribution?>
    Function();
typedef DeferredShortLinkResolver = Future<DeferredReferralResolvedLink?>
    Function(String shortUrl);
typedef DeferredRecoveryPause = Future<void> Function(Duration duration);

class DeferredReferralRecovery {
  DeferredReferralRecovery({
    required DeferredAttributionReader readAttribution,
    required DeferredShortLinkResolver resolveShortLink,
    DeferredRecoveryPause pause = Future<void>.delayed,
    List<Duration> attemptDelays = defaultAttemptDelays,
  })  : _readAttribution = readAttribution,
        _resolveShortLink = resolveShortLink,
        _pause = pause,
        _attemptDelays = List<Duration>.unmodifiable(attemptDelays);

  static const defaultAttemptDelays = <Duration>[
    Duration.zero,
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
  ];

  final DeferredAttributionReader _readAttribution;
  final DeferredShortLinkResolver _resolveShortLink;
  final DeferredRecoveryPause _pause;
  final List<Duration> _attemptDelays;

  Future<String?> recover() async {
    for (final delay in _attemptDelays) {
      if (delay > Duration.zero) {
        await _pause(delay);
      }

      final attribution = await _readAttribution();
      if (attribution == null) {
        continue;
      }

      final directCode = referralCodeFromUrls([
        attribution.destinationWithUtm,
        attribution.destinationUrl,
        attribution.clickedShortUrl,
        attribution.shortUrl,
      ]);
      if (directCode != null) {
        return directCode;
      }

      final shortUrl = _firstNonEmpty([
        attribution.clickedShortUrl,
        attribution.shortUrl,
      ]);
      if (shortUrl == null) {
        continue;
      }

      final resolved = await _resolveShortLink(shortUrl);
      final resolvedCode = referralCodeFromUrls([
        resolved?.link,
        resolved?.shortLink,
        resolved?.shortLinkRaw,
      ]);
      if (resolvedCode != null) {
        return resolvedCode;
      }
    }

    return null;
  }
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final normalized = value?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}
