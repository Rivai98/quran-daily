<!--
SYNC IMPACT REPORT
==================
Version change: 2.1.0 -> 2.2.0
Bump type: MINOR - New binding principle VII. Quran Content Integrity (verified
  sources only, checksums, no authored Quranic text by any human or AI agent)
  and Agent Compliance rule 6.

Previous amendment (same day): 2.0.0 -> 2.1.0
Bump type: MINOR - New binding principle (VI. Design System) and materially
  expanded guidance for UX, MVVM layering, and AI-agent compliance. No principle
  was removed or redefined in a backward-incompatible way.

Modified principles (old -> new):
  II. Mobile-First UX & Accessibility -> II. Mobile-First, Arabic-First UX &
      Accessibility (expanded: Arabic-Indic numerals, 200% text scale, 320dp
      width, dark mode, reduced motion)
  IV. MVVM Architecture with Cubit -> IV. MVVM Architecture with Cubit
      (expanded: State class rules, use cases, DI, design-system imports)

Added sections:
  VI. Design System (NON-NEGOTIABLE) - typography, color tokens, spacing,
      radius, elevation, buttons, components, screen states, iconography,
      motion, copy.
  Design Reference - docs/design/design-system-mock.html as visual source of truth.
  Agent Compliance - rules binding every human or AI agent on any spec.

Removed sections: none

Templates reviewed:
  OK  .specify/templates/plan-template.md - Constitution Check gate is generic
      ("[Gates determined based on constitution file]"); plans now MUST list
      gates I-VI including Design System compliance.
  OK  .specify/templates/spec-template.md - No mandatory section added; UI specs
      reference Principle VI instead of redefining visual rules.
  OK  .specify/templates/tasks-template.md - Polish phase gains a design-system
      compliance task.
  OK  CLAUDE.md / AGENTS.md - Point every agent to this constitution and the
      design reference before working on any spec.
  N/A .specify/templates/commands/ - Directory not present in this workspace.

Follow-up (code, not governance):
  - Existing lib/core/theme/* and feature widgets predate Principle VI and MUST
    be migrated (fonts bundled, tokens, components) by a dedicated feature.

Deferred TODOs: none
-->

# quran_daily Constitution

## Core Principles

### I. Offline-Resilient Core

The app MUST keep the personal Quran assignment loop usable without an internet
connection after the relevant group and day have been opened on the device.
Quran part metadata, Arabic labels, reading ranges, today's assignment, the
user's own completion state, and pending personal completion operations MUST be
bundled or locally cached.

Network calls are permitted for authenticated shared group coordination:
Supabase Auth, public group discovery, join requests, organizer approvals,
assignment publishing, shared progress refresh, and cross-device sync. When
shared data may be stale because the device is offline, the UI MUST label that
state clearly and MUST NOT present stale shared progress as fresh truth.

A user opening the app in airplane mode after the relevant group/day has been
cached MUST reach their cached assignment and personal completion action within
one tap from the selected group dashboard. Full Quran text and audio are not
required unless a feature explicitly includes them. Fonts and icons MUST be
bundled as app assets; runtime font downloading (e.g. `google_fonts` HTTP
fetching) is prohibited.

**Rationale**: Reliable daily worship requires local access to the member's own
assignment and completion flow, while group membership, approval, and shared
progress require an authenticated source of truth across devices.

### II. Mobile-First, Arabic-First UX & Accessibility

- Every screen MUST be designed for touch-first phone use (iOS 15+, Android
  API 26+) and MUST work at 320 logical-pixel width with no horizontal overflow.
- The whole app MUST run in Arabic with `TextDirection.rtl` set at the app root.
  English user-facing copy is prohibited. Only inherently LTR content (email
  addresses, URLs) is rendered LTR inside its own field.
- Directional icons (back, forward, chevrons, progress arrows) MUST mirror in
  RTL. Leading/trailing MUST use `EdgeInsetsDirectional` / `AlignmentDirectional`;
  hard-coded `left`/`right` in layout code is prohibited.
- Numerals in user-facing copy MUST use Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩)
  through one shared formatter in `lib/core/localization/`.
- Layouts MUST remain usable at 200% system text scale: no clipped text, no
  hidden primary action, no overflow stripes.
- Every interactive target MUST be at least 48x48 logical pixels.
- Normal text MUST meet WCAG 2.1 AA contrast (4.5:1); large text and icons
  MUST meet 3:1, in both light and dark themes.
- Light and dark themes MUST both be supported and follow the system setting.
- Animations MUST respect the platform reduce-motion setting.
- Every interactive or informative widget without visible text MUST have an
  Arabic semantic label.

**Rationale**: The primary audience reads Arabic and uses the app daily, often
before dawn or late at night. Accessibility is non-negotiable for a devotional
tool.

### III. Test-First (NON-NEGOTIABLE)

TDD is mandatory for all business logic and widget code:
- Tests MUST be written and confirmed to fail before implementation begins.
- Red-Green-Refactor cycle MUST be followed.
- Unit tests cover Cubit logic and repository contracts; widget tests cover View
  behavior; integration tests cover user journeys end-to-end.
- Widget tests for every screen MUST include an RTL run, a 200% text-scale run,
  and a dark-theme run.
- No feature is considered complete until its tests pass on both iOS and Android
  simulator targets.

**Rationale**: Daily reading tracking and Quran data integrity require high
correctness confidence. Cubits are trivially unit-testable without the Flutter
framework, making this principle practical at scale.

### IV. MVVM Architecture with Cubit

Every feature MUST follow the Model-View-ViewModel (MVVM) pattern implemented
with Cubit from the `flutter_bloc` package. The folder structure for each feature
is non-negotiable:

```text
lib/features/<feature_name>/
|-- data/          # Model: entities, models (DTOs), data sources,
|                  #        repository interfaces + impls, use cases
|-- cubit/         # ViewModel: Cubit class(es) + State class(es)
`-- view/          # View: screens/ and widgets/ (Flutter widgets only)
```

Rules:
- **Model layer** (`data/`): MUST NOT import Flutter widgets or Cubit classes.
  Repositories hide whether data comes from Supabase, SQLite, or cache.
  Use cases are added only when they contain real logic beyond one repository
  call (Principle V).
- **ViewModel layer** (`cubit/`): one Cubit per logical feature unit. All
  business logic and state transitions live here. Cubits MUST NOT import
  `package:flutter/material.dart` or any widget; they depend on repository
  interfaces or use cases, never on concrete data sources.
- **State classes** MUST be immutable, extend `Equatable`, and model loading,
  success, empty, error, and offline/stale explicitly (sealed classes or a
  status enum). States MUST NOT carry `BuildContext`, widgets, colors, or
  Arabic copy; the View maps state to copy.
- **View layer** (`view/`): widgets render Cubit state via `BlocBuilder`,
  `BlocSelector`, and `BlocListener`. Views MUST NOT contain business logic;
  they call Cubit methods and display state only.
- `setState` is permitted ONLY for purely local, ephemeral UI state (animation
  controllers, focus nodes, text controllers, password visibility).
- Dependencies are registered in `lib/core/di/` with `get_it` and provided to
  widgets through `BlocProvider`; widgets MUST NOT call `GetIt` for repositories.
- Cross-feature shared code lives in `lib/core/`. Feature modules MUST NOT
  import from sibling feature modules.
- Views MUST build UI from `lib/core/design_system/` (Principle VI).

**Rationale**: MVVM with Cubit enforces a clear, testable separation of concerns.
The unidirectional data flow (View -> Cubit -> State -> View) makes state changes
predictable and auditable, which is critical for a correctness-sensitive app.

### V. Simplicity & YAGNI

Start with the simplest implementation that fulfills the user story. Do not
introduce abstractions, patterns, or dependencies unless a concrete need exists
today. Three similar widgets are better than a premature abstraction. Complexity
MUST be justified in the implementation plan before being introduced.

**Rationale**: Over-engineering a v1 Flutter app slows delivery and creates
maintenance burden without user benefit.

### VI. Design System (NON-NEGOTIABLE)

The visual language is calm, focused, and devotional: warm ivory surfaces, one
deep green brand color, restrained gold accents, generous Arabic line height,
and flat surfaces separated by hairline borders. All values below are binding
tokens. They live in `lib/core/design_system/` (`app_colors.dart`,
`app_typography.dart`, `app_spacing.dart`, `app_radius.dart`, `app_theme.dart`,
and `widgets/`). Feature code MUST NOT contain raw hex colors, raw `TextStyle`
font sizes, magic spacing numbers, or ad-hoc `BorderRadius` values.

#### Typography

- **UI font**: IBM Plex Sans Arabic (weights 400, 500, 600, 700), bundled under
  `assets/fonts/`. It is used for all interface text.
- **Quran label font**: Amiri (400, 700), used ONLY for Quran part names, surah
  names, and reading-range labels. It MUST NOT be used for UI chrome.
- Cairo is not used: its wide, display-oriented letterforms lose legibility in
  dense lists and at small sizes compared with IBM Plex Sans Arabic.
- Type scale (size / line height / weight); no other sizes are permitted:

| Token | Size | Line height | Weight | Use |
|-------|------|-------------|--------|-----|
| `display` | 28 | 40 | 700 | Progress number, hero figures |
| `headline` | 22 | 32 | 700 | Screen titles |
| `title` | 18 | 28 | 600 | Card and section titles |
| `bodyLarge` | 16 | 26 | 400 | Primary reading text |
| `body` | 15 | 24 | 400 | Default body text |
| `label` | 14 | 20 | 600 | Buttons, chips, tabs |
| `caption` | 13 | 20 | 500 | Metadata, timestamps |
| `quranLabel` | 20 | 34 | 700 | Amiri; part and surah labels |

- 13 is the minimum font size. Arabic text MUST NOT use letter spacing,
  italics, or all-caps transforms.
- The user's Quran text-size setting scales `quranLabel` only, between 0.85x
  and 1.6x, on top of the system text scale.

#### Color Tokens

| Token | Light | Dark | Use |
|-------|-------|------|-----|
| `primary` | `#0E5E4E` | `#5CC4A8` | Brand, primary buttons, active state |
| `onPrimary` | `#FFFFFF` | `#00382D` | Text/icons on `primary` |
| `primaryContainer` | `#D7EDE6` | `#123F35` | Tonal buttons, selected tiles |
| `onPrimaryContainer` | `#08392F` | `#BFEADC` | Text on `primaryContainer` |
| `accent` | `#B07D2B` | `#E2B866` | Decorative highlights only, never body text |
| `background` | `#F7F5EF` | `#0F1513` | Scaffold background |
| `surface` | `#FFFFFF` | `#171F1C` | Cards, sheets, inputs |
| `surfaceMuted` | `#F0EDE4` | `#1F2925` | Grouped rows, skeletons |
| `ink` | `#1B2420` | `#E7ECE9` | Primary text |
| `inkMuted` | `#5A6560` | `#A3AFA9` | Secondary text |
| `border` | `#E2DED3` | `#2C3833` | Hairline borders, dividers |
| `danger` | `#B3261E` | `#FF8A80` | Destructive actions, errors |

Status colors (foreground / background). A status MUST always be shown as
color + icon + Arabic label together; color alone is prohibited.

| Status | Arabic label | Icon | Light fg / bg | Dark fg / bg |
|--------|--------------|------|---------------|--------------|
| completed | تمت القراءة | `check_circle` | `#1B7A47` / `#E3F3EA` | `#6FD39C` / `#173A28` |
| pending | لم يُقرأ بعد | `schedule` | `#8A5A00` / `#FBF0D9` | `#F2C063` / `#3A2E12` |
| missed | فائت | `cancel` | `#B3261E` / `#FBE6E4` | `#FF8A80` / `#3D1A18` |
| late | قُرئ متأخرًا | `history` | `#5B47B5` / `#ECE8FA` | `#B4A6FF` / `#2A2448` |

#### Spacing, Radius, Elevation

- Spacing uses a 4-point scale only: `xxs 4`, `xs 8`, `sm 12`, `md 16`,
  `lg 24`, `xl 32`, `xxl 48`.
- Screen horizontal gutter is `md` (16); vertical gap between sections is
  `lg` (24); gap inside a card is `sm` (12).
- Radius tokens: `sm 8` (chips, small tiles), `md 12` (buttons, inputs),
  `lg 16` (cards), `xl 24` (bottom sheets, dialogs), `pill` (status chips).
- Surfaces are flat: cards use `surface` + 1px `border`, no shadow. Shadows
  are allowed only on bottom sheets, dialogs, and the floating snackbar.

#### Buttons

| Variant | Flutter base | Height | Use |
|---------|--------------|--------|-----|
| Primary | `FilledButton` | 52 | The single main action of a screen |
| Tonal | `FilledButton.tonal` | 48 | Important secondary action |
| Secondary | `OutlinedButton` | 48 | Alternative or cancel-type actions |
| Text | `TextButton` | 48 | Low-emphasis links ("عرض الكل") |
| Destructive | `FilledButton` with `danger` | 48 | Only inside a confirmation dialog/sheet |
| Icon | `IconButton` | 48x48 | Toolbar actions; MUST have tooltip + semantic label |

Button rules:
- At most ONE primary button is visible per screen. On action screens it is
  full width, pinned to the bottom safe area above the keyboard.
- Labels are Arabic verbs, 1-3 words, describing the result
  (`سجّل إتمام الجزء`, `انشر التوزيع`, `اطلب الانضمام`), never "موافق" for a
  meaningful action, and never English.
- Optional icon sits at the start (right in RTL) of the label, 20dp.
- Loading: the button is disabled, keeps its width, and shows a 20dp progress
  indicator in place of the icon; repeated taps are ignored.
- Disabled buttons use 38% opacity, and the screen MUST show the reason
  (e.g. `يجب أن يكتمل عدد الأعضاء ٣٠ قبل النشر`).
- Destructive or irreversible actions (undo completion, reject request, remove
  member, sign out) MUST pass through a confirmation bottom sheet whose
  confirm button states the consequence.
- Pairs of actions place the confirming action at the start (right in RTL)
  and the cancel action at the end.

#### Components

Features MUST use these shared components from `lib/core/design_system/widgets/`
and MUST NOT re-implement them:

- `AppButton` (variants above), `AppTextField`, `AppCard`, `AppSectionHeader`.
- `StatusChip` (status table above), `PartTile` (one of 30 juz cells in the
  progress grid: Arabic-Indic number + status icon + status background).
- `ProgressHeader` (ring or bar + `display` count `١٢ / ٣٠` + percentage).
- `StatePanel` for empty, error, and no-permission states: icon, title, one
  sentence of explanation, and the next action as a button.
- `OfflineBanner` for stale/offline state with last-synced time.
- `ConfirmSheet` for confirmations; `AppSnackBar` for transient feedback.
- Loading uses skeleton placeholders shaped like the final content; full-screen
  spinners are allowed only at app startup.

#### Screen Composition and States

- Every screen MUST define and test five states: loading, content, empty,
  error, offline/stale. Error copy MUST state what happened and the next action.
- App bar: title at the start (right in RTL), `headline` or `title` style,
  `background` color, no elevation.
- Primary navigation, when used, is a Material 3 `NavigationBar` with at most
  4 destinations, each with an Arabic label and an icon.
- The member's own assignment and its primary action MUST be visible on the
  dashboard without scrolling on a 360x640 screen at 100% text scale.

#### Iconography, Imagery, Motion

- Icons: Material Symbols Rounded, 24dp default, outlined for idle and filled
  for selected states.
- Decorative Islamic geometric patterns are allowed only in headers at 6% or
  lower opacity and MUST NOT sit behind body text.
- Motion durations are 150-250 ms with standard easing; no decorative looping
  animation. Completion success may use one short check animation.

#### Copy

- Modern Standard Arabic, short and warm, addressed to the user directly.
- No emojis, no exclamation stacking, no English, no raw backend error text.
- Canonical copy (status labels, pending join text `بانتظار القبول من مالك
  المجموعة`, errors) lives in `lib/core/localization/arabic_strings.dart`.

**Rationale**: A single, strict design system keeps every screen built by any
contributor or AI model visually consistent, accessible, and calm, and lets
the whole app be restyled by changing tokens in one place.

### VII. Quran Content Integrity (NON-NEGOTIABLE)

The Quran is never authored, generated, or edited inside this project. Every
piece of Quranic content comes from a verified, recognized source and is
shipped exactly as published.

- **Approved sources**: the King Fahd Glorious Quran Printing Complex (KFGQPC)
  Mushaf data and fonts, Tanzil.net verified Uthmani text and Quran metadata,
  or an equally recognized publisher approved by the project owner. The feature
  plan that introduces Quran content MUST name the exact source, edition,
  riwayah (Hafs 'an 'Asim unless the owner decides otherwise), version, and
  license.
- **Scope**: Quran text, Mushaf page images, ayah numbering, surah names, juz
  and hizb boundaries, page mapping, and every reading-range label (e.g. the
  start and end ayah of a juz) MUST be read from the source data files. None of
  them may be typed by hand or written from memory.
- **No authoring by any agent**: no human or AI model may type, generate,
  complete, paraphrase, re-encode, normalize, "fix", or reconstruct Quranic
  text, including in code, tests, fixtures, mocks, seed data, comments, or
  documentation. Tests use the real bundled source files or reference ayat by
  surah/ayah number only.
- **Bundled and verified**: source files are stored unmodified under
  `assets/quran/` with a `SOURCE.md` (origin URL, edition, version, license,
  date) and a SHA-256 checksum. An automated test MUST fail if any checksum
  changes. Updating these files requires explicit project-owner review in the
  PR. The Mushaf is available offline (Principle I).
- **Faithful rendering**: Quran text uses only the font shipped or specified by
  its source (e.g. KFGQPC Uthmanic Hafs). It MUST NOT be truncated, ellipsized,
  letter-spaced, broken inside a word, or restyled in a way that alters
  diacritics or ayah markers. The type scale of Principle VI does not apply to
  Mushaf text; it scales only with the user's Quran text-size setting.
- **Non-Quran religious text** (e.g. دعاء الختم, opening and closing du'a)
  MUST be visually distinct from Quran text, MUST NOT use the Mushaf font or
  ayah markers, and is approved by the project owner before shipping.

**Rationale**: An error in a single letter or diacritic of the Quran is
unacceptable. Using verified sources, checksums, and a strict ban on authored
Quranic text is the only reliable protection when code is written by many
contributors and AI models.

## Design Reference

`docs/design/design-system-mock.html` is the visual source of truth for
Principle VI: tokens, typography, buttons, components, and sample screens in
light and dark themes. When the mock and this document disagree, this document
wins and the mock MUST be corrected in the same change.

## Technology Stack

- **Language**: Dart (SDK ^3.10.4)
- **Framework**: Flutter, Material 3 (`useMaterial3: true`) themed by
  `lib/core/design_system/`
- **Platforms**: iOS 15+ and Android API 26+ (primary); Web and desktop are out
  of scope for v1
- **Architecture**: MVVM - Model / Cubit (ViewModel) / View (see Principle IV)
- **State Management**: Cubit (`flutter_bloc`) + `equatable` - MANDATORY for all
  feature state. `setState` only for local ephemeral UI state.
- **Dependency Injection**: `get_it`
- **Backend**: Supabase (Auth with email/password, PostgreSQL with RLS, database
  and Edge Functions for privileged or atomic operations)
- **Local storage**: SQLite (`sqflite`) for cached assignments, Quran part
  metadata, and the sync queue; `shared_preferences` for user settings
- **Fonts**: IBM Plex Sans Arabic + Amiri, bundled assets; Mushaf font from the
  verified Quran source (Principle VII)
- **Quran data**: verified source files under `assets/quran/` with checksums
  (Principle VII)
- **Testing**: `flutter_test` (unit + widget), `bloc_test`, `mocktail`,
  `integration_test`
- **Linting**: `flutter_lints` ^6.0.0; all lints MUST pass with no suppressions
  unless justified in a code comment

## Development Workflow

- Features follow the speckit workflow: `/speckit-specify` -> `/speckit-plan` ->
  `/speckit-tasks` -> `/speckit-implement`
- The Constitution Check in `plan-template.md` MUST list and pass gates I-VI
  before Phase 0 begins and again after Phase 1 design
- Each feature lives in `specs/<###-feature-name>/`
- Task order within a user story MUST respect layer dependencies:
  `data/` entities -> repository interface -> Cubit + State -> View widgets
- Specs and UI contracts MUST reference Principle VI tokens and components by
  name instead of inventing new colors, sizes, or button styles
- Widget tests and Cubit unit tests MUST pass before a feature is marked complete
- Run `flutter analyze` and `flutter test` before every commit; both MUST be
  green
- Breaking changes to the offline data schema require a migration plan documented
  in the feature's `plan.md`

## Agent Compliance

These rules bind every contributor, human or AI model, working on any spec,
plan, task list, or code in this repository:

1. Read this constitution and `docs/design/design-system-mock.html` before
   writing or changing any spec, plan, tasks, or code.
2. Never introduce a new color, font size, spacing value, radius, button style,
   or component variant outside Principle VI. If one is truly needed, amend this
   constitution first.
3. Never place business logic in widgets or Flutter imports in Cubits/data.
4. Never add English user-facing copy or runtime-downloaded fonts.
5. When an existing spec or code conflicts with this constitution, the
   constitution wins; record the conflict and fix it rather than copying it.
6. Never write, generate, or edit Quranic text, surah names, or juz ranges by
   hand; read them from the verified source files (Principle VII). If the data
   is not available, stop and ask the project owner.

## Governance

This constitution supersedes all other practices, conventions, and preferences.
Any deviation MUST be documented as a Complexity Tracking violation in the
relevant `plan.md` with explicit justification.

**Amendment procedure**:
1. Open a PR with the proposed constitution change.
2. Describe the rationale and any affected features/templates.
3. Update `LAST_AMENDED_DATE` and bump `CONSTITUTION_VERSION` per semver rules.
4. Run the consistency propagation checklist (templates, commands, docs, and
   the design reference mock).
5. Merge only after the sync impact report confirms all templates are aligned.

**Versioning**: MAJOR for removed or redefined principles, MINOR for new
principles or materially expanded rules (including new design tokens), PATCH
for clarifications and wording.

**Compliance**: All feature plans and code reviews MUST verify compliance with
these principles. Reviewers are empowered to block merges for constitution
violations.

**Version**: 2.2.0 | **Ratified**: 2026-06-20 | **Last Amended**: 2026-11-14
