# Tasks: In-App Mushaf

**Plan**: [plan.md](./plan.md). Test-first.

## Phase 0: Source files (owner)
- [X] T000 Owner approves the source and downloads (or approves the download of) the KFGQPC Hafs font + text data file; files placed byte-for-byte under `assets/quran/hafs/` and `assets/fonts/kfgqpc_hafs/`; `SOURCE.md` + checksums recorded. OWNER-PROVIDED.
- [ ] T000b Owner provides the khatm dua text + its source (optional; feature hidden without it). OWNER-PROVIDED.

## Phase 1: Backend (codex-1)
- [ ] T001 pgTAP `supabase/tests/003_mushaf_sync_test.sql`: owner-only RLS on `reading_positions` and `bookmarks`; upsert last page; bookmark CRUD
- [ ] T002 Migration `supabase/migrations/20261115140001_mushaf_sync.sql`: tables, RLS, grants
- [ ] T003 Apply to DEV; run all pgTAP files: 0 failed

## Phase 2: Mushaf data (codex-2)
- [ ] T004 [P] Tests `test/core/quran/mushaf/mushaf_integrity_test.dart`: checksums match; 604 pages, 6236 ayahs, 114 surahs; page starts equal Tanzil `quran-data.xml` `<page>` entries
- [ ] T005 `lib/core/quran/mushaf/`: checksum verification, parser (isolate), `MushafPage`, `AyahRef`, `pageOf`
- [ ] T006 [P] Tests `test/core/quran/mushaf/portion_pages_test.dart`: for every portion of all 5 units, start/end pages equal `pageOf(start/end)` from metadata
- [ ] T007 `MushafRepository.portionPages(unit, index)`
- [ ] T008 [P] Test `test/core/quran/no_quran_text_in_repo_test.dart`: no Arabic Quran ayah strings in `lib/`, `test/` (except reading the source files)
- [ ] T009 DI registration; integrity failure state

## Phase 3: Reader + UI (codex)
- [ ] T010 [P] Cubit tests `test/features/mushaf/cubit/reader_cubit_test.dart` (open page, open portion, highlight, completion, offline)
- [ ] T011 `ReaderCubit`
- [ ] T012 Reader screen: RTL PageView, page header, ayah rendering in KFGQPC font, highlights, portion banner, "تمت القراءة" on end page, 200% text scroll, dark mode
- [ ] T013 [P] Widget tests for the reader (RTL, dark, 320dp, 200%)
- [ ] T014 Index screen (surahs / juz / hizb / pages, search) + tests
- [ ] T015 Last position + bookmarks: sqflite + sync, long-press "إضافة علامة", bookmarks list + tests
- [ ] T016 Enable "اقرأ الآن" entry points (assignment card, personal assignment) and "المصحف" app-bar action + tests
- [ ] T017 Khatm dua sheet behind the asset flag + tests
- [ ] T018 Licenses page attribution (KFGQPC, Tanzil)

## Phase 4: Validation (orchestrator)
- [ ] T019 Integration test `integration_test/mushaf_flow_test.dart`: hizb group → "اقرأ الآن" → start page → end page → "تمت القراءة" → dashboard completed
- [ ] T020 analyze 0, all tests green, pgTAP 0 failed, phone check; validation log; merge to main

## Validation log
_(filled at T020)_
