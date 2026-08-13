# Referral invite registration UI

## Scope

This stage makes the existing invite-link fallback understandable on the
registration screen. It changes presentation only. Chottu attribution,
Hosting routes, `FFAppState.tempReferralCode`, `process_referral`, Supabase
eligibility rules and RevenueCat products remain unchanged.

Release marker: `referral-invite-card-v1`.

## Behavior

The registration screen presents one compact card in the existing application
theme:

- no referral code: explains the subscription benefit and offers `Paste invite
  link`;
- code captured automatically: shows `Invite link found` and explains that it
  will be verified when registration finishes;
- code captured through the manual fallback: shows `Invite link added` and
  explains that the discount will be verified after registration;
- an existing link can be replaced through `Change link`.

The input sheet tells the user to paste the complete link, exposes a visible
`Paste from clipboard` action and keeps the existing validation and capture
boundary. The UI never claims that a discount is applied before
`process_referral` succeeds.

## Files

Created:

- `lib/auth/registration/referral_invite_card.dart`;
- `test/auth/referral_invite_card_test.dart`.

Changed:

- `lib/auth/registration/registration_widget.dart`;
- `lib/auth/registration/referral_link_input_sheet.dart`;
- `lib/flutter_flow/internationalization.dart`;
- `test/auth/referral_link_input_sheet_test.dart`.

## Verification

Automated:

```bash
dart format lib/auth/registration test/auth
flutter analyze
flutter test
```

The full suite passed with 386 tests. The analyzer retains 1763 pre-existing
FlutterFlow warnings and infos and reports no new compile error from this
stage.

Manual checklist:

1. Open registration without a referral and confirm the benefit and paste
   action are visible in English and Russian.
2. Open an installed-app referral link and confirm the card reports automatic
   detection without requiring a second paste.
3. On a deferred iOS install where attribution is unavailable, paste the full
   link and confirm the card reports that it was added manually.
4. Finish registration and verify `referred_by_id`/referral statistics and the
   referral subscription price through the existing flow.
5. Confirm invalid links stay in the input sheet and show a localized error.
6. Confirm light and dark themes and a small device with the keyboard open do
   not overflow.

## Rollback

Revert this stage if the registration screen overflows, automatic capture no
longer changes the visible state, the manual sheet cannot resolve an existing
Chottu link, or registration behavior changes. Rolling back the UI does not
require a Supabase, Chottu or RevenueCat rollback.
