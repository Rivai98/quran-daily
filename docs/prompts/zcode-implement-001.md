# ZCode prompt: implement spec 001

Copy everything inside the block below into ZCode, run from the repository root
(`H:\quran_daily`) on branch `001-track-quran-groups`.

For long runs, give ZCode one phase at a time by changing the PHASE line
(e.g. `PHASE: 2A`), and review/commit between phases.

---

```text
You are implementing the Flutter + Supabase app "quran_daily" (Arabic Quran
group khatma tracker). Work on git branch 001-track-quran-groups.

PHASE: 1 through 5 (MVP). Stop after Phase 5 and report.

## Read first, in this order (mandatory, do not skip)
1. .specify/memory/constitution.md          (binding rules, v2.4.0+)
2. docs/design/design-system-mock.html      (visual reference)
3. specs/001-track-quran-groups/spec.md
4. specs/001-track-quran-groups/plan.md
5. specs/001-track-quran-groups/research.md
6. specs/001-track-quran-groups/data-model.md
7. specs/001-track-quran-groups/contracts/  (supabase-rpc.md, repository-contracts.md, ui-contract.md)
8. specs/001-track-quran-groups/quickstart.md
9. specs/002-email-password-auth/ (spec, plan, data-model, research, contracts) before Phase 2B
10. specs/001-track-quran-groups/tasks.md   (your work list)

## How to work
- Execute tasks.md strictly in order, phase by phase. Respect [P] only for
  tasks in the same phase that touch different files.
- TDD is mandatory: for every test task, write the test, run it, confirm it
  FAILS for the right reason, then implement until it passes. Never weaken or
  delete a test to make it pass.
- After finishing a task, change its "- [ ]" to "- [X]" in tasks.md.
- Commit after each completed task group (one commit per logical group, e.g.
  "feat(design-system): tokens and theme (T009-T015)"). Conventional commit
  messages. Do not push.
- At each phase checkpoint run and make green:
    flutter analyze
    flutter test
    supabase test db        (once supabase/ exists and Docker is running)
- If a command cannot run in your environment (no Docker, no emulator),
  say so explicitly in the report; never claim it passed.

## Hard rules (violations = task failed)
1. QURAN CONTENT: never type, generate, complete, or "fix" any Quranic text,
   surah name, ayah number, or juz boundary - not in code, tests, fixtures,
   comments, or docs. Read them only through QuranMetadataRepository from
   assets/quran/quran-data.xml. Tests check structure and values read from
   the file, never hard-coded names or boundaries.
2. OWNER-PROVIDED files (T007 fonts, T008 Quran data): do NOT create,
   download, or fake them. If they are missing when a task needs them, skip
   only the dependent tasks, continue with the rest, and list what is blocked.
3. DESIGN SYSTEM: no Color(0x...), fontSize:, or BorderRadius.circular( in
   lib/features/**. Use lib/core/design_system tokens and shared widgets.
   UI font is Cairo; Amiri only for quranLabel. Max one primary button per
   screen. Statuses always color + icon + Arabic label.
4. ARABIC ONLY: every user-facing string in Arabic, in
   lib/core/localization/arabic_strings.dart; numbers via ArabicNumerals.
   RTL everywhere; EdgeInsetsDirectional, never hard-coded left/right.
5. MVVM + CUBIT: data/ -> cubit/ -> view/. Cubits never import
   package:flutter/material.dart. States are immutable Equatable classes with
   a status enum and no Arabic copy, colors, or BuildContext. Widgets contain
   no business logic. Features never import sibling features.
6. SECURITY: all group writes go through SECURITY DEFINER SQL functions with
   role checks; RLS on every table. Never put the Supabase service key in the
   Flutter app, tests, or repo. Only SUPABASE_URL and SUPABASE_ANON_KEY via
   --dart-define-from-file=.env (.env is gitignored).
7. SCOPE: no push notifications, no Supabase Realtime, no Google sign-in, no
   Mushaf/Quran text (that is spec 003), no features not in tasks.md.
8. Every screen widget test covers RTL, 200% text scale, dark theme, 320dp
   width, and the 5 states (loading, content, empty, error, offline).
9. Legacy scaffold files under lib/features/quran_groups/view/ and
   lib/core/theme/ are replaced as tasks say; delete each legacy file and its
   legacy test when its replacement lands.
10. If the spec, plan, and constitution disagree, the constitution wins; if
    something is genuinely ambiguous, choose the option most consistent with
    the docs, note it in the report, and continue. Do not edit the
    constitution or spec.

## Report when you stop
- Tasks completed (IDs) and commits created.
- Output summary of flutter analyze / flutter test / supabase test db.
- Tasks skipped or blocked, with the reason (e.g. missing owner assets).
- Any decision you had to make that the docs did not cover.
```

---

## Phase-by-phase variant

Change the `PHASE:` line to one of these and keep the rest:

| PHASE | Tasks | Done when |
|-------|-------|-----------|
| `1` | T001-T008 | deps updated, supabase/ initialized (T007/T008 are yours) |
| `2A` | T009-T024 | design system tests green |
| `2B` | T025-T034 | sign up / sign in / sign out work |
| `2C` | T035-T052 | schema + metadata + DI green |
| `3` | US2 | create group + start khatma + rotation |
| `4` | US1 | dashboard |
| `5` | US3 | completion + offline (MVP done) |
| `6-8` | US4, US5, US6 | joining, volunteering, management |
| `9-10` | US7 + polish | history, settings, integration tests |

## Before you start ZCode (your part)

1. Download Cairo and Amiri TTF files from Google Fonts into `assets/fonts/` (T007).
2. Download Tanzil `quran-data.xml` from the official Tanzil metadata page into
   `assets/quran/`, write `SOURCE.md` matching the "Quran Content Source" table in
   `specs/001-track-quran-groups/plan.md`, and generate `checksums.sha256` (T008).
3. Install Docker Desktop and the Supabase CLI for `supabase start` / `supabase test db`.
4. Create `.env` from `.env.example` with your Supabase URL and anon key.
