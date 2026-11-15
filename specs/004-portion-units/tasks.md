# Tasks: Configurable Daily Portion (Wird Unit)

**Input**: spec.md, plan.md, data-model.md (this folder). Binding: constitution v2.4.0.
TDD mandatory: write the test, see it fail, implement. Migrations range:
`2026111509NNNN`. pgTAP UUID prefix `a4`, invite codes `P4xxxxx`.
Apply migrations with `supabase db query --remote --yes -f` + `supabase
migration repair --remote --yes --status applied <version>` (never db push).

## Phase 1: Metadata foundation (branch 004-portion-metadata, codex-1)

- [X] T001 [P] `PortionUnit` enum + `QuranPortion` + `QuranMetadataRepository.portions(unit)`/`portion(unit, i)` derived only from assets/quran/quran-data.xml in `lib/core/quran/`
- [X] T002 [P] Tests: counts per unit read from file, contiguity/full coverage, hizb = 4 quarters, half juz = 2 hizb, juz equals existing `juz()` in `test/core/quran/`
- [X] T003 Unit labels and portion name formatter ("الحزب ١٢"، "الصفحة ٤٥") in `lib/core/localization/arabic_strings.dart`

## Phase 2: Database (US1, US2, US3, US4)

- [X] T004 pgTAP `supabase/tests/004_portion_units_test.sql`: `portion_count`; `portion_for_seat` for every unit — one full cycle covers 1..N exactly once, rest days only on the last partial page day, next cycle shift +1, juz equals `juz_for_seat`; `create_group` with unit; `start_khatma` with start portion; day generation stores unit/cycle fields; pending unit applies only at cycle boundary (immediately while forming); full_khatma per cycle incl. late; volunteer/override/leave on non-juz days
- [X] T005 Migration `20261115090001_portion_units.sql`: enum, columns (groups, group_days, assignments.portion_index + backfill), `portion_count`, `portion_for_seat`, updated `create_group`, `start_khatma`, `update_group_settings`, `create_day_assignments`, `ensure_current_group_day`/`generate_due_group_days` (pending unit at boundary), `recompute_day_counts` + cycle full_khatma
- [X] T006 Migration `20261115090002_portion_reads.sql`: `get_dashboard` (portion_unit, cycle block, pending unit, assignments with portion_index), `get_history`/`get_history_day` by cycle, `get_invite_preview`, `search_public_groups`, `get_my_groups` add portion_unit
- [X] T007 Run all existing pgTAP files: juz behavior unchanged (SC-003)

## Phase 3: App data layer

- [X] T008 [P] Entities/models: `portionUnit` on MyGroupSummary, PublicGroupCard, InvitePreview, DashboardSnapshot; `portionIndex` on Assignment (fallback to juz); `CycleInfo`; `pendingPortionUnit`; JSON mappers + tests
- [X] T009 Repositories: `createGroup(input with unit)`, `startKhatma(groupId, startPortion)`, `updateGroupSettings(unit)`; history cycles; tests

## Phase 4: UI (US1-US4)

- [X] T010 [US1] Create group S4: unit selector (5 options with daily amount + khatma days) + CreateGroupCubit field; widget tests (RTL, 200%, dark, 320dp)
- [X] T011 [US1] Unit chip on group card S1, discovery card S2, invite preview S3
- [X] T012 [US2] Dashboard S5: portion card (name + range from metadata), cycle header (day k of C, completed of N), seat tiles labelled by portion, rest-day state "لا ورد اليوم"; forming start sheet picks start portion 1..N; tests
- [X] T013 [US2] Personal assignment S6: portion name + range; tests
- [X] T014 [US3] History S10 grouped by cycle with full-khatma badge per cycle; day detail; tests
- [X] T015 [US4] Group settings S9: owner unit change with confirm + pending notice on dashboard; tests

## Phase 5: Polish

- [X] T016 Integration test `integration_test/portion_flow_test.dart`: create hizb group -> start -> day 1 portions 1..30 for seats
- [X] T017 Principle VII review: no hand-typed boundaries; Principle VI review of new UI
- [X] T018 flutter analyze / flutter test / all pgTAP; record in quickstart

## Dependencies

Phase 1 ∥ Phase 2. Phase 3 needs Phase 1 (unit enum) and Phase 2 contracts.
Phase 4 needs Phase 3. T012/T013 need T001 (metadata portions).

## Validation log (2026-11-15)

| Check | Result |
|---|---|
| flutter analyze | 0 issues |
| flutter test | 315 passing |
| pgTAP (11 files, hosted dev DB) | 261 passed, 0 failed (incl. 004_portion_units_test 57/57) |
| T016 integration_test/portion_flow_test.dart (Android emulator API 35) | PASS: hizb group, day 1 = hizb 1..30 for seats 1..30, cycle length 2 |
| Spec 001 regression: integration_test/group_flow_test.dart | PASS (juz behavior unchanged, SC-003) |
| T017 Principle VII | no hand-typed sura names/boundaries; portions only from quran-data.xml; checksum test green |
| T017 Principle VI | no raw colors/sizes/radii or left/right insets in features; rest-day label moved to ArabicStrings |
| iOS | not run (no macOS) |
