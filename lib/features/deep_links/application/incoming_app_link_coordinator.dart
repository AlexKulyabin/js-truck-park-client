import 'dart:async';

import '../domain/incoming_app_link.dart';

typedef IncomingAppLinkErrorHandler = void Function(
  Object error,
  StackTrace stackTrace,
);

class IncomingAppLinkCoordinator {
  IncomingAppLinkCoordinator({
    required Stream<Uri> links,
    required void Function(String location) openLocation,
    required void Function(String referralCode) persistReferralCode,
    IncomingAppLinkErrorHandler? onError,
  })  : _links = links,
        _openLocation = openLocation,
        _persistReferralCode = persistReferralCode,
        _onError = onError;

  final Stream<Uri> _links;
  final void Function(String location) _openLocation;
  final void Function(String referralCode) _persistReferralCode;
  final IncomingAppLinkErrorHandler? _onError;

  StreamSubscription<Uri>? _subscription;

  void start() {
    if (_subscription != null) {
      return;
    }
    _subscription = _links.listen(
      handle,
      onError: _onError,
    );
  }

  bool handle(Uri uri) {
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
    final subscription = _subscription;
    _subscription = null;
    subscription?.cancel();
  }
}
