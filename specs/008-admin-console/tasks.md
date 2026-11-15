# Tasks: App Admin Console

**Plan**: [plan.md](./plan.md). Test-first.

## Phase 1: Backend
- [ ] T001 [P] pgTAP `supabase/tests/008_admin_guard_test.sql`: EVERY admin_* RPC raises `not_admin` for a normal user; works for an admin
- [ ] T002 [P] pgTAP `supabase/tests/008_admin_actions_test.sql`: overview numbers on fixtures; list/search groups and users; archive/restore/delete group; remove member; transfer ownership; audit row per action; self and last-admin protections
- [ ] T003 Migration `supabase/migrations/20261115150001_admin_guard_and_audit.sql`: `require_app_admin()`, `admin_is_admin()`, audit table/actions, `profiles.suspended_at`
- [ ] T004 Migration `20261115150002_admin_read_rpcs.sql`: overview, list/detail groups and users, audit list
- [ ] T005 Migration `20261115150003_admin_group_actions.sql`: group actions + `admin_suspend_cleanup`
- [ ] T006 Edge Function `supabase/functions/admin-user-action/` (ban/unban/delete/grant/revoke) reusing `_shared` auth + audit; Deno tests
- [ ] T007 Apply migrations to DEV; run ALL pgTAP: 0 failed
- [ ] T008 Deploy Edge Functions (admin-create-user, admin-reset-password, admin-user-action) with `supabase functions deploy` (orchestrator, after owner approval)

## Phase 2: App
- [ ] T009 [P] Data + cubit tests `test/features/admin/`
- [ ] T010 `lib/features/admin/data` (RPCs + Edge Function calls)
- [ ] T011 Overview screen (metric cards + 30-day chart)
- [ ] T012 Groups list/search + group detail with actions (double confirm)
- [ ] T013 Users list/search + user detail with actions (suspend, reset password, create, delete, admin role)
- [ ] T014 Audit log screen with filter
- [ ] T015 Entry "لوحة الإدارة" in حسابي visible when `admin_is_admin()`; suspended sign-in message in auth
- [ ] T016 [P] Widget tests (RTL, dark, 320dp, 200%)

## Phase 3: Validation
- [ ] T017 Emulator: admin vs normal user; delete a test group; suspend/unsuspend a test user
- [ ] T018 analyze 0, all tests green, pgTAP 0 failed; validation log; merge to main

## Validation log
_(filled at T018)_
