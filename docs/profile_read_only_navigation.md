# Profile read-only navigation

## Scope

The Android integration build now exposes the existing profile destinations
needed for production-parallel testing without enabling production writes:

- subscription presentation;
- parking requests and request details;
- reviews and complaints;
- favourites and the selected parking details flow.

Profile editing, parking creation, account deletion, favorite mutation,
referrals and all other write-capable routes remain blocked.

## Safety boundaries

- the PayWall uses deterministic fallback prices in integration mode and does
  not call RevenueCat during page loading;
- restore and purchase callbacks return before their external actions;
- Requests, Reviews and Favourites perform authenticated reads only;
- opening a favourite may display public parking details on Home, where the
  favorite write control remains disabled;
- production routing and RevenueCat behavior are unchanged.

## Verification

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test
flutter build apk --debug
```

## Real-device checklist

1. Open Profile from Home.
2. Open Subscription and confirm prices render.
3. Tap Restore purchases and Subscribe; no store sheet or purchase must start.
4. Open Requests, switch all tabs and open each available request detail.
5. Confirm Create parking remains unavailable in the read-only build.
6. Open Reviews and switch between Reviews and Complaints.
7. Open Favourites and select a parking.
8. Confirm Home opens that parking's details and favorite mutation remains
   disabled.
9. Return to Profile and verify theme switching and logout still work.

## Rollback

Revert this stage if a profile destination redirects unexpectedly, a
subscription action reaches RevenueCat, a production write becomes available,
request/review/favourite data is not owner-bounded, or favourite selection no
longer opens the expected parking.
