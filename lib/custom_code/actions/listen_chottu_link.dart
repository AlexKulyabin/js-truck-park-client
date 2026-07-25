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
import '/features/referrals/referral_links.dart';

StreamSubscription<ResolvedLink>? _chottuLinkSubscription;

Future listenChottuLink() async {
  if (_chottuLinkSubscription != null) {
    return;
  }

  _chottuLinkSubscription = ChottuLink.onLinkReceivedWithMeta.listen((link) {
    _persistReferralCode(
      referralCodeFromUrls([
        link.link,
        link.shortLink,
        link.shortLinkRaw,
      ]),
    );
  });
}

Future recoverChottuReferral() async {
  if (!Platform.isAndroid || FFAppState().tempReferralCode.isNotEmpty) {
    return;
  }

  try {
    final attribution = await ChottuLink.getAttributionData();
    if (attribution == null) {
      return;
    }

    final attributedCode = referralCodeFromUrls([
      attribution.destinationWithUtm,
      attribution.destinationUrl,
      attribution.clickedShortUrl,
      attribution.shortUrl,
    ]);
    if (_persistReferralCode(attributedCode)) {
      return;
    }

    final shortUrl = _firstNonEmpty([
      attribution.clickedShortUrl,
      attribution.shortUrl,
    ]);
    if (shortUrl == null) {
      return;
    }

    final resolvedLink = await _resolveShortUrl(shortUrl);
    _persistReferralCode(
      referralCodeFromUrls([
        resolvedLink?.link,
        resolvedLink?.shortLink,
        resolvedLink?.shortLinkRaw,
      ]),
    );
  } catch (error) {
    debugPrint('Chottu referral recovery failed: ${error.runtimeType}');
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

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final normalized = value?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

Future<ResolvedLink?> _resolveShortUrl(String shortUrl) async {
  final completer = Completer<ResolvedLink?>();
  await ChottuLink.getAppLinkDataFromUrl(
    shortUrl: shortUrl,
    onSuccess: (link) {
      if (!completer.isCompleted) {
        completer.complete(link);
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
