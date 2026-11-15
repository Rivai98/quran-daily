# Implementation Plan: App Admin Console

**Branch**: `008-admin-console` | **Date**: 2026-11-15 | **Spec**: [spec.md](./spec.md)
**Constitution**: v2.4.0 (binding)

## Technical Context

Flutter MVVM + Cubit; hosted Supabase. Database RPCs (SECURITY DEFINER,
`set search_path=''`) for reads and group actions, guarded by
`public.require_app_admin()` which checks `private.app_admins`. Auth actions
(ban/unban, delete user, create user, reset password) via Edge Functions using
the service role server-side (existing `admin-create-user`,
`admin-reset-password`; new `admin-user-action` for ban/unban/delete/grant/
revoke). Migration range `2026111515NNNN`.

## Constitution Check

| Principle | Compliance |
|-----------|------------|
| I Offline core | Admin console is online-only (clear offline state); core app unaffected |
| II Arabic/RTL | All copy in ArabicStrings |
| III Test-first | pgTAP: every admin RPC refuses non-admins; Edge Function unit tests; cubit/widget tests |
| IV MVVM + Cubit | AdminOverviewCubit, AdminGroupsCubit, AdminUsersCubit, AdminAuditCubit |
| VI Design system | Danger buttons + double confirm for destructive actions |
| Security | Service key only in Edge Functions env; audit everything; self/last-admin protections |

Gate: PASS.

## RPCs

- `admin_is_admin() → boolean` (safe for any authenticated user; drives the entry).
- `admin_overview() → jsonb` metrics of US1 incl. 30-day series.
- `admin_list_groups(p_query, p_status, p_limit, p_offset)`, `admin_group_detail(p_group_id)`.
- `admin_archive_group`, `admin_restore_group`, `admin_delete_group`, `admin_remove_member`, `admin_transfer_ownership`, `admin_regenerate_invite`.
- `admin_list_users(p_query, p_status, p_limit, p_offset)` (emails from auth.users), `admin_user_detail(p_user_id)`.
- `admin_list_audit(p_action, p_limit, p_offset)`.
- Audit: extend `private.admin_auth_audit.action` check to the new actions (or new `private.admin_audit` table).
- Suspension: `profiles.suspended_at`; Edge Function sets auth ban (`ban_duration`) and calls `admin_suspend_cleanup(p_user_id)` to end active memberships.

## Work split

| Agent | Scope |
|-------|-------|
| backend agent | T001-T008 (RPCs, audit, Edge Function, pgTAP) |
| app agent | T009-T016 (console screens, entry in حسابي) |
