# Map interaction bugfix

## Scope

This bounded fix addresses two regressions found during the Android real-device
smoke test:

- the Home profile button appeared inert in the integration build;
- parking details closed after both upward and downward handle swipes.

No Supabase schema, RPC, storage, authentication, deep-link, sharing or
production release contract changed.

## Changes

- `/profile` is part of the integration read-only route allowlist;
- the destructive account-deletion action returns before its API call in
  integration builds;
- write-capable profile child routes remain blocked by the existing route
  guard;
- parking details dismiss only when vertical drag velocity is downward;
- the same direction rule is used by the handle and the no-photo placeholder.
- the photo gallery no longer captures vertical drags, so an upward drag over a
  photo expands the scrollable details content while horizontal paging and
  photo taps remain unchanged.
- the gallery now forwards vertical drag deltas to the details scroll
  controller explicitly, rather than relying on implicit gesture-arena
  propagation through the horizontal photo pager;
- tab changes and favorite mutations retain the already loaded parking details;
  only the affected local state changes, so the bottom sheet shell does not
  disappear behind a full-screen loading state.

## Automated verification

- route-guard regression test for the Profile shell;
- integration boundary test for account-deletion isolation;
- unit tests for down, up, zero and missing drag velocity;
- widget test proving an upward fling keeps details open and a downward fling
  closes them;
- widget test proving an upward drag that starts on the gallery changes the
  details scroll offset;
- widget tests proving tab changes and a delayed favorite mutation do not
  reload or hide the details shell;
- complete Flutter test suite;
- analyzer and Android debug build.

## Real-device checklist

1. Open Home and tap the profile/menu button.
2. Confirm Profile opens and shows the signed-in user's data.
3. Open Delete account and confirm its destructive confirmation does nothing in
   `JS Truck Park Dev`.
4. Return to Home and open a parking marker.
5. Swipe upward directly over a visible photo; details must expand.
6. Swipe horizontally over the photo; the gallery must change pages.
7. Tap the photo; the full photo view must still open.
8. Swipe the top handle upward; details must remain visible.
9. Swipe the top handle downward; details must close.
10. Repeat both handle gestures on a parking without photos.
11. Confirm the close icon still closes details.
12. Switch between Info, Reviews and Photo; the sheet must stay continuously
    visible.
13. Add and remove the parking from Favorites; the sheet must stay visible
    while the button shows progress.

## Rollback

Revert this bugfix if Profile exposes a production write in integration mode,
the profile button redirects unexpectedly, upward drag dismisses details, or
downward drag/close icon no longer dismisses details.
