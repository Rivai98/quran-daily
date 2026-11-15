# Implementation Plan: Google Sign-In (amendment to spec 002)

**Branch**: `002-google-signin` | **Date**: 2026-11-15 | **Spec**: [spec.md](./spec.md) (User Story 5, FR-017, FR-021..FR-023)
**Constitution**: v2.4.0 (binding)

## Summary

Add "تسجيل الدخول باستخدام Google" to the auth screen using the native Google
account picker (`google_sign_in`), then exchange the Google ID token with
Supabase Auth (`signInWithIdToken`). Same verified email = one account
(Supabase automatic identity linking). First Google sign-in creates the
profile from the Google name. Google accounts cannot add a password.

## Technical Context

Flutter (Dart ^3.10.4), MVVM + Cubit, get_it, supabase_flutter, hosted Supabase
(dev `zwkvijapswwutwozbvgy`). New dependency: `google_sign_in` (v7 API:
`GoogleSignIn.instance.initialize(serverClientId: ...)`, `authenticate()`).
Config: `GOOGLE_WEB_CLIENT_ID` (and optional `GOOGLE_IOS_CLIENT_ID`) via
`--dart-define-from-file=.env`. Client IDs are public identifiers; the Google
**client secret** lives only in the Supabase dashboard (owner), never in the
app or repo. Migration range: `2026111513NNNN`.

## Constitution Check

| Principle | Compliance |
|-----------|------------|
| I Offline core | Sign-in needs network (as email/password); existing session restore unchanged |
| II Arabic/RTL | Button label and errors in ArabicStrings; RTL layout |
| III Test-first | pgTAP for the profile trigger; cubit/repository/widget tests with a fake Google client |
| IV MVVM + Cubit | `GoogleAuthClient` abstraction in data layer; AuthCubit gets `signInWithGoogle()` |
| V Simplicity | No new tables; one trigger fix |
| VI Design system | Secondary/outlined button with Google mark per brand rules; one primary per screen stays "تسجيل الدخول" |
| VII Quran integrity | N/A |
| Security | No secrets in app/repo; non-revealing errors kept (FR-008) |

Gate: PASS.

## Design

- **Trigger fix** (`handle_new_auth_user`): today it rejects users without
  `display_name` metadata, which would break Google sign-up. New rule: use
  `display_name`, else `full_name`, else `name`, else the email local part;
  trim, cap at 100 chars. Email/password behavior unchanged.
- **Data layer**: `GoogleAuthClient` (interface) + `GoogleSignInAuthClient`
  (google_sign_in impl) returning `{idToken, accessToken}` or `cancelled`.
  `AuthRepository.signInWithGoogle()` → `supabase.auth.signInWithIdToken(
  provider: OAuthProvider.google, idToken, accessToken)`. Cancel → no failure
  state. Sign-out also calls `GoogleSignIn.instance.signOut()`.
- **Cubit**: `AuthCubit.signInWithGoogle()` with loading / cancelled (back to
  idle, no banner) / failure (Arabic message) / success (existing auth gate).
- **UI**: divider "أو" + outlined Google button under the email form on both
  sign-in and sign-up modes. Generic sign-in error gets the hint "إذا كنت
  سجّلت عبر Google فاستخدم زر Google".
- **Missing config**: when `GOOGLE_WEB_CLIENT_ID` is empty the button is hidden
  (so builds without Google setup still work).

## Owner setup (blocking for the device test only)

See [google-setup.md](./google-setup.md). Code and unit tests proceed with fakes.

## Risks

- Supabase links identities by email only when the email is verified. Test
  T010 checks linking with an existing email/password account on DEV.
- Android ID-token nonce: if Supabase rejects the token for nonce, enable
  "Skip nonce check" for Google in the dashboard (documented in setup).
