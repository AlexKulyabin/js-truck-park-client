# Splash back navigation bugfix

## Scope

This bounded UI fix changes only the successful startup transition for an
already authenticated user. Supabase, authentication, onboarding, referral and
deep-link contracts are unchanged.

## Root cause

Splash opened Home with `pushNamed`, leaving the completed Splash route below
Home in the Android navigation stack. Pressing the system Back button on Home
popped Home and exposed the old Splash instance. Its one-time post-frame startup
callback had already run, so the visible Splash had no remaining transition and
appeared frozen.

## Change

Splash now opens Home with `goNamed`. Home replaces the startup route, so the
system Back action cannot reveal a completed Splash screen. Navigation to Home
from ordinary application screens is not changed.

## Verification

- the boundary test requires `goNamed(HomePageWidget.routeName)` in Splash and
  rejects the previous `pushNamed` call;
- on Android, start as an authenticated user, wait for Home, then press Back;
  Splash must not appear.

## Rollback

Revert this fix if authenticated startup no longer reaches Home or if referral
startup parameters stop being processed before the transition.
