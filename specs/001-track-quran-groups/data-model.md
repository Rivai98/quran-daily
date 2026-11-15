# Data Model: Quran Group Reading Tracker (amended 2026-11-14)

Server tables live in Supabase Postgres schema `public` unless noted. Profiles (`public.profiles`) and `private.app_admins` come from spec 002. All timestamps are `timestamptz` (UTC); group-local dates are `date`.

## Entity Overview

```text
profiles 1--* group_memberships *--1 groups
profiles 1--* join_requests     *--1 groups
groups   1--* group_days 1--30 assignments
assignments 1--* completion_records
group_memberships 0..1--* assignments (reader)
```

## groups

| Field | Type | Rules |
|-------|------|-------|
| `id` | uuid PK | generated |
| `name` | text | trimmed, 3-60 chars |
| `short_description` | text | trimmed, 0-200 chars |
| `owner_id` | uuid → profiles | exactly one owner; equals the membership with role `owner` |
| `timezone` | text | valid IANA name (checked against `pg_timezone_names`) |
| `day_start_time` | time | default `00:00` |
| `visibility` | enum `public`, `private` | |
| `join_mode` | enum `auto_accept`, `approval` | |
| `status` | enum `forming`, `active`, `archived` | |
| `start_juz` | smallint 1-30, null | set when started |
| `start_date` | date, null | group-local date of day index 0 |
| `invite_code` | text unique (partial: non-archived) | 8 chars, alphabet `23456789ABCDEFGHJKLMNPQRSTUVWXYZ` |
| `created_at`, `updated_at` | timestamptz | server-maintained |

**Rules**: a user owns ≤ 3 groups with `status <> 'archived'`; `start_juz`/`start_date` non-null iff `status = 'active'` (or archived after being active); timezone/start-time edits never change existing `group_days`.

**Transitions**: `forming → active` (start_khatma, ≥ 1 active member) · `forming|active → archived` (owner) · no un-archive in v1.

## group_memberships

| Field | Type | Rules |
|-------|------|-------|
| `id` | uuid PK | |
| `group_id` | uuid → groups | |
| `user_id` | uuid → profiles | |
| `role` | enum `owner`, `supervisor`, `member` | one `owner` per group |
| `status` | enum `active`, `left`, `removed` | |
| `seat_number` | smallint 1-30, null | non-null iff `status = 'active'` |
| `joined_at`, `ended_at` | timestamptz | |

**Rules**: unique active membership per `(group_id, user_id)`; unique `(group_id, seat_number)` where active; ≤ 30 active per group; a `removed` row makes later joins go to approval (FR-028a); history keeps ended memberships for display names.

## join_requests

| Field | Type | Rules |
|-------|------|-------|
| `id` | uuid PK | |
| `group_id`, `user_id` | uuid | |
| `status` | enum `pending`, `approved`, `rejected`, `cancelled` | ≤ 1 pending per `(group_id, user_id)` |
| `source` | enum `discovery`, `invite`, `match` | |
| `requested_at`, `reviewed_at` | timestamptz | |
| `reviewed_by` | uuid, null | owner or supervisor |

**Transitions**: `pending → approved` (seat allocated) · `pending → rejected` · `pending → cancelled` (requester) · `rejected/cancelled → pending` (new request row).

## group_days

| Field | Type | Rules |
|-------|------|-------|
| `id` | uuid PK | |
| `group_id` | uuid | unique `(group_id, group_date)` |
| `group_date` | date | group-local date |
| `day_index` | int ≥ 0 | `group_date - start_date` |
| `opens_at`, `ends_at`, `closes_at` | timestamptz | rollover, next rollover, rollover after that |
| `state` | enum `open`, `grace`, `closed` | |
| `completed_count`, `late_count`, `missed_count`, `unread_count`, `pending_count`, `available_count` | smallint | maintained by functions |
| `full_khatma` | boolean | all 30 in (`completed`, `late`) |

**Transitions**: `open → grace` at `ends_at` (pending→missed, available→unread) · `grace → closed` at `closes_at`.

## assignments

| Field | Type | Rules |
|-------|------|-------|
| `id` | uuid PK | |
| `group_day_id` | uuid | |
| `juz` | smallint 1-30 | unique per day |
| `seat_number` | smallint 1-30 | unique per day; `juz = juz_for_seat(seat, start_juz, day_index)` |
| `kind` | enum `seat`, `override`, `volunteer`, `unassigned` | |
| `reader_membership_id` | uuid, null | null iff `kind = 'unassigned'` |
| `status` | enum `pending`, `completed`, `missed`, `late`, `available`, `unread` | `available/unread` iff unassigned |
| `completed_at` | timestamptz, null | |
| `updated_at` | timestamptz | |

**State transitions** (server-enforced):

```text
open day:   available -> pending          (volunteer / override / member joins seat)
            pending   -> completed        (complete)        completed -> pending (undo)
            pending   -> available        (reader leaves/removed, not completed)
grace:      pending   -> missed           (automatic at ends_at)
            available -> unread           (automatic at ends_at)
            missed    -> late             (complete)        late -> missed (undo)
closed:     no changes
```

## completion_records

| Field | Type | Rules |
|-------|------|-------|
| `id` | uuid PK | |
| `assignment_id` | uuid | |
| `actor_user_id` | uuid | |
| `action` | enum `completed`, `late`, `undone` | |
| `client_recorded_at` | timestamptz | time on device |
| `recorded_at` | timestamptz | server time |
| `source` | enum `online`, `offline_sync` | |

Duplicate completes are idempotent (no new record when status already completed/late).

## Read models (returned by RPC, cached locally)

**PublicGroupProfile**: `group_id, name, short_description, active_member_count, timezone, status (forming/active), join_mode, my_request_status (none/pending/rejected), my_join_request_id?` (set when pending, for cancel). Never members, progress, or history.

**MyGroupSummary**: `group_id, name, status, my_role, active_member_count, today_my_juz?, today_my_status?`.

**PendingJoinRequest**: `join_request_id, group_id, group_name, requested_at, source`. Returned with my groups by `get_my_groups` so S1 can show pending rows and cancel them.

**DashboardSnapshot**: group summary; today `group_day` (date, state, counts, full_khatma, ends_at); `my_assignments[]` (own seat + volunteered/overridden); `assignments[30]` (`juz, seat_number, kind, status, reader_display_name?, is_me`); `is_khatm_juz` flag on juz 30; `server_generated_at`. Forming groups return members per seat instead of assignments.

**HistoryDaySummary**: `group_date, counts, full_khatma, my_result?`; detail (owner/supervisor only) adds per-juz `seat_number, reader_display_name, status`.

## Local SQLite (device)

| Table | Columns | Purpose |
|-------|---------|---------|
| `cached_snapshots` | `group_id PK, json, cached_at` | dashboard offline |
| `cached_groups` | `user_id, json, cached_at` | my groups offline |
| `cached_history` | `group_id, json, cached_at` | last history page |
| `sync_queue` | `id PK, op (mark_complete/undo_completion), assignment_id, client_recorded_at, status (pending/syncing/failed), attempts, last_error_kind, created_at` | queued personal actions |

`shared_preferences` (via `lib/core/settings/SettingsRepository`): `selected_group_id`, `quran_text_scale` (0.85-1.6, default 1.0).

## Quran metadata (bundled, Principle VII)

`assets/quran/quran-data.xml` (Tanzil, owner-provided) → `QuranMetadataRepository` exposes `JuzInfo { number 1-30, startSura, startAya, endSura, endAya }`, `suraName(sura)`, and `suraAyahCount(sura)` from the same file; every end boundary is derived from the next juz start and the file's ayah counts (source details: plan.md "Quran Content Source"). Ordinal juz names come from `arabic_strings.dart`. A test verifies `assets/quran/checksums.sha256`.
