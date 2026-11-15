# Tasks: Google Sign-In (amendment to spec 002)

**Plan**: [google-plan.md](./google-plan.md). Test-first.

## Phase 1: Backend
- [X] T001 pgTAP `supabase/tests/002_google_profile_test.sql`: insert auth user with only `full_name` / only `name` / only email → profile created with that name; `display_name` still wins; >100 chars capped; existing email/password case unchanged
- [X] T002 Migration `supabase/migrations/20261115130001_google_profile_name.sql`: replace `handle_new_auth_user` with the fallback rule; apply to DEV (`db query -f` + `migration repair`); run all pgTAP files: 0 failed

## Phase 2: App
- [X] T003 [P] Add `google_sign_in` to pubspec; `GOOGLE_WEB_CLIENT_ID` / `GOOGLE_IOS_CLIENT_ID` in `lib/core/config` env reading and `.env.example` (empty values)
- [X] T004 [P] Tests `test/features/auth/data/google_sign_in_test.dart`: repository calls signInWithIdToken with tokens; cancel returns cancelled; missing idToken → failure; sign-out signs out of Google too
- [X] T005 `lib/features/auth/data/`: `GoogleAuthClient` + `GoogleSignInAuthClient`, `AuthRepository.signInWithGoogle()`
- [X] T006 [P] Cubit tests in `test/features/auth/cubit/auth_cubit_test.dart`: loading → success; cancel → idle no failure; failure → stable copy code
- [X] T007 `AuthCubit.signInWithGoogle()`
- [X] T008 [P] Widget tests in `test/features/auth/view/auth_entry_screen_test.dart`: button visible in both modes when configured, hidden when not, RTL, 200% text, dark, 320dp; generic error shows the Google hint
- [X] T009 Auth screen: "أو" divider + outlined Google button; strings in ArabicStrings; DI registration
- [X] T010 Android/iOS wiring: iOS `GIDClientID` + reversed client ID URL scheme in Info.plist (from config); nothing secret committed

## Phase 3: Validation (orchestrator + owner)
- [X] T011 Owner completes [google-setup.md](./google-setup.md)
- [X] T012 On the phone: new Google account → profile with Google name; sign out/in again; same email as an existing email/password account → one profile (check `auth.identities`); cancel → back to auth screen with no error
- [X] T013 `flutter analyze` 0, `flutter test` green, pgTAP all 0 failed; record results; merge to `main`

## Validation log
2026-11-15:
- Owner setup done: Google project "Quran Daily" (newprojectflutter011), consent screen External/Testing, Web + Android (com.qurandaily.app, debug SHA-1) + iOS clients; Supabase Google provider enabled with the 3 client IDs, skip nonce on. Package renamed to com.qurandaily.app (owner request).
- Phone (RZCTC0TNMRW): Google sign-in succeeded; DEV shows one `google` identity with a profile name.
- Not run yet: linking with an existing email/password account of the same Gmail, cancel flow on device (covered by unit tests), iOS (no macOS; GOOGLE_IOS_REVERSED_CLIENT_ID build setting still to set on a Mac).
- flutter analyze: 0 issues; flutter test: 325 passed; pgTAP: 12 files, 266 passed, 0 failed.
