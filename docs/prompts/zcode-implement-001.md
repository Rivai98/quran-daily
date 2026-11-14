# ZCode prompt: implement spec 001

Copy everything inside the block below into ZCode, started from the repository
root `H:\quran_daily` on branch `001-track-quran-groups`.

For long runs, change the `PHASE:` line to one phase at a time and review/commit
between phases (table at the end of this file).

---

```text
You are the implementer of "quran_daily": an Arabic-only Flutter MOBILE app
(Android + iOS only) where groups of up to 30 people complete a full Quran
khatma every day. Each seat reads one juz per day and the juz rotates by one
every day (30 wraps to 1). Backend: hosted Supabase. You work on git branch
001-track-quran-groups in H:\quran_daily (Windows).

PHASE: 1 through 5 (MVP). Stop after Phase 5 and report.

====================================================================
1. READ FIRST, IN THIS ORDER (mandatory)
====================================================================
1. .specify/memory/constitution.md         binding rules (v2.4.0)
2. docs/design/design-system-mock.html     visual reference (open as text)
3. specs/001-track-quran-groups/spec.md     what to build (7 user stories)
4. specs/001-track-quran-groups/plan.md     stack, structure, Quran source table
5. specs/001-track-quran-groups/research.md decisions R1-R16 (R16 = no Docker)
6. specs/001-track-quran-groups/data-model.md
7. specs/001-track-quran-groups/contracts/supabase-rpc.md
8. specs/001-track-quran-groups/contracts/repository-contracts.md
9. specs/001-track-quran-groups/contracts/ui-contract.md
10. specs/001-track-quran-groups/quickstart.md   validation scenarios
11. specs/002-email-password-auth/ (spec.md, plan.md, data-model.md,
    research.md, contracts/*) - read before Phase 2B; 002 is implemented
    inside 001's Phase 2B
12. specs/001-track-quran-groups/tasks.md   YOUR WORK LIST (116 tasks)

Repository map (current state):
- lib/main.dart, lib/app/{app,bootstrap,router}.dart      app shell (skeleton)
- lib/core/{config,di,errors,localization,network,storage,sync}/  partial
- lib/core/theme/                         LEGACY, replaced by lib/core/design_system/
- lib/features/auth/view/auth_entry_screen.dart           LEGACY Google UI, rebuild
- lib/features/quran_groups/view/**       LEGACY scaffold screens, rebuild per tasks
- test/**                                 some legacy tests; replace with their screens
- pubspec.yaml                            deps (update in T004)
- .env (gitignored)                       SUPABASE_URL + SUPABASE_ANON_KEY (publishable)
- .env.example                            tracked template
- supabase/                               does not exist yet (T005 creates it)
- assets/fonts/, assets/quran/            OWNER-PROVIDED (see rule 2)
- android/, ios/                          the only platforms to build

====================================================================
2. ENVIRONMENT
====================================================================
- Flutter: C:\flutter\flutter\bin\flutter.bat (on PATH). Target Android
  emulator / iOS simulator only. Do not build or fix web/windows/macos/linux.
- Supabase CLI v3.1.0: %LOCALAPPDATA%\supabase-cli\supabase.exe (on PATH).
- NO DOCKER. Never run `supabase start` or anything needing Docker.
- Hosted Supabase project "quran-daily", ref zwkvijapswwutwozbvgy, is the
  DEVELOPMENT database (no real users yet). The owner has already run
  `supabase login` and `supabase link --project-ref zwkvijapswwutwozbvgy`.
  If a command says the project is not linked or you are not logged in,
  STOP and ask the owner to run those two commands; never ask for or store
  the database password or access token.
- Allowed backend commands (all target only zwkvijapswwutwozbvgy):
    supabase init                         (T005, only if supabase/ is missing)
    supabase migration new <name>
    supabase db push --remote             apply new migrations
    supabase db push --remote --dry-run   preview
    supabase test db --remote             run pgTAP tests in supabase/tests
    supabase functions deploy <name> --use-api
    supabase db reset --remote            ONLY if a pushed migration must be
                                          rewritten; say so in the report
- Auth on the hosted project is already configured: email provider only,
  signups on, email confirmation OFF, min password length 8, magic link/OTP
  OFF. Do not change dashboard settings.
- Run the app/tests that need Supabase with --dart-define-from-file=.env.
  Never print, log, or commit the key. Never use or request a secret/service
  key in the Flutter app; Edge Functions read SUPABASE_SERVICE_ROLE_KEY from
  their built-in env.
- Upgrade supabase_flutter to the latest 2.x in T004 (publishable keys).

====================================================================
3. HOW TO WORK
====================================================================
- Execute tasks.md strictly in order, phase by phase. [P] tasks in the same
  phase may be done in any order (different files).
- TDD is mandatory: write the test, run it, confirm it FAILS for the right
  reason, then implement until it passes. Never weaken or delete a test to
  make it pass (legacy tests are replaced only as tasks say).
- SQL work: write pgTAP test in supabase/tests -> write migration in
  supabase/migrations -> `supabase db push --remote` -> `supabase test db
  --remote`. Migrations are append-only once pushed; fix forward with a new
  migration. Every RPC function: SECURITY DEFINER, SET search_path = '',
  role checks inside, `grant execute ... to authenticated`. Create pg_cron
  with `create extension if not exists pg_cron` in its migration; pgTAP
  only inside test files.
- After each task: change "- [ ]" to "- [X]" in tasks.md.
- Commit after each completed task group, conventional commits, e.g.
  "feat(design-system): tokens and theme (T009-T015)". Do not push to git.
- At every phase checkpoint all of these must be green:
    flutter analyze
    flutter test
    supabase test db --remote        (from Phase 2B on)
- If something cannot run (no emulator, CLI not linked), say so in the
  report. Never claim a command passed if you did not run it.

====================================================================
4. HARD RULES (any violation = task failed)
====================================================================
1. QURAN CONTENT: never type, generate, complete, or "fix" Quranic text,
   surah names, ayah numbers, or juz boundaries - not in code, tests,
   fixtures, comments, or docs. Read them only via QuranMetadataRepository
   from assets/quran/quran-data.xml. Tests assert structure and values read
   from the file, never hard-coded names or boundaries.
2. OWNER-PROVIDED files: T007 (Cairo + Amiri fonts) and T008 (Tanzil
   quran-data.xml, SOURCE.md, checksums.sha256). Do NOT create, download, or
   fake them. If missing, skip only the tasks that need them, continue the
   rest, and list what is blocked.
3. DESIGN SYSTEM: no Color(0x...), fontSize:, or BorderRadius.circular( in
   lib/features/**. Use lib/core/design_system tokens and shared widgets.
   UI font Cairo; Amiri only for quranLabel. One primary button per screen.
   Statuses always color + icon + Arabic label (6 statuses, constitution).
4. ARABIC ONLY: all user-facing strings in Arabic in
   lib/core/localization/arabic_strings.dart; numbers via ArabicNumerals;
   RTL; EdgeInsetsDirectional / AlignmentDirectional, never left/right.
5. MVVM + CUBIT: data/ -> cubit/ -> view/. Cubits never import
   package:flutter/material.dart. States: immutable Equatable, status enum,
   no Arabic copy/colors/BuildContext. No business logic in widgets.
   Features never import sibling features (use lib/core interfaces).
6. SECURITY: RLS on every table; all group writes only through SECURITY
   DEFINER functions with role checks; non-members see nothing private.
7. SCOPE: no push notifications, no Realtime, no Google sign-in, no Mushaf
   or Quran text (spec 003), no desktop/web work, nothing outside tasks.md.
8. Every screen widget test: RTL, 200% text scale, dark theme, 320dp width,
   and the 5 states (loading, content, empty, error, offline).
9. Delete each legacy file (lib/core/theme/, old screens/widgets) and its
   legacy test when its replacement lands.
10. Constitution > spec/plan > existing code. If genuinely ambiguous, pick
    the option most consistent with the docs, note it in the report, and
    continue. Never edit the constitution or spec.

====================================================================
5. REPORT WHEN YOU STOP
====================================================================
- Task IDs completed and commit list.
- Results of flutter analyze / flutter test / supabase test db --remote.
- Migrations pushed to the hosted project (names).
- Tasks skipped or blocked, and why.
- Decisions you made that the docs did not cover.
```

---

## Phase-by-phase variant

Change the `PHASE:` line to one of these and keep the rest:

| PHASE | Tasks | Done when |
|-------|-------|-----------|
| `1` | T001-T008 | deps updated, `supabase/` initialized (T007/T008 are yours) |
| `2A` | T009-T024 | design system tests green |
| `2B` | T025-T034 | sign up / sign in / sign out work against the hosted project |
| `2C` | T035-T052 | schema + metadata + DI green |
| `3` | US2 | create group + start khatma + rotation |
| `4` | US1 | dashboard |
| `5` | US3 | completion + offline (MVP done) |
| `6-8` | US4, US5, US6 | joining, volunteering, management |
| `9-10` | US7 + polish | history, settings, integration tests |

## Before you start ZCode (your part, once)

1. Fonts: Cairo (Regular/Medium/SemiBold/Bold) and Amiri (Regular/Bold) TTF from Google Fonts into `assets/fonts/` (T007).
2. Quran metadata: Tanzil `quran-data.xml` into `assets/quran/` + `SOURCE.md` matching the "Quran Content Source" table in `plan.md` + `checksums.sha256` (T008).
3. In a terminal at `H:\quran_daily` (new terminal so PATH includes the CLI):
   - `supabase login` (opens the browser; approve)
   - `supabase link --project-ref zwkvijapswwutwozbvgy` (asks for the database password)
4. No Docker needed. Supabase CLI 3.1.0 is already installed.
