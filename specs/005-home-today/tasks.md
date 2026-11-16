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

- [X] T011 [P] [US2] Widget tests `test/features/shell/home_shell_test.dart`: 4 tabs, Home initially selected, nested stack retention/back, RTL, 320dp and 200% text
- [X] T012 [US2] Four-stack HomeShell, ShellCubit, AppTabBar, placeholders, auth gate, deep-link route handling, and stack disposal at auth-gate transition
- [X] T013 [P] [US1] Entities + JSON parsing tests `test/features/home/data/today_parsing_test.dart` for the `get_my_today` contract
- [X] T014 [US1] `lib/features/home/data/`: TodayRemoteDataSource, TodayRepository(+Impl) with sqflite cache and offline fallback
- [X] T015 [P] [US1] Cubit tests `test/features/home/cubit/home_cubit_test.dart` for loading, completion, pinning, empty and cached states
- [X] T016 [US1] `lib/features/home/cubit/` HomeCubit + HomeState
- [X] T017 [P] [US1] `hijri` dependency and DateHeader test (both were present on resume)
- [X] T018 [US1b] Main group hero with avatar, progress/cycle, metadata range, portion actions, rest-day state and dashboard shortcut
- [X] T019 [US1] Today cards render each assigned portion; Home includes date, empty entry points, completion/offline states. Settings is opened from حسابي per updated brief.
- [X] T020 [P] [US1] Home widget tests cover empty/content/offline/error, dark/light, 320dp, 200% text and RTL
- [X] T021 [US1b] Group dashboard main-group menu and mark-opened callback (present on resume)
- [X] T022 [US1] DI and ArabicStrings have marked 005 home blocks

## Phase 3: Log + limit UI + visuals (codex) — US3, US4, FR-004c

- [X] T023 [P] [US3] Parsing tests `test/features/log/data/log_parsing_test.dart` for `get_my_log`
- [X] T024 [US3] `lib/features/log/data/`: LogRemoteDataSource, LogRepository(+Impl) with cache of the first page
- [X] T025 [P] [US3] Cubit tests `test/features/log/cubit/log_cubit_test.dart`: load, loadMore pagination, refresh, offline cached, empty
- [X] T026 [US3] `lib/features/log/cubit/` LogCubit + LogState
- [X] T027 [US3] LogScreen: StreakHeader (streak + best), MonthSummary, days grouped by week, LogDayTile with status triplets (color + icon + label: مكتمل، متأخر، فائت، تطوع); friendly empty state
- [X] T028 [US3] LogDayDetailScreen: each item with portion name/range from metadata and link to that group's history day
- [X] T029 [P] [US3] Widget tests `test/features/log/view/log_screen_test.dart` (RTL, dark, 320dp, 200% text)
- [X] T030 [P] FR-004c: map `membership_limit` to "يمكنك الانضمام إلى مجموعتين بحد أقصى" in create, join, join-any, invite preview (with link to مجموعاتي), approve request; tests
- [X] T031 [US4] Member initial avatars, role and seat icons on members list and group cards; group status icons; Islamic ornament on Log/Home empty states; gold only for ornament (Home feature is not present in this branch)
- [X] T032 [US4] Golden/contrast tests for the new visuals (light + dark)
- [X] T033 DI (marked block) and strings (marked block)

## Phase 3b: Profile tab حسابي (agy) — FR-011
- [X] T038 [P] pgTAP `supabase/tests/005_my_profile_test.sql`: streak/best streak, totals, khatmas per group, badges (first_khatma, streak_7/30/100, portions_100) from fixture history; only the caller's data
- [X] T039 Migration `supabase/migrations/20261115100005_get_my_profile.sql`: `get_my_profile()` per plan; apply to DEV
- [X] T040 [P] Parsing + cubit tests `test/features/profile/`
- [X] T041 `lib/features/profile/` data (remote + sqflite cache), ProfileCubit
- [X] T042 ProfileScreen: header (avatar initials, name, member since), streak card, totals, khatmas list, badges grid (earned vs locked), entry rows to السجل (LogScreen) and الإعدادات (SettingsScreen); calm, no shaming
- [X] T043 [P] Widget tests (RTL, dark, 320dp, 200% text)
- [X] T044 Strings block `// --- 005 profile ---`, DI block

## Phase 4: Integration + validation (orchestrator)

- [X] T034 Merge agent branches into `005-home-today`; mount Mushaf index (spec 003) as المصحف tab and ProfileScreen as حسابي tab; resolve shared-file blocks
- [X] T035 Integration test `integration_test/home_flow_test.dart`: sign up, create group, start, Home hero shows portion, mark complete from Home, profile shows, 3rd group creation refused (written; device run pending)
- [X] T036 Update spec 001 T111 / spec 004 T016 integration tests for the new shell navigation (written; device run pending)
- [ ] T037 (pending: final re-run of spec_validation + tour stopped by owner) Final validation: `flutter analyze` 0, `flutter test` all green, pgTAP all files 0 failed, integration tests on Android; record results below

## Dependencies

Phase 1 is independent. Phases 2 and 3 code against the plan contracts with
fakes and can run in parallel with Phase 1. Phase 4 needs all three.

## Validation log

### 2026-11-16 (qa)
- T031 verified in code and tests: members list UserAvatar + role badge icon (stars/shield) + seat icon (`members_screen_test`), group cards GroupAvatar + status badge icons (`group_selection_screen_test`), Islamic ornament on Log empty (`IslamicOrnamentBand`, `log_screen_test`) and Home empty (HalaqaLogo, `home_screen_test`, commit 3d03852). Gold (`accent`) is used only by ornament/logo/avatar art.
- T034 verified on emulator-5554 by `spec_validation_test.dart`: four tabs present; المصحف opens MushafIndexScreen; حسابي opens ProfileScreen ("005 T034 PASS").
- Fixed on the way: Home stayed on the empty state after creating/starting a group within 30 s (fab9d47); first-run reminders sheet popped over other tabs (92564cd).
- Gates on qa @ 4a49987: `flutter analyze` No issues; `flutter test` 595 passed, 0 failed.
- pgTAP (hosted DEV, `scripts/run_remote_pgtap.py`, every file in `supabase/tests`): 24 files, 593 passed, 0 failed.
- Integration tests on emulator-5554 (Android, swiftshader) @ 4a49987: group_flow, home_flow, mushaf_flow, offline_completion, portion_flow all passed.
- `integration_test/spec_validation_test.dart` passed in full @ 28c435e (log below). Its re-run in the final pass, and the screenshot tour re-run, were stopped by the owner's publish request, so they were not repeated after 92564cd/fab9d47/745f152.
