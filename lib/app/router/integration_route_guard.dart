const integrationReadOnlyAllowedPaths = <String>{
  '/',
  '/splash',
  '/onboard1',
  '/onboard2',
  '/onboard3',
  '/enterPhoneNumber',
  '/validateSmsCode',
  '/homePage',
  '/profile',
  '/payWall',
  '/requests',
  '/moderationParking',
  '/acceptedParking',
  '/rejectedParking',
  '/reviewsAndComplaints',
  '/favourites',
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
