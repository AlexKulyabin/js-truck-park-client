import 'dart:async';

import '../domain/incoming_app_link.dart';

const deepLinkColdStartReleaseMarker = 'deep-link-cold-start-v1';

typedef IncomingAppLinkErrorHandler = void Function(
  Object error,
  StackTrace stackTrace,
);

class IncomingAppLinkCoordinator {
  IncomingAppLinkCoordinator({
    required Stream<Uri> links,
    required void Function(String location) openLocation,
    required void Function(Uri uri) openReferralLink,
    required void Function(String referralCode) persistReferralCode,
    Future<Uri?>? initialLink,
    IncomingAppLinkErrorHandler? onError,
  })  : _links = links,
        _openLocation = openLocation,
        _openReferralLink = openReferralLink,
        _persistReferralCode = persistReferralCode,
        _initialLink = initialLink,
        _onError = onError;

  final Stream<Uri> _links;
  final void Function(String location) _openLocation;
  final void Function(Uri uri) _openReferralLink;
  final void Function(String referralCode) _persistReferralCode;
  final Future<Uri?>? _initialLink;
  final IncomingAppLinkErrorHandler? _onError;

  StreamSubscription<Uri>? _subscription;
  final Set<String> _linksSeenWhileInitialPending = {};
  bool _initialLinkPending = false;
  bool _active = false;

  void start() {
    if (_subscription != null) {
      return;
    }
    _active = true;
    _initialLinkPending = _initialLink != null;
    _subscription = _links.listen(
      _handleStreamLink,
      onError: _onError,
    );
    final initialLink = _initialLink;
    if (initialLink != null) {
      unawaited(_handleInitialLink(initialLink));
    }
  }

  void _handleStreamLink(Uri uri) {
    if (_initialLinkPending) {
      _linksSeenWhileInitialPending.add(uri.toString());
    }
    handle(uri);
  }

  Future<void> _handleInitialLink(Future<Uri?> initialLink) async {
    try {
      final uri = await initialLink;
      if (!_active || uri == null) {
        return;
      }
      if (!_linksSeenWhileInitialPending.contains(uri.toString())) {
        handle(uri);
      }
    } catch (error, stackTrace) {
      _onError?.call(error, stackTrace);
    } finally {
      _initialLinkPending = false;
      _linksSeenWhileInitialPending.clear();
    }
  }

  bool handle(Uri uri) {
    if (isChottuReferralLink(uri)) {
      _openReferralLink(uri);
      return true;
    }

    final link = resolveIncomingAppLink(uri);
    if (link == null) {
      return false;
    }
    final referralCode = link.referralCode;
    if (referralCode != null) {
      _persistReferralCode(referralCode);
    }
    _openLocation(link.location);
    return true;
  }

  void dispose() {
    _active = false;
    final subscription = _subscription;
    _subscription = null;
    subscription?.cancel();
  }
}
