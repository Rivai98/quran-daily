# Tasks: Google Sign-In (amendment to spec 002)

**Plan**: [google-plan.md](./google-plan.md). Test-first.

## Phase 1: Backend
- [ ] T001 pgTAP `supabase/tests/002_google_profile_test.sql`: insert auth user with only `full_name` / only `name` / only email → profile created with that name; `display_name` still wins; >100 chars capped; existing email/password case unchanged
- [ ] T002 Migration `supabase/migrations/20261115130001_google_profile_name.sql`: replace `handle_new_auth_user` with the fallback rule; apply to DEV (`db query -f` + `migration repair`); run all pgTAP files: 0 failed

## Phase 2: App
- [ ] T003 [P] Add `google_sign_in` to pubspec; `GOOGLE_WEB_CLIENT_ID` / `GOOGLE_IOS_CLIENT_ID` in `lib/core/config` env reading and `.env.example` (empty values)
- [ ] T004 [P] Tests `test/features/auth/data/google_sign_in_test.dart`: repository calls signInWithIdToken with tokens; cancel returns cancelled; missing idToken → failure; sign-out signs out of Google too
- [ ] T005 `lib/features/auth/data/`: `GoogleAuthClient` + `GoogleSignInAuthClient`, `AuthRepository.signInWithGoogle()`
- [ ] T006 [P] Cubit tests `test/features/auth/cubit/auth_cubit_google_test.dart`: loading → success; cancel → idle no failure; failure → Arabic message
- [ ] T007 `AuthCubit.signInWithGoogle()`
- [ ] T008 [P] Widget tests `test/features/auth/view/auth_google_button_test.dart`: button visible in both modes when configured, hidden when not, RTL, 200% text, dark, 320dp; generic error shows the Google hint
- [ ] T009 Auth screen: "أو" divider + outlined Google button; strings in ArabicStrings; DI registration
- [ ] T010 Android/iOS wiring: iOS `GIDClientID` + reversed client ID URL scheme in Info.plist (from config); nothing secret committed

## Phase 3: Validation (orchestrator + owner)
- [ ] T011 Owner completes [google-setup.md](./google-setup.md)
- [ ] T012 On the phone: new Google account → profile with Google name; sign out/in again; same email as an existing email/password account → one profile (check `auth.identities`); cancel → back to auth screen with no error
- [ ] T013 `flutter analyze` 0, `flutter test` green, pgTAP all 0 failed; record results; merge to `main`

## Validation log
_(filled at T013)_
