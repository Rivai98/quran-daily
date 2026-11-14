# Implementation Plan: Quran Group Reading Tracker

**Branch**: `001-track-quran-groups` | **Date**: 2026-11-14 | **Spec**: [spec.md](./spec.md)

**Input**: Amended feature specification from `specs/001-track-quran-groups/spec.md` (Clarifications Session 2026-11-14). Constitution v2.4.0.

## Summary

Build the Arabic-first Flutter app core: any signed-in user creates a group with 30 seats, members join through public discovery, one-tap matching, or invite codes, and the Owner starts a khatma. From then on the backend materializes one group day per group-local date where every seat advances one juz (30 wraps to 1). Members mark their juz complete (offline-capable), volunteer for juz of empty seats, and review history. Owner/Supervisors manage requests, seats, roles, and today-only overrides.

This plan also delivers, as blocking foundations:
1. **Design system foundation** (constitution Principle VI) in `lib/core/design_system/`, because 001 is the first UI feature.
2. **Email/password authentication** exactly as designed in [specs/002-email-password-auth/plan.md](../002-email-password-auth/plan.md) and its contracts, because every 001 flow needs a signed-in user. 002 has no separate `tasks.md`; its implementation is tracked in this feature's Phase 2B.
3. **Verified juz metadata** (Principle VII) loaded from an owner-provided Tanzil file (see Quran Content Source below).

## Quran Content Source (Principle VII)

| Item | Value |
|------|-------|
| Source | Tanzil.net, "Quran Metadata" page (`https://tanzil.net/docs/quran_metadata`) |
| File | `quran-data.xml` (juz starts as sura/aya, sura names and ayah counts) |
| Edition / version | Tanzil Quran Metadata v1.0 (the version string in the file header MUST be copied verbatim into `assets/quran/SOURCE.md`) |
| Riwayah / numbering | Hafs 'an 'Asim, Kufan ayah count (6236 ayat), standard Madani juz boundaries |
| License | `cc-by` (Creative Commons Attribution), as stated in the file header `license="cc-by"`; attribution to Tanzil.net in `SOURCE.md` and the app's licenses page |
| Content used | Juz start sura/aya, sura Arabic names, sura ayah counts only. No ayah text. |

If the downloaded file's header shows a different version or license, the owner updates this table in the same PR that adds the file. Agents never create, edit, or reformat the file.

## Technical Context

**Language/Version**: Dart SDK `^3.10.4` (Flutter stable); SQL/PLpgSQL for Supabase migrations; TypeScript (Deno) for the two admin Edge Functions from spec 002.

**Primary Dependencies**: `flutter_bloc`, `equatable`, `get_it`, `supabase_flutter`, `sqflite`, `path_provider`, `shared_preferences`, `flutter_localizations`, `intl`, `flutter_timezone` (device timezone for matching/defaults), `share_plus` (share invite), `app_links` (open `qurandaily://join/<code>`), `connectivity_plus` (offline detection). Dev: `flutter_test`, `bloc_test`, `mocktail`, `integration_test`, `sqflite_common_ffi` (DB tests on host). **Remove** `google_sign_in`.

**Storage**: Supabase PostgreSQL is the source of truth (groups, memberships, join requests, invites, group days, assignments, completion records, profiles). `pg_cron` runs rollover/close jobs every minute. Local SQLite caches dashboard snapshots, history summaries, my groups, and the personal sync queue; `shared_preferences` stores selected group and Quran text scale.

**Testing**: TDD per constitution III. Cubit tests (`bloc_test`), repository tests (mocktail), widget tests (RTL + 200% text scale + dark theme for every screen), SQL tests with pgTAP via `supabase test db --remote` against the linked hosted dev project (no Docker; research R16), `integration_test` journeys on Android emulator and iOS simulator.

**Target Platform**: iOS 15+, Android API 26+. Web/desktop out of scope (platform folders may remain but are not built or tested).

**Project Type**: Mobile app + Supabase backend (versioned under `supabase/`).

**Performance Goals**: Cached dashboard visible < 1 s after launch; network refresh < 3 s; completion tap updates UI < 300 ms (optimistic); new group day visible ≤ 1 min after rollover (SC-012); 30-cell grid at 60 fps.

**Constraints**: Arabic-only RTL UI; design tokens only (no raw colors/sizes in features); fonts bundled; offline personal loop; all management and rotation rules enforced server-side (RLS + `SECURITY DEFINER` functions); no Quranic text authored by agents; no notifications.

**Scale/Scope**: ≤ 30 active members per group, unlimited groups (owner cap 3), target 10k users / 1k active groups for v1; ~12 screens, 12 Cubits (plus `AuthCubit` from spec 002), ~25 RPC functions.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate

| Gate | Status | Evidence |
|------|--------|----------|
| I. Offline-Resilient Core | PASS | Today's assignment, own status, and queued complete/undo work offline from SQLite; discovery, joining, volunteering, management require network (allowed shared coordination). Fonts bundled. |
| II. Mobile-First, Arabic-First UX | PASS | Arabic-only RTL root, Arabic-Indic numerals formatter, 320 dp / 200% text scale, dark theme, 48 dp targets. |
| III. Test-First | PASS | Every task group starts with failing tests; widget tests include RTL/200%/dark runs; pgTAP for RLS and rotation. |
| IV. MVVM with Cubit | PASS | `data/` → `cubit/` → `view/` per feature; repositories behind interfaces; DI via `get_it` + `BlocProvider`. No sibling-feature imports: `SettingsRepository` lives in `lib/core/settings/`, and `quran_groups`/`settings` reach auth only through the core `SessionGateway` interface (implemented by `features/auth`). Cubits never depend on other Cubits. |
| V. Simplicity & YAGNI | PASS | Rotation is computed by one SQL function; no Realtime subscriptions (refresh on open/resume/pull and after mutations); use cases only where logic exists (sync queue, optimistic completion). |
| VI. Design System | PASS | Foundation built in Phase 2A before any screen; screens use shared widgets only. |
| VII. Quran Content Integrity | PASS | Juz ranges and surah names read from owner-provided Tanzil `quran-data.xml` under `assets/quran/` with SHA-256 test; ordinal juz names are UI copy, not Quran text; no ayah text in this feature. |

### Post-Design Gate

| Gate | Status | Evidence |
|------|--------|----------|
| I | PASS | [data-model.md](./data-model.md) local tables + sync queue; [repository-contracts.md](./contracts/repository-contracts.md) offline rules. |
| II | PASS | [ui-contract.md](./contracts/ui-contract.md) global rules, states, copy keys. |
| III | PASS | [quickstart.md](./quickstart.md) red-green validation per layer. |
| IV | PASS | Cubit/repository boundaries fixed in repository contracts. |
| V | PASS | No Realtime, no pause, no custom portions, no admin console. |
| VI | PASS | UI contract references only Principle VI tokens/components. |
| VII | PASS | `QuranMetadataRepository` reads verified file; checksum test; tasks forbid authoring data. |

## Project Structure

### Documentation (this feature)

```text
specs/001-track-quran-groups/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- supabase-rpc.md
|   |-- repository-contracts.md
|   `-- ui-contract.md
|-- checklists/
|   |-- requirements.md
|   `-- ux.md               # historical (pre-amendment), superseded by constitution VI
`-- tasks.md
```

### Source Code (repository root)

```text
assets/
|-- fonts/                  # Cairo, Amiri (owner downloads, OFL)
`-- quran/                  # quran-data.xml (Tanzil), SOURCE.md, checksums.sha256 (owner provides)
lib/
|-- main.dart
|-- app/                    # app.dart (auth gate), bootstrap.dart, router.dart
|-- core/
|   |-- config/  di/  errors/  network/  storage/  sync/
|   |-- auth/               # session_gateway.dart (interface; impl in features/auth)
|   |-- settings/           # SettingsRepository (selected group, Quran text scale)
|   |-- localization/       # arabic_strings.dart, arabic_numerals.dart
|   |-- design_system/      # app_colors, app_typography, app_spacing, app_radius, app_theme
|   |   `-- widgets/        # AppButton, StatusChip, PartTile, StatePanel, ...
|   `-- quran/              # QuranMetadataRepository (reads assets/quran)
`-- features/
    |-- auth/               # spec 002 (data/, cubit/, view/)
    `-- quran_groups/
        |-- data/           # entities/, models/, data_sources/, repositories/, use_cases/
        |-- cubit/          # selected_group/, group_list/, create_group/, discovery/, join/,
        |                   # dashboard/, assignment/, members/, join_requests/,
        |                   # group_settings/, history/
        `-- view/           # screens/, widgets/
lib/features/settings/      # SettingsCubit + screen (text size, sign-out via SessionGateway)
supabase/
|-- config.toml
|-- migrations/             # applied in filename order; auth first because groups reference profiles:
|                           # 001_email_password_auth, 002_core_schema, 003_group_lifecycle_functions,
|                           # 004_rotation_jobs (enables pg_cron), 005_dashboard_functions,
|                           # 006_completion_functions, 007_join_functions, 008_volunteer_functions,
|                           # 009_management_functions, 010_history_functions
|-- functions/              # admin-create-user/, admin-reset-password/, _shared/ (spec 002)
`-- tests/                  # pgTAP: rls, rotation, joins, volunteering, history
test/                       # mirrors lib/
integration_test/
```

**Structure Decision**: One Flutter app, feature-first MVVM. `features/auth` follows spec 002. `features/quran_groups` owns all group behavior. `features/settings` is tiny but separate so `quran_groups` does not own sign-out. Shared Quran metadata lives in `core/quran` because spec 003 (Mushaf) will reuse it. Existing scaffolded screens under `lib/features/quran_groups/view/` predate the amendment and design system; they are rebuilt, not patched.

## Implementation Order (dependency summary)

1. Phase 1 Setup → Phase 2A Design system → Phase 2B Auth (spec 002) → Phase 2C Core data + backend schema + metadata.
2. P1 stories: US2 (create + start) → US1 (dashboard) → US3 (completion). US2 first because there is no dashboard without a started group.
3. P2: US4 join → US5 volunteer → US6 manage. P3: US7 history.
4. Until US4 lands, US2/US1/US3 are validated with members inserted by a test-only SQL seed helper (`supabase/tests/helpers/seed_members.sql`); the first real-user release therefore includes US4 (a group with only its Owner is not a useful release).

## Complexity Tracking

| Item | Why Needed | Simpler Alternative Rejected Because |
|------|------------|-------------------------------------|
| `pg_cron` jobs | Days must exist and close at each group's local rollover (SC-012) | Client-side creation: absent clients would leave days missing and allow tampering. A lazy `ensure_current_day` call is kept as a fallback. |
| Auth implemented inside 001 tasks | 001 cannot be tested without sign-in | Separate 002 tasks first: duplicates setup and delays the first usable slice. |
