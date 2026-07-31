enum ReferralDevicePlatform {
  android,
  ios,
  other,
}

const referralDeviceIdentityReleaseMarker = 'referral-device-identity-v1';

final _iosIdentifierPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);
final _androidIdentifierPattern =
    RegExp(r'^[0-9a-f]{16}$', caseSensitive: false);

String normalizeReferralDeviceId({
  required ReferralDevicePlatform platform,
  required String? value,
}) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) {
    return '';
  }

  switch (platform) {
    case ReferralDevicePlatform.android:
      return _androidIdentifierPattern.hasMatch(normalized) &&
              normalized.toLowerCase() != '9774d56d682e549c'
          ? normalized
          : '';
    case ReferralDevicePlatform.ios:
      return _iosIdentifierPattern.hasMatch(normalized) ? normalized : '';
    case ReferralDevicePlatform.other:
      return '';
  }
}
