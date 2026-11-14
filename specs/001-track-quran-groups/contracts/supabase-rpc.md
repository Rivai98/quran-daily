# Contract: Supabase Database Functions (amended 2026-11-14)

The Flutter app calls these functions with `supabase.rpc(name, params)`. Exact SQL is an implementation task; names, inputs, outputs, validation, and error codes are fixed here. Auth/profile/admin functions are defined in [spec 002 backend contract](../../002-email-password-auth/contracts/supabase-backend.md).

## Shared Rules

- Every function requires `auth.uid()` (error `unauthenticated`), is `SECURITY DEFINER SET search_path = ''`, and checks roles internally.
- RLS is enabled on every table. Direct client `insert/update/delete` on group tables is denied; `select` is allowed only for active members of the group (and own join requests / own memberships).
- Errors are raised as `{ code }` with the stable codes listed; the app maps codes to Arabic copy.
- Timestamps are UTC; group-local dates are `date` strings `YYYY-MM-DD`.
- Rotation helper `juz_for_seat(seat int, start_juz int, day_index int) returns int` = `((start_juz - 1) + (seat - 1) + day_index) % 30 + 1`; immutable, covered by pgTAP.
- Common errors: `unauthenticated`, `group_not_found`, `group_archived`, `not_member`, `forbidden` (role), `validation_failed`.

## Group lifecycle

### `create_group(name, short_description, timezone, day_start_time, visibility, join_mode)`
→ `{ group_id, invite_code }`. Creator gets membership role `owner`, seat 1, status `forming`.
Errors: `validation_failed` (name 3-60, description ≤ 200, timezone invalid), `owner_group_limit` (already owns 3 non-archived).

### `update_group_settings(group_id, name?, short_description?, timezone?, day_start_time?, visibility?, join_mode?)`
Owner only. Timezone/start-time changes apply from the next group day. → updated `MyGroupSummary`.

### `start_khatma(group_id, start_juz default 1)`
Owner only; group must be `forming`; ≥ 1 active member. Sets `status=active`, `start_juz`, `start_date = current group-local date`, creates today's `group_day` with 30 assignments. → `DashboardSnapshot`.
Errors: `group_not_forming`, `validation_failed`.

### `archive_group(group_id)` · `transfer_ownership(group_id, new_owner_membership_id)`
Owner only. Transfer target must be an active member; previous owner becomes `member`.

### `regenerate_invite(group_id)` → `{ invite_code }` (owner only; old code stops working).

## Discovery and joining

### `get_my_groups()` → `{ groups: MyGroupSummary[], pending_requests: PendingJoinRequest[] }`
Active memberships plus the caller's own `pending` join requests (feeds S1 rows and "إلغاء الطلب").

### `search_public_groups(query?, needs_members_only default true, limit, offset)`
→ `PublicGroupProfile[]` for public, non-archived groups, sorted by empty seats ascending then `created_at`. Never returns members or progress.

### `get_invite_preview(invite_code)` → `PublicGroupProfile` (works for private groups) · errors `invite_invalid`.

### `join_group(group_id? , invite_code?, source)`
Exactly one of `group_id` (public only) or `invite_code`. Logic per research R7.
→ `{ result: 'joined' | 'pending', membership_id?, seat_number?, join_request_id? }`.
Errors: `already_member`, `request_already_pending`, `group_full`, `group_not_public`, `invite_invalid`, `group_archived`.

### `join_any_group(device_timezone)` → same shape as `join_group` · error `no_group_available`.

### `cancel_join_request(join_request_id)` (requester only).

### `list_join_requests(group_id)` → `[{ join_request_id, user_display_name, requested_at, source }]` (owner/supervisor).

### `review_join_request(join_request_id, decision: 'approve'|'reject')`
Owner/supervisor. Approve allocates the lowest free seat. Errors: `request_not_pending`, `group_full`.

## Membership and seats

### `get_group_members(group_id)` → `[{ membership_id, display_name, role, seat_number }]` + empty seats (members of the group).

### `move_member_seat(group_id, membership_id, target_seat)` (owner/supervisor)
If target occupied, the two members swap seats. Takes effect from the next group day for active groups. Errors: `validation_failed`.

### `set_member_role(group_id, membership_id, role: 'supervisor'|'member')` (owner only).

### `remove_member(group_id, membership_id)` (owner only; cannot remove self). Frees seat; today's pending row becomes available.

### `leave_group(group_id)` · error `owner_must_transfer` for the owner.

## Daily khatma

### `get_dashboard(group_id)`
Calls `ensure_current_group_day(group_id)` first (idempotent). Members only. → `DashboardSnapshot` (see data-model). Forming groups return `{ status: 'forming', seats[30], active_member_count, invite_code }`. `invite_code` is returned to every active member in forming and active groups (UI-005, S9); only the Owner can regenerate it.

### `mark_assignment_complete(assignment_id, client_recorded_at, source: 'online'|'offline_sync')`
Caller must be the reader. Open day → `completed`; grace → `late`; closed → `day_closed`. The decisive time is `now()` for `source='online'`; for `source='offline_sync'` it is `client_recorded_at` clamped to `[day.opens_at, now()]` (research R11). Idempotent. → `{ assignment_id, status, completed_at, day_counts }`.
Errors: `not_reader`, `day_closed`, `assignment_not_found`.

### `undo_assignment_completion(assignment_id)`
Reader only; open: `completed → pending`; grace: `late → missed`; closed → `day_closed`. → same shape.

### `volunteer_for_juz(assignment_id)` (any active member; open day only)
Atomic conditional update (research R5). → updated assignment row. Errors: `juz_already_taken`, `day_not_open`.

### `override_assignment(assignment_id, membership_id)` (owner only; open day; target active member)
Sets `kind='override'`, reader, `status='pending'` (keeps `completed` rows untouchable: error `already_completed`).

### `get_history(group_id, before_date?, limit default 30)` → `HistoryDaySummary[]` (members).
### `get_history_day(group_id, group_date)` → detail; per-member rows only for owner/supervisor, own row for members.

## Scheduled jobs (pg_cron, every minute)

- `generate_due_group_days()`: for each active group whose current group-local date has no `group_day`, create it with 30 assignments from seats (occupied → `seat/pending`, empty → `unassigned/available`).
- `advance_day_states()`: `open → grace` at `ends_at` (pending→missed, available→unread); `grace → closed` at `closes_at`; recompute counts and `full_khatma`.

## Privacy guarantees (pgTAP)

- Non-member cannot select from `group_memberships`, `group_days`, `assignments`, `completion_records` of a group.
- `search_public_groups` / `get_invite_preview` never expose members or progress.
- Member cannot call owner/supervisor functions (`forbidden`); supervisor cannot archive, transfer, set roles, override, or remove.
