# Implementation Plan: Today Home, Bottom Tabs, and Personal Daily Log

**Branch**: `005-home-today` | **Date**: 2026-11-15 | **Spec**: [spec.md](./spec.md)
**Constitution**: v2.4.0 (binding) | **Builds on**: specs 001 + 004 (in `main`)

## Summary

Replace the group-list-first flow with a 4-tab shell (الرئيسية، مجموعاتي،
المصحف، حسابي). المصحف hosts the spec 003 index/bookmarks; حسابي is a
motivating profile (streak, totals, khatmas, badges) that contains the
personal log and Settings. Home shows the user's main group as a hero card and today's portions
in their other group, with open / mark-complete actions. The Log shows the
user's personal history across groups with a streak and a monthly summary.
Each user may hold at most 2 active memberships. Two new read RPCs aggregate
across groups; two small write RPCs store the main group and the last-opened
time.

## Technical Context

Same stack as specs 001/004: Flutter (Dart ^3.10.4) Android/iOS, MVVM + Cubit,
get_it, named-route Navigator, hosted Supabase Postgres (RLS + SECURITY
DEFINER RPCs with `set search_path = ''`, pg_cron), sqflite cache + sync queue.
Docker-free workflow: `python scripts/run_remote_pgtap.py <file>`; migrations
applied with `supabase db query --remote --yes -f <file>` then
`supabase migration repair --remote --yes --status applied <version>`.
**Migration range for 005: `2026111510NNNN`.**

New dependency: `hijri` (Umm al-Qura conversion, pub.dev, tested) for FR-007.

## Constitution Check

| Principle | How this feature complies |
|-----------|---------------------------|
| I Offline core | Home and Log read through repositories that cache the last RPC payload in sqflite; completions reuse the spec 001 sync queue |
| II Arabic/RTL | All copy in ArabicStrings; Arabic numerals; tab order follows RTL; 48dp targets |
| III Test-first | pgTAP for limit, main group, today, log, streak; cubit + widget tests (RTL, 200% text, dark, 320dp) |
| IV MVVM + Cubit | HomeCubit, LogCubit, ShellCubit (tab index); widgets render state only |
| V Simplicity | No new tables; 2 columns added; streak computed in SQL |
| VI Design system | Hero/compact cards and tab bar built from existing tokens and AppCard/StatusChip; gold only for ornament |
| VII Quran integrity | RPCs return unit + index only; names/ranges come from QuranMetadataRepository |

Gate: PASS.

## Data model changes

- `profiles.main_group_id uuid null references groups(id) on delete set null`.
- `group_memberships.last_opened_at timestamptz null`.
- Limit: a user has at most **2** memberships with `status = 'active'` in groups
  whose `status <> 'archived'`. Replaces spec 001's owner limit of 3. Error code
  `membership_limit` (P0001). Enforced in `create_group`, `join_group`,
  `join_any_group`, `review_join_request` (approve), invite accept. Users already
  above the limit keep their groups. `get_invite_preview` and
  `search_public_groups` rows gain `can_join_limit boolean`.

## RPC contracts

All are SECURITY DEFINER, `set search_path = ''`, callable by `authenticated`.

### `set_main_group(p_group_id uuid) returns void`
Caller must be an active member, else `not_member`. `null` clears the pin.

### `mark_group_opened(p_group_id uuid) returns void`
Sets the caller's `last_opened_at = now()`; no-op when not a member.

### `get_my_today() returns jsonb`
```json
{
  "server_generated_at": "timestamptz",
  "main_group_id": "uuid|null",          // pinned if still active, else most recently opened active group, else first
  "membership_count": 2,
  "membership_limit": 2,
  "groups": [{
    "group_id": "uuid", "name": "text", "role": "owner|supervisor|member",
    "status": "forming|active", "portion_unit": "juz|...",
    "is_main": true,
    "day": null | {
      "group_date": "date", "day_index": 3, "state": "open|grace|closed",
      "ends_at": "timestamptz", "closes_at": "timestamptz",
      "cycle_number": 1, "cycle_day": 1, "cycle_length": 2,
      "completed_count": 18, "total_count": 30,
      "rest_day": false                   // true when the caller's seat rests today (spec 004 page unit)
    },
    "items": [{                           // caller's assignments for that group's current day
      "assignment_id": "uuid", "kind": "seat|override|volunteer",
      "seat_number": 4, "portion_index": 12,
      "status": "pending|completed|late|missed|unread",
      "completed_at": "timestamptz|null", "can_undo": true
    }]
  }]
}
```
Groups ordered: main first, then by `day.ends_at`. Archived groups excluded.

### `get_my_profile() returns jsonb`
```json
{
  "display_name": "text", "member_since": "date",
  "streak": 5, "best_streak": 12,
  "portions_read": 143, "portions_late": 9,
  "khatmas": [{"group_id": "uuid", "group_name": "text", "completed": 3}],
  "badges": [{"code": "first_khatma|streak_7|streak_30|streak_100|portions_100", "earned_at": "date"}]
}
```
Badges are computed in SQL from assignments/group_days (no client trust).

### `get_my_log(p_before date default null, p_days int default 30) returns jsonb`
```json
{
  "streak": 5,                            // FR-010: consecutive days, newest first; late counts, missed breaks, empty days skipped
  "best_streak": 12,
  "month": {"year": 2026, "month": 11, "full_days": 9, "days_with_items": 12},
  "days": [{                              // newest first, only days with at least one item, date < p_before
    "date": "date",                       // the group's local group_date
    "complete": true,                     // every item completed or late
    "items": [{"group_id": "uuid", "group_name": "text", "portion_unit": "hizb",
               "portion_index": 12, "kind": "seat|override|volunteer",
               "status": "completed|late|missed|pending|unread",
               "completed_at": "timestamptz|null", "group_day_id": "uuid"}]
  }],
  "next_before": "date|null"              // pagination cursor
}
```
Items come from assignments whose reader is any of the caller's memberships
(active or past), so history survives leaving a group.

## App structure (changes only)

```text
lib/app/router.dart                        root '/home' -> HomeShell; existing routes stay (pushed inside tab navigators)
lib/features/shell/                        HomeShell (IndexedStack of 4 nested Navigators), ShellCubit, AppTabBar
lib/features/home/
  data/  today_remote_data_source, today_repository(+_impl, sqflite cache), entities (TodaySnapshot, TodayGroup, TodayItem)
  cubit/ home_cubit (load/refresh/complete/undo/pin), home_state
  view/  home_screen, widgets/ main_group_hero_card, today_item_card, date_header (Hijri + Gregorian)
lib/features/log/
  data/  log_remote_data_source, log_repository(+_impl, cache), entities (PersonalLog, LogDay, LogItem)
  cubit/ log_cubit (load, loadMore, refresh)
  view/  log_screen, log_day_detail_screen, widgets/ streak_header, month_summary, log_day_tile
lib/features/quran_groups/                 group menu "اجعلها مجموعتي الرئيسية"; mark_group_opened on dashboard open;
                                           membership_limit failure -> Arabic message; group list becomes the مجموعاتي tab
lib/core/localization/arabic_strings.dart  new strings
supabase/migrations/2026111510NNNN_*.sql
supabase/tests/005_*.sql
```

Completion and undo from Home reuse `KhatmaRepository.markComplete/undo` (spec
001 rules: grace, offline queue, undo confirmation sheet). After a change the
Home cubit refreshes Today and the group dashboard cache is invalidated.

## Work split (agents)

| Agent | Scope | Files |
|-------|-------|-------|
| codex-1 | Backend: T001-T010 | `supabase/` only |
| codex-2 | Shell + Home: T011-T022 | `lib/app`, `lib/features/shell`, `lib/features/home`, tests |
| codex | Log + limit UI + icons: T023-T033 | `lib/features/log`, `lib/features/quran_groups`, tests |
| agy | Profile tab حسابي: T038-T044 | `supabase/` (get_my_profile only), `lib/features/profile`, tests |

The app agents code against the contracts above with fakes; integration runs
after the backend lands. `arabic_strings.dart` and `service_locator.dart` are
shared: each agent appends in its own clearly marked block to keep merges easy.
