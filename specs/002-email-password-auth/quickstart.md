# Quickstart: Validate Email and Password Authentication

## Prerequisites

- Flutter SDK compatible with Dart `^3.10.4`.
- A disposable local/test Supabase project; never run destructive auth tests against production.
- Project URL and publishable/anonymous key supplied through `SUPABASE_URL` and `SUPABASE_ANON_KEY` dart defines.
- Server-side service secret configured only for Edge Functions.
- Email/password enabled and email confirmation disabled in the test project.
- One test administrator seeded in the protected administrator table.

## Setup

```powershell
flutter pub get
flutter analyze
flutter test
```

Run the app with test-project public configuration:

```powershell
flutter run --dart-define=SUPABASE_URL=<test-url> --dart-define=SUPABASE_ANON_KEY=<test-publishable-key>
```

Do not place a service-role/secret key in this command.

## Test-First Order

1. Write failing validation tests for email normalization, blank display name, minimum password length, and confirmation mismatch.
2. Write failing repository tests for signup, login, profile load, auth events, session restoration, sign-out, and safe failure mapping.
3. Write failing AuthCubit tests for bootstrap, mode changes, duplicate-submit protection, success/failure, expiry, and missing profile.
4. Write failing Arabic widget tests for both modes, field behavior, progress, errors, accessibility, and exclusions.
5. Write failing route-gate tests before implementing private-route protection.
6. Write migration/function integration tests before applying backend behavior.
7. Implement the smallest change needed for each red test, then refactor only while green.

## Mobile Acceptance Journeys

### Self-registration

1. Open Create Account.
2. Enter display name, unused email, and matching password of at least eight characters.
3. Submit once, including a rapid double-tap attempt.

**Expected**: One account and exactly one profile exist; one submission runs; no email/code is sent; the app reaches group selection within the performance target.

### Login and session restoration

1. Sign out, then sign in with the created email/password.
2. Close and reopen the app normally.

**Expected**: Login succeeds, profile loads, and restart restores the signed-in destination without credential re-entry or private-content flash.

### Invalid and offline login

1. Try an incorrect password.
2. Repeat while offline.

**Expected**: The invalid-credential message does not confirm whether the email exists; offline state gives a recoverable Arabic error; no private route opens.

### Logout and route protection

1. Sign out from settings.
2. Press system back and attempt a private deep link.

**Expected**: Auth Entry remains visible and no private widget/data is exposed.

### Accessibility

Test Login and Create Account at 320 logical-pixel width and 200% text scale with the keyboard open.

**Expected**: No overflow; all fields/actions remain reachable; semantic labels and 48x48 targets are present; email reads LTR within the RTL page.

### Exclusion audit

**Expected**: No Google, OTP, email-verification/recovery, administrator console, notification permission, notification token, or notification-setting behavior exists.

## Backend Contract Validation

Validate against [supabase-backend.md](contracts/supabase-backend.md):

- Self-registration and administrator creation each produce exactly one profile.
- Concurrent duplicate email creation produces one identity/profile.
- Invalid/blank display name fails cleanly.
- Anonymous profile access fails.
- Owner profile read/update succeeds; cross-user access and client insert/delete fail.
- Normal users cannot grant administrator authority.
- Unauthenticated privileged calls return 401 and normal users receive 403.
- Authorized administrator creation sends no email and creates a profile.
- Authorized reset makes the previous password fail and replacement password succeed.
- Responses, logs, and audit records contain no password, token, or service secret.

## Final Verification

```powershell
flutter analyze
flutter test
flutter test integration_test
```

Run device integration journeys on both an iOS 15+ simulator and Android API 26+ emulator/device. Record evidence for the measurable outcomes in [spec.md](spec.md), especially route blocking, profile cardinality, password replacement, session restoration, and the three-second normal-connectivity target.
