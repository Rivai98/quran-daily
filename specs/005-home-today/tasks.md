# Tasks: Today Home, Bottom Tabs, and Personal Daily Log

**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)
Test-first (constitution III): write each test task before its implementation.

## Phase 1: Backend (codex-1, `supabase/` only, migrations `2026111510NNNN`)

- [X] T001 [P] pgTAP `supabase/tests/005_membership_limit_test.sql`: 3rd active membership refused with `membership_limit` in create_group, join_group, join_any_group, review_join_request approve, invite join; archived groups and left memberships do not count; users already above 2 keep their groups
- [X] T002 Migration `supabase/migrations/20261115100001_membership_limit.sql`: shared helper `active_membership_count(uid)`, enforce limit 2 in all join/create paths, drop the owner-3 rule, add `can_join_limit` to invite preview and search rows
- [X] T003 [P] pgTAP `supabase/tests/005_main_group_test.sql`: set_main_group (member ok, non-member `not_member`, null clears), mark_group_opened, main group fallback order
- [X] T004 Migration `supabase/migrations/20261115100002_main_group.sql`: `profiles.main_group_id`, `group_memberships.last_opened_at`, `set_main_group`, `mark_group_opened`
- [X] T005 [P] pgTAP `supabase/tests/005_my_today_test.sql`: two groups (juz + hizb) return both with day, counts, cycle fields and the caller's items; volunteer/override items included; rest-day flag for a page group; forming group has `day = null`; archived excluded; ordering main first
- [X] T006 Migration `supabase/migrations/20261115100003_get_my_today.sql`: `get_my_today()` per plan contract (call `ensure_current_group_day` per group first)
- [X] T007 [P] pgTAP `supabase/tests/005_my_log_test.sql`: days newest first; late keeps streak; missed breaks it; empty days skipped; month summary; pagination via `p_before`; history kept after leaving a group; other users' items never returned
- [X] T008 Migration `supabase/migrations/20261115100004_get_my_log.sql`: `get_my_log(p_before, p_days)` per plan contract
- [X] T009 Apply migrations to hosted DEV (`db query -f` + `migration repair`), run all 005 tests and the full existing suite (`supabase/tests/*.sql`) with `scripts/run_remote_pgtap.py`: 0 failed
- [X] T010 Update existing tests that assumed the owner-3 limit

## Phase 2: Shell + Home (codex-2) — US1, US1b, US2

- [ ] T011 [P] [US2] Widget tests `test/features/shell/home_shell_test.dart`: 4 tabs (الرئيسية، مجموعاتي، المصحف، حسابي) with icon + label, Home selected after sign-in, tab switch keeps each stack, back inside مجموعاتي returns to the list, RTL, 48dp, 320dp, 200% text
- [ ] T012 [US2] `lib/features/shell/` HomeShell (IndexedStack + 3 nested Navigators reusing `AppRoutes.onGenerateRoute`), ShellCubit, AppTabBar from design tokens; auth gate opens HomeShell; deep link join still opens above the tabs; sign-out clears stacks
- [ ] T013 [P] [US1] Entities + JSON parsing tests `test/features/home/data/today_parsing_test.dart` for the `get_my_today` contract
- [ ] T014 [US1] `lib/features/home/data/`: TodayRemoteDataSource, TodayRepository(+Impl) with sqflite cache of the last payload, offline fallback
- [ ] T015 [P] [US1] Cubit tests `test/features/home/cubit/home_cubit_test.dart`: load, cached-then-fresh, offline, complete/undo through KhatmaRepository then refresh, pin main group, empty (no groups), all-done
- [ ] T016 [US1] `lib/features/home/cubit/` HomeCubit + HomeState
- [ ] T017 [P] [US1] Add `hijri` dependency; `DateHeader` widget test (Hijri then Gregorian, Arabic numerals) `test/features/home/view/date_header_test.dart`
- [ ] T018 [US1b] `MainGroupHeroCard` (avatar from group initials, name, "١٨ من ٣٠" progress, cycle line, portion name/range from QuranMetadataRepository, افتح الورد primary + تمت القراءة, rest-day state "لا ورد اليوم", shortcut to dashboard)
- [ ] T019 [US1] `TodayItemCard` (compact) for the other group, and HomeScreen: greeting, DateHeader, hero, other group, empty state with spec 001 entry points, calm all-done message, offline banner, settings icon in app bar
- [ ] T020 [P] [US1] Widget tests `test/features/home/view/home_screen_test.dart` (states above, light/dark, 320dp, 200% text, RTL)
- [ ] T021 [US1b] Group dashboard menu "اجعلها مجموعتي الرئيسية" + `mark_group_opened` call when a dashboard opens
- [ ] T022 [US1] DI registration (marked block in `service_locator.dart`), strings (marked block in `arabic_strings.dart`)

## Phase 3: Log + limit UI + visuals (codex) — US3, US4, FR-004c

- [ ] T023 [P] [US3] Parsing tests `test/features/log/data/log_parsing_test.dart` for `get_my_log`
- [ ] T024 [US3] `lib/features/log/data/`: LogRemoteDataSource, LogRepository(+Impl) with cache of the first page
- [ ] T025 [P] [US3] Cubit tests `test/features/log/cubit/log_cubit_test.dart`: load, loadMore pagination, refresh, offline cached, empty
- [ ] T026 [US3] `lib/features/log/cubit/` LogCubit + LogState
- [ ] T027 [US3] LogScreen: StreakHeader (streak + best), MonthSummary, days grouped by week, LogDayTile with status triplets (color + icon + label: مكتمل، متأخر، فائت، تطوع); friendly empty state
- [ ] T028 [US3] LogDayDetailScreen: each item with portion name/range from metadata and link to that group's history day
- [ ] T029 [P] [US3] Widget tests `test/features/log/view/log_screen_test.dart` (RTL, dark, 320dp, 200% text)
- [ ] T030 [P] FR-004c: map `membership_limit` to "يمكنك الانضمام إلى مجموعتين بحد أقصى" in create, join, join-any, invite preview (with link to مجموعاتي), approve request; tests
- [ ] T031 [US4] Member initial avatars, role and seat icons on members list and group cards; group status icons; Islamic ornament on Log/Home empty states; gold only for ornament
- [ ] T032 [US4] Golden/contrast tests for the new visuals (light + dark)
- [ ] T033 DI (marked block) and strings (marked block)

## Phase 3b: Profile tab حسابي (agy) — FR-011
- [ ] T038 [P] pgTAP `supabase/tests/005_my_profile_test.sql`: streak/best streak, totals, khatmas per group, badges (first_khatma, streak_7/30/100, portions_100) from fixture history; only the caller's data
- [ ] T039 Migration `supabase/migrations/20261115100005_get_my_profile.sql`: `get_my_profile()` per plan; apply to DEV
- [ ] T040 [P] Parsing + cubit tests `test/features/profile/`
- [ ] T041 `lib/features/profile/` data (remote + sqflite cache), ProfileCubit
- [ ] T042 ProfileScreen: header (avatar initials, name, member since), streak card, totals, khatmas list, badges grid (earned vs locked), entry rows to السجل (LogScreen) and الإعدادات (SettingsScreen); calm, no shaming
- [ ] T043 [P] Widget tests (RTL, dark, 320dp, 200% text)
- [ ] T044 Strings block `// --- 005 profile ---`, DI block

## Phase 4: Integration + validation (orchestrator)

- [ ] T034 Merge agent branches into `005-home-today`; mount Mushaf index (spec 003) as المصحف tab and ProfileScreen as حسابي tab; resolve shared-file blocks
- [ ] T035 Integration test `integration_test/home_flow_test.dart`: sign up, create group, start, Home hero shows portion, mark complete from Home, Log shows today after refresh, 3rd group creation refused
- [ ] T036 Update spec 001 T111 / spec 004 T016 integration tests for the new shell navigation
- [ ] T037 Final validation: `flutter analyze` 0, `flutter test` all green, pgTAP all files 0 failed, integration tests on Android; record results below

## Dependencies

Phase 1 is independent. Phases 2 and 3 code against the plan contracts with
fakes and can run in parallel with Phase 1. Phase 4 needs all three.

## Validation log

_(filled at T037)_
