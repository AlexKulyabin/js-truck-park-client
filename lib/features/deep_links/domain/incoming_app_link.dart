import 'deep_link_contract.dart';

class IncomingAppLink {
  const IncomingAppLink({
    required this.location,
    this.referralCode,
  });

  final String location;
  final String? referralCode;
}

const _homePath = '/homePage';
const _sharedPhotoPath = '/sharedPhotoView';
const _splashPath = '/splash';

const _allowedParameters = <String, Set<String>>{
  _homePath: {'targetParkingId', 'targetLat', 'targetLng'},
  _sharedPhotoPath: {'photoUrl', 'address', 'date'},
  _splashPath: {'ref'},
};

/// Resolves only the legacy Hosting links owned by the Flutter router.
///
/// Chottu HTTPS links intentionally return null because the ChottuLink SDK is
/// their single owner and resolves their deferred destination separately.
IncomingAppLink? resolveIncomingAppLink(Uri uri) {
  if (isChottuReferralLink(uri) || !_isLegacyHostingLink(uri)) {
    return null;
  }

  final path = _resolveRoutePath(uri);
  if (path == null) {
    return null;
  }

  final allowedKeys = _allowedParameters[path]!;
  final parameters = <String, String>{
    for (final entry in uri.queryParameters.entries)
      if (allowedKeys.contains(entry.key)) entry.key: entry.value,
  };
  final referralCode = parameters['ref']?.trim();

  return IncomingAppLink(
    location: Uri(
      path: path,
      queryParameters: parameters.isEmpty ? null : parameters,
    ).toString(),
    referralCode:
        referralCode == null || referralCode.isEmpty ? null : referralCode,
  );
}

bool isChottuReferralLink(Uri uri) =>
    uri.scheme == 'https' && uri.host == productionChottuLinkDomain;

bool _isLegacyHostingLink(Uri uri) {
  final isCustomScheme = uri.scheme == productionCustomLinkScheme;
  final isHostingRelay =
      uri.scheme == 'https' && uri.path == productionHostingRelayPath;
  return uri.host == productionHostingDomain &&
      (isCustomScheme || isHostingRelay);
}

String? _resolveRoutePath(Uri uri) {
  final directPath = _normalizeRoute(uri.path);
  if (directPath != null && uri.path != productionHostingRelayPath) {
    return directPath;
  }

  final requestedRoute = _normalizeRoute(uri.queryParameters['route']);
  if (requestedRoute != null) {
    return requestedRoute;
  }
  if (uri.queryParameters.containsKey('targetParkingId')) {
    return _homePath;
  }
  if (uri.queryParameters.containsKey('photoUrl')) {
    return _sharedPhotoPath;
  }
  if (uri.queryParameters.containsKey('ref')) {
    return _splashPath;
  }
  return null;
}

String? _normalizeRoute(String? value) {
  final normalized = value?.trim().replaceFirst(RegExp(r'^/+'), '');
  return switch (normalized) {
    'homePage' => _homePath,
    'sharedPhotoView' => _sharedPhotoPath,
    'splash' => _splashPath,
    _ => null,
  };
}
