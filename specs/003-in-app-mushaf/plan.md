# Implementation Plan: In-App Mushaf

**Branch**: `003-in-app-mushaf` | **Date**: 2026-11-15 | **Spec**: [spec.md](./spec.md)
**Constitution**: v2.4.0 (binding, especially VII Quran Content Integrity)

## Summary

Bundle the King Fahd Complex (KFGQPC) Hafs Uthmanic text and its matching
font, render the 604 Madinah pages offline, open any assignment at its start
ayah, offer completion at its end ayah, browse by surah/juz/hizb/page, keep the
last position and bookmarks (synced), and show an owner-approved khatm dua.

## Quran source (Principle VII) — owner approval required

| Item | Decision |
|------|----------|
| Publisher | King Fahd Glorious Quran Printing Complex (KFGQPC), Madinah |
| Package | "KFGQPC Uthmanic Script HAFS" font + its Hafs text data file (the text file published together with the font, with surah/ayah/page/juz per ayah), latest version on fonts.qurancomplex.gov.sa |
| Riwayah | Hafs 'an 'Asim, Madinah Mushaf 604 pages |
| Files in repo | `assets/quran/hafs/` text data file and `assets/fonts/kfgqpc_hafs/` font, byte-for-byte as downloaded |
| Records | `assets/quran/hafs/SOURCE.md` (URL, version, date, license text, sizes), SHA-256 in `assets/quran/checksums.sha256` |
| Cross-check | A test verifies the per-ayah page numbers of the KFGQPC file against the existing Tanzil `quran-data.xml` `<page>` starts (604 pages, 6236 ayahs, 114 surahs, 30 juz starts, 240 quarter starts) |
| Download | The project owner downloads the files (or explicitly approves the download). No agent edits them. |

Why KFGQPC text + KFGQPC font together: the font is built for that exact text
encoding, so all marks render correctly; mixing another text with this font
risks wrong glyphs.

## Technical Context

Flutter (Dart ^3.10.4), MVVM + Cubit, get_it, sqflite, hosted Supabase. No new
packages for rendering (Flutter `Text`/`RichText` with the bundled font).
Migration range: `2026111514NNNN`.

## Constitution Check

| Principle | Compliance |
|-----------|------------|
| I Offline core | All text and font bundled; bookmarks local first, synced via queue |
| II Arabic/RTL | RTL page order; Arabic numerals; 200% text with vertical scroll |
| III Test-first | Data parsing/integrity tests, portion→page tests for all 5 units, cubit and widget tests |
| IV MVVM + Cubit | MushafRepository, ReaderCubit, MushafIndexCubit, BookmarksCubit |
| V Simplicity | One text file + one font; page model derived at load, no per-page assets |
| VI Design system | Chrome uses tokens/Cairo; Quran text only in the KFGQPC font |
| VII Quran integrity | Source table above, checksums, no authored text, test that no Quran text exists outside source files |

Gate: PASS once the owner approves the source.

## Design

- **MushafRepository** (`lib/core/quran/mushaf/`): verifies checksums, parses
  the KFGQPC file once (isolate), builds `MushafPage` (ayah refs per page) and
  lookups `pageOf(AyahRef)`. Text is only ever read from the parsed file.
- **Portion range**: `QuranMetadataRepository.portion(unit, index)` (spec 004)
  gives start/end AyahRef → `pageOf(start)`, `pageOf(end)`.
- **Reader** (`lib/features/mushaf/`): `PageView` reversed for RTL, one page per
  item, header (surah, juz, page), highlighted start/end ayahs, portion banner,
  "تمت القراءة" on the end page via `KhatmaRepository.markComplete`.
- **Index**: tabs السور / الأجزاء / الأحزاب / الصفحات, search by surah name.
- **Position and bookmarks**: sqflite tables + `reading_positions` and
  `bookmarks` tables in Supabase (RLS: owner only), synced through the
  existing sync queue.
- **Khatm dua**: `assets/text/khatm_dua.txt` + `SOURCE.md` supplied by the
  owner; feature flag = file present and checksum recorded.
- **Entry points**: enable spec 001's reserved "اقرأ الآن" on the assignment
  card and personal assignment screen; "المصحف" action in the groups app bar
  (moves to the Home tab when spec 005 lands).

## Work split

| Agent | Scope |
|-------|-------|
| codex-1 | Backend tables + RLS + pgTAP (T001-T003) |
| codex-2 | MushafRepository, integrity, page model, portion→page (T004-T009) |
| codex | Reader, index, bookmarks UI, entry points (T010-T020), after T009 contracts are stubbed |
