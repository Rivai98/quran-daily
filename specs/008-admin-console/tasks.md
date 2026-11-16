# Tasks: App Admin Console

**Plan**: [plan.md](./plan.md). Test-first.

## Phase 1: Backend
- [x] T001 [P] pgTAP `supabase/tests/008_admin_guard_test.sql`: EVERY admin_* RPC raises `not_admin` for a normal user; works for an admin
- [x] T002 [P] pgTAP `supabase/tests/008_admin_actions_test.sql`: overview numbers on fixtures; list/search groups and users; archive/restore/delete group; remove member; transfer ownership; audit row per action; self and last-admin protections
- [x] T003 Migration `supabase/migrations/20261115150001_admin_guard_and_audit.sql`: `require_app_admin()`, `admin_is_admin()`, audit table/actions, `profiles.suspended_at`
- [x] T004 Migration `20261115150002_admin_read_rpcs.sql`: overview, list/detail groups and users, audit list
- [x] T005 Migration `20261115150003_admin_group_actions.sql`: group actions + `admin_suspend_cleanup`
- [x] T006 Edge Function `supabase/functions/admin-user-action/` (ban/unban/delete/grant/revoke) reusing `_shared` auth + audit; Deno tests
- [x] T007 Apply migrations to DEV; run ALL pgTAP: 0 failed
- [x] T008 Deploy Edge Functions (admin-create-user, admin-reset-password, admin-user-action) with `supabase functions deploy` (orchestrator, after owner approval)

## Phase 2: App
- [X] T009 [P] Data + cubit tests `test/features/admin/`
- [X] T010 `lib/features/admin/data` (RPCs + Edge Function calls)
- [X] T011 Overview screen (metric cards + 30-day chart)
- [X] T012 Groups list/search + group detail with actions (double confirm)
- [X] T013 Users list/search + user detail with actions (suspend, reset password, create, delete, admin role)
- [X] T014 Audit log screen with filter
- [X] T015 Entry "لوحة الإدارة" in حسابي visible when `admin_is_admin()`; suspended sign-in message in auth
- [X] T016 [P] Widget tests (RTL, dark, 320dp, 200%)

## Phase 3: Validation
- [ ] T017 (pending: admin path needs an owner-added admin) Emulator: admin vs normal user; delete a test group; suspend/unsuspend a test user
- [ ] T018 (pending: final re-run stopped by owner) analyze 0, all tests green, pgTAP 0 failed; validation log; merge to main

## Validation log

### 2026-11-16 (qa)
- T017 normal user on emulator-5554 (`spec_validation_test.dart` @ 28c435e): no «لوحة الإدارة» entry; pushing /admin shows the load-error panel with no data; `admin_overview` raises `not_admin`; `admin_is_admin` = false.
- Admin path NOT validated on device: it needs a row in `private.app_admins`, which only the owner can add, and no admin test account exists. Not faked. Covered by widget tests (admin entry shown/hidden, 268636e; admin screens tests) and pgTAP `008_admin_guard_test.sql` (31 passed) and `008_admin_actions_test.sql` (65 passed). Deleting a test group and suspending/unsuspending a test user from the UI remain to be done with an admin account.
- Gates on qa @ 4a49987: `flutter analyze` No issues; `flutter test` 595 passed, 0 failed.
- pgTAP (hosted DEV, `scripts/run_remote_pgtap.py`, every file in `supabase/tests`): 24 files, 593 passed, 0 failed.
- Integration tests on emulator-5554 (Android, swiftshader) @ 4a49987: group_flow, home_flow, mushaf_flow, offline_completion, portion_flow all passed.
- `integration_test/spec_validation_test.dart` passed in full @ 28c435e (log below). Its re-run in the final pass, and the screenshot tour re-run, were stopped by the owner's publish request, so they were not repeated after 92564cd/fab9d47/745f152.
