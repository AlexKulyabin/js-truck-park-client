const integrationReadOnlyAllowedPaths = <String>{
  '/',
  '/splash',
  '/onboard1',
  '/onboard2',
  '/onboard3',
  '/enterPhoneNumber',
  '/validateSmsCode',
  '/homePage',
  '/photoDetailed',
  '/photoDetailedReviews',
  '/language',
};

String? integrationReadOnlyRedirect({
  required bool enabled,
  required bool loggedIn,
  required String requestedPath,
}) {
  if (!enabled || integrationReadOnlyAllowedPaths.contains(requestedPath)) {
    return null;
  }

  return loggedIn ? '/homePage' : '/enterPhoneNumber';
}
