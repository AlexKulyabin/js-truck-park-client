// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'dart:io' show Platform;

import 'package:chottu_link/chottu_link.dart';
import 'package:chottu_link/model/chottu_link_resolve_link.dart';
import '/features/referrals/deferred_referral_readiness.dart';
import '/features/referrals/deferred_referral_recovery.dart';
import '/features/referrals/referral_links.dart';

StreamSubscription<ResolvedLink>? _chottuLinkSubscription;
Future<bool>? _referralRecoveryInFlight;
Future<bool>? _referralLinkCaptureInFlight;
const referralLinkCaptureReleaseMarker = 'referral-link-capture-v2';

Future listenChottuLink() async {
  if (_chottuLinkSubscription != null) {
    return;
  }

  _chottuLinkSubscription = ChottuLink.onLinkReceivedWithMeta.listen((link) {
    unawaited(_captureResolvedChottuLink(link));
  });
}

/// Resolves a Chottu URL observed by the independent platform-link channel.
///
/// This is a fallback for cold starts where the native Chottu event can be
/// emitted before Dart attaches its event-stream listener.
Future<bool> captureChottuReferralUrl(String url) async {
  final inFlight = _referralLinkCaptureInFlight;
  if (inFlight != null) {
    return inFlight;
  }

  final capture = _captureChottuReferralUrl(url);
  _referralLinkCaptureInFlight = capture;
  try {
    return await capture;
  } finally {
    if (identical(_referralLinkCaptureInFlight, capture)) {
      _referralLinkCaptureInFlight = null;
    }
  }
}

Future<bool> _captureChottuReferralUrl(String url) async {
  if (_persistReferralCode(referralCodeFromUrl(url))) {
    return true;
  }
  if (!isValidReferralShortLink(url)) {
    return false;
  }

  try {
    final resolved = await _resolveShortUrl(url);
    return _persistReferralCode(
      referralCodeFromUrls([
        resolved?.link,
        resolved?.shortLink,
        resolved?.shortLinkRaw,
      ]),
    );
  } catch (error) {
    debugPrint(
      'Chottu URL capture failed '
      '[$referralLinkCaptureReleaseMarker]: ${error.runtimeType}',
    );
    return false;
  }
}

Future<bool> _captureResolvedChottuLink(ResolvedLink link) async {
  final values = [link.link, link.shortLink, link.shortLinkRaw];
  if (_persistReferralCode(referralCodeFromUrls(values))) {
    return true;
  }

  for (final value in values) {
    if (isValidReferralShortLink(value)) {
      return captureChottuReferralUrl(value!);
    }
  }
  return false;
}

Future<bool> recoverChottuReferral() async {
  final pendingCapture = _referralLinkCaptureInFlight;
  if (pendingCapture != null && await pendingCapture) {
    return true;
  }

  if (!shouldAttemptDeferredReferralRecovery(
    isAndroid: Platform.isAndroid,
    isIOS: Platform.isIOS,
    hasReferralCode: FFAppState().tempReferralCode.isNotEmpty,
  )) {
    return FFAppState().tempReferralCode.isNotEmpty;
  }

  final inFlight = _referralRecoveryInFlight;
  if (inFlight != null) {
    return inFlight;
  }

  final recovery = _recoverChottuReferral();
  _referralRecoveryInFlight = recovery;
  try {
    return await recovery;
  } finally {
    if (identical(_referralRecoveryInFlight, recovery)) {
      _referralRecoveryInFlight = null;
    }
  }
}

Future<bool> _recoverChottuReferral() async {
  try {
    final isReady = await DeferredReferralReadiness(
      probe: () async => (await ChottuLink.getApiKey()).isNotEmpty,
    ).waitUntilReady();
    if (!isReady) {
      return false;
    }

    final recovery = DeferredReferralRecovery(
      readAttribution: () async {
        final attribution = await ChottuLink.getAttributionData();
        if (attribution == null) {
          return null;
        }
        return DeferredReferralAttribution(
          isAttributed: attribution.isAttributed,
          matchFound: attribution.matchFound,
          destinationWithUtm: attribution.destinationWithUtm,
          destinationUrl: attribution.destinationUrl,
          clickedShortUrl: attribution.clickedShortUrl,
          shortUrl: attribution.shortUrl,
        );
      },
      resolveShortLink: _resolveShortUrl,
    );
    return _persistReferralCode(await recovery.recover());
  } catch (error) {
    debugPrint(
      'Chottu referral recovery failed '
      '[$deferredReferralReleaseMarker]: ${error.runtimeType}',
    );
    return false;
  }
}

bool _persistReferralCode(String? refCode) {
  if (refCode == null) {
    return false;
  }

  FFAppState().update(() {
    FFAppState().tempReferralCode = refCode;
  });
  return true;
}

Future<DeferredReferralResolvedLink?> _resolveShortUrl(String shortUrl) async {
  final completer = Completer<DeferredReferralResolvedLink?>();
  await ChottuLink.getAppLinkDataFromUrl(
    shortUrl: shortUrl,
    onSuccess: (link) {
      if (!completer.isCompleted) {
        completer.complete(
          DeferredReferralResolvedLink(
            link: link.link,
            shortLink: link.shortLink,
            shortLinkRaw: link.shortLinkRaw,
          ),
        );
      }
    },
    onError: (_) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    },
  );
  if (!completer.isCompleted) {
    completer.complete(null);
  }
  return completer.future;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
