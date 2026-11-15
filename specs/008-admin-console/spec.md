# Feature Specification: App Admin Console

**Feature Branch**: `008-admin-console`
**Created**: 2026-11-15
**Status**: Clarified (2026-11-15)
**Depends on**: 001 (groups), 002 (`private.app_admins`, admin Edge Functions), 005 (حسابي tab)
**Input**: Owner: "I want an admin part inside the app for me only: see all
groups, delete a group, remove people, full authority, manage everything, with
reports."

## Clarifications

### Session 2026-11-15

- Q: Where does the admin console live? → A: Inside the app. A "لوحة الإدارة"
  entry appears in حسابي only for app admins; every admin action is authorized
  on the server (`private.app_admins`), never by hiding UI alone.
- Q: What does "delete a person" do? → A: Two separate actions: "إيقاف"
  (suspend: blocks sign-in, removes the user from active groups, reversible by
  "إلغاء الإيقاف") and "حذف نهائي" (permanent account deletion, double
  confirmation, irreversible).
- Q: Who is admin? → A: Only users in `private.app_admins` (the owner seeds
  the first one, spec 002). Admins can grant/revoke admin for others only from
  the console, with the last admin protected from removal.
- Q: Is admin activity recorded? → A: Yes, every admin action is written to an
  audit log visible in the console.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Overview and reports (Priority: P1)

The admin opens "لوحة الإدارة" and sees: total users, new users (7/30 days),
active users today, total groups by status (forming/active/archived), today's
completion rate across all groups, khatmas completed (7/30 days), and a 30-day
chart of daily completions.

**Acceptance Scenarios**:
1. **Given** an admin, **When** the console opens, **Then** the numbers come
   from the server and match the database.
2. **Given** a non-admin, **When** they call any admin RPC, **Then** it fails
   with `not_admin` and the entry is not shown.

### User Story 2 - Manage groups (Priority: P1)

The admin lists and searches ALL groups (public and private) with owner,
member count, unit, status, created date. Opening a group shows its members and
today's progress. Actions: archive, restore, delete permanently (double
confirmation), remove a member, transfer ownership, regenerate invite.

**Acceptance Scenarios**:
1. **Given** any group, **When** the admin deletes it after double
   confirmation, **Then** it and its days/assignments are removed and members
   no longer see it.
2. **Given** a member, **When** the admin removes them, **Then** the seat is
   freed using spec 001 rules.

### User Story 3 - Manage users (Priority: P1)

The admin lists and searches users (display name, email visible to admins
only, created date, groups count, last activity, status). Actions: view
groups, suspend / unsuspend, reset password (existing Edge Function), create a
user (existing Edge Function), delete permanently (double confirmation),
grant/revoke admin.

**Acceptance Scenarios**:
1. **Given** a suspended user, **When** they try to sign in, **Then** sign-in
   is refused with a calm Arabic message, and they are no longer in active
   groups.
2. **Given** a permanent delete, **Then** the auth user, profile and
   memberships are removed; history rows keep the day counts but lose the name.
3. **Given** only one admin, **When** they try to revoke themselves, **Then**
   it is refused (`last_admin`).

### User Story 4 - Audit log (Priority: P2)

A chronological list of admin actions (who, what, target, when, result),
filterable by action type.

### Edge Cases

- An admin cannot suspend or delete themselves.
- Deleting a group's owner account first transfers ownership to the most senior
  supervisor/member, or archives the group if empty.
- All destructive actions require typing the target name or a second confirm.

## Requirements *(mandatory)*

- **FR-001**: Admin RPCs MUST verify `private.app_admins` server-side and raise
  `not_admin` otherwise.
- **FR-002**: The console MUST show the overview metrics of US1 computed server-side.
- **FR-003**: Admins MUST be able to list/search all groups and perform archive,
  restore, delete, remove member, transfer ownership, regenerate invite.
- **FR-004**: Admins MUST be able to list/search users, suspend/unsuspend,
  reset password, create user, delete permanently, grant/revoke admin.
- **FR-005**: Suspension MUST block sign-in (auth ban) and remove active
  memberships; unsuspend restores sign-in only.
- **FR-006**: Every admin action MUST be recorded in an audit log readable in
  the console.
- **FR-007**: Emails are visible only inside the admin console.
- **FR-008**: The console follows constitution II and VI; destructive actions
  use the danger button style with double confirmation.

## Success Criteria *(mandatory)*

- **SC-001**: 100% of admin RPCs refuse non-admins in automated tests.
- **SC-002**: The admin can find any user or group by name in under 5 seconds.
- **SC-003**: Every destructive action leaves an audit entry (tested).

## Assumptions

- Auth-level operations (ban, delete user, create user, reset password) run in
  Edge Functions with the service role on the server; the key never reaches
  the app (constitution / spec 002).
- Edge Function deployment is done with the Supabase CLI by the orchestrator
  after owner approval.
