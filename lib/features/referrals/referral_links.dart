import '../deep_links/domain/deep_link_contract.dart';

const referralHostingDomain = productionHostingDomain;
const referralHostingRelayPath = productionHostingRelayPath;
const referralRoute = 'splash';

/// Builds the destination stored inside a Chottu short link.
///
/// Referral links intentionally use the same hosting relay as the existing
/// parking and shared-photo links. The relay preserves the query parameters
/// and opens `jstrackpark://js-truck-park.web.app/splash?...` when the app is
/// already installed.
Uri buildReferralDestinationUri(String referralCode) {
  return Uri.https(
    referralHostingDomain,
    referralHostingRelayPath,
    <String, String>{
      'route': referralRoute,
      'ref': referralCode.trim(),
    },
  );
}

/// Extracts a pending referral code from a resolved Chottu or hosting URL.
String? referralCodeFromUrl(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(value.trim());
  final code = uri?.queryParameters['ref']?.trim();
  return code == null || code.isEmpty ? null : code;
}

/// Returns the first referral code found in resolved or attributed URLs.
String? referralCodeFromUrls(Iterable<String?> values) {
  for (final value in values) {
    final code = referralCodeFromUrl(value);
    if (code != null) {
      return code;
    }
  }
  return null;
}
