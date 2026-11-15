# Quickstart: Validate Quran Group Reading Tracker (amended 2026-11-15)

Validation/run guide only; implementation lives in `tasks.md`.

## Prerequisites

- Flutter stable (Dart `^3.10.4`), Android emulator (API 26+) or device, iOS simulator (iOS 15+, macOS only).
- Supabase CLI v3 (installed at `%LOCALAPPDATA%\supabase-cli`, on PATH). No Docker. Owner has run `supabase login` and `supabase link --project-ref zwkvijapswwutwozbvgy` once (research R16). Every hosted CLI command requires `--remote --yes`.
- Owner-provided assets (agents must not create them):
  - `assets/fonts/` Cairo (`Cairo-Variable.ttf`) and Amiri (`Amiri-Regular.ttf`, `Amiri-Bold.ttf`) TTF files (OFL).
  - `assets/quran/quran-data.xml` (Tanzil metadata), `assets/quran/SOURCE.md`, `assets/quran/checksums.sha256`.
- `.env`/`--dart-define`: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (publishable key only; never the service key).

## Commands

### Backend Workflow (No Docker)

Because `supabase test db` requires Docker, pgTAP tests run through the repository runner:

```bash
# Run all pgTAP test files against the hosted dev project
python scripts/run_remote_pgtap.py supabase/tests/*.sql

# Or run a single pgTAP test file
python scripts/run_remote_pgtap.py supabase/tests/<file>.sql
```

Applying migrations to the remote dev database:
Do not use `supabase db push` (parallel branches push timestamps out of order, leading to `DbPushMissingLocalError`). Apply and repair status explicitly:

```bash
supabase db query --remote --yes -f supabase/migrations/<file>.sql
supabase migration repair --remote --yes --status applied <version>
```

### Flutter App & Testing

```bash
# 1. Fetch dependencies and analyze code
flutter pub get
flutter analyze

# 2. Run all unit and widget tests
flutter test

# 3. Run the app on an attached phone or emulator
flutter run -d <device-id> --dart-define-from-file=.env

# 4. Run integration tests on device/emulator
flutter test integration_test/group_flow_test.dart -d <device-id> --dart-define-from-file=.env
flutter test integration_test/offline_completion_test.dart -d <device-id> --dart-define-from-file=.env

# 5. Run the offline journey on host (no device needed)
flutter test test/integration_offline_completion_test.dart
```

All must be green before a story is marked done.

## Owner Steps Still Pending

Before public release, the project owner performs these steps:

1. **Seed First Admin**: In Supabase SQL editor, register the admin user ID (from spec 002 quickstart):
   ```sql
   insert into private.app_admins (user_id) values ('<your auth user id>');
   ```
2. **Deploy Edge Functions**: Deploy the admin Edge Functions with the `--use-api` flag:
   ```bash
   supabase functions deploy admin-create-user --use-api
   supabase functions deploy admin-reset-password --use-api
   ```
3. **Review Quran Metadata**: Review [`assets/quran/SOURCE.md`](../../assets/quran/SOURCE.md) and confirm license attribution and checksums before release.

## Scenarios

1. **Create & start** (US2 + US4 invite join; before US4 lands, add the second member with `supabase/tests/helpers/seed_members.sql`): Sign up (spec 002) → S1 empty → "أنشئ مجموعة" → group forming, you are seat 1 → second test user joins via invite code → owner "ابدأ الختمة" with juz 1. Expect: seat 1 juz 1, seat 2 juz 2, 28 juz "متاح".
2. **Rotation** (US2, SC-005): advance the DB clock / call `generate_due_group_days()` for the next date. Expect seat 1 juz 2, seat 2 juz 3; with start juz 30 seat 1 wraps to juz 1 next day. Every day has 30 distinct juz.
3. **Dashboard** (US1): my juz card visible without scrolling at 360×640; counts and percentage correct; juz 30 shows دعاء الختم note.
4. **Complete / undo / offline** (US3): complete → count +1; undo with confirm → −1; airplane mode → complete → own status updates, banner shown → reconnect → server shows completed.
5. **Late & close** (US3): move to grace → pending shows فائت; complete → قُرئ متأخرًا; after close → completion rejected with explanation.
6. **Join paths** (US4): auto-accept join immediate; approval join shows "بانتظار القبول من مالك المجموعة"; "انضم لأي مجموعة ناقصة" picks per rule; full group blocked; private group hidden from discovery but joinable by code.
7. **Volunteer race** (US5, SC-006): two clients volunteer for the same available juz → exactly one succeeds; next day volunteer row not carried.
8. **Manage** (US6): approve/reject, group full on approve, move seat (effective next day), supervisor permissions limited, remove member → seat available, owner leave blocked until transfer, regenerate invite invalidates old code, removed user rejoin → pending.
9. **History** (US7): 7 seeded days; members see summaries + own result only; owner/supervisor see per-seat misses; full khatma with late reads marked.
10. **Privacy** (SC-010): non-member cannot read members/progress via any RPC or table select.
11. **Design/a11y** (SC-011): every screen passes widget tests in RTL, 200% text, dark theme; no raw colors/sizes in `lib/features` (lint test).
12. **Quran metadata** (Principle VII): `SOURCE.md` matches plan.md "Quran Content Source"; checksum test passes; altering one byte of `quran-data.xml` fails the test.

## Compliance review

| Check | Found | Fixed |
|---|---|---|
| T114 design system, Arabic copy, and screen variants | No forbidden raw color, font size, radius, physical left/right inset, or alignment literals. Hard-coded screen copy existed in create group, group settings, and forming group views. Member, join-request, and group-settings screens lacked full variant coverage. | Moved copy to `ArabicStrings`; added RTL, 200% text, dark, and 320dp coverage. Existing shared design-system components and one-primary-action screen patterns remain in use. |
| T115 Quran content integrity and source access | Static surah/range examples existed in a localization test and the design mock; `QuranMetadataRepository` is the only application code that reads Quran metadata. The checksum test verifies the bundled XML bytes. | Replaced examples with repository-driven test data and neutral mock placeholders. Kept Quran source files unchanged; checksum test passes. |

## Validation log

### Date: 2026-11-15

| Target / Suite | Command | Result | Notes |
|---|---|---|---|
| Static Analysis | `flutter analyze` | PASS (0 issues) | Clean run |
| Unit & Widget Tests | `flutter test` | PASS (292 passing) | 100% passing across all feature suites |
| pgTAP DB Tests | `python scripts/run_remote_pgtap.py supabase/tests/*.sql` | PASS (10 files green) | All 10 test suites passed against dev DB |
| Integration: Group Flow | `flutter test integration_test/group_flow_test.dart -d <device-id> --dart-define-from-file=.env` | pending | Orchestrator fills on attached device |
| Integration: Offline Completion | `flutter test integration_test/offline_completion_test.dart -d <device-id> --dart-define-from-file=.env` | pending | Orchestrator fills on attached device |
| Integration: Host Offline Journey | `flutter test test/integration_offline_completion_test.dart` | PASS | Verified in flutter test suite |
| Android Device / Emulator | Acceptance scenarios 1–12 | pending | Orchestrator fills on device |
| iOS Simulator | Acceptance scenarios 1–12 | pending | Orchestrator fills on simulator |
