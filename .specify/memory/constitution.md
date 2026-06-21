<!--
SYNC IMPACT REPORT
==================
Version change: 1.1.0 -> 2.0.0
Bump type: MAJOR - Principle I materially redefined to permit authenticated
  shared group coordination over the network while keeping the personal reading
  and cached assignment loop offline-resilient.

Modified principles (old -> new):
  I. Offline-First -> I. Offline-Resilient Core

Added sections: none
Removed sections: none

Templates reviewed:
  OK .specify/templates/plan-template.md - Constitution Check gate is generic;
     active plans must state which operations are offline-capable and which
     shared operations require network.
  OK .specify/templates/spec-template.md - No changes required; requirements
     format is architecture-agnostic.
  OK .specify/templates/tasks-template.md - Task phases already support offline
     cache, sync, and network-backed operations.
  N/A .specify/templates/commands/ - Directory not present in this workspace.

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
required unless a feature explicitly includes them.

**Rationale**: Reliable daily worship requires local access to the member's own
assignment and completion flow, while group membership, approval, and shared
progress require an authenticated source of truth across devices.

### II. Mobile-First UX & Accessibility

Every screen MUST be designed for touch-first interaction on phones (iOS 15+ and
Android API 26+). Arabic text MUST render with a legible, properly-shaped
Arabic font. RTL (right-to-left) layout MUST be supported for Arabic content.
Font size MUST be user-adjustable. Contrast ratios MUST meet WCAG 2.1 AA
(4.5:1 for normal text).

**Rationale**: The primary audience reads Arabic and uses the app daily, often
in low-light conditions. Accessibility is non-negotiable for a devotional tool.

### III. Test-First (NON-NEGOTIABLE)

TDD is mandatory for all business logic and widget code:
- Tests MUST be written and confirmed to fail before implementation begins.
- Red-Green-Refactor cycle MUST be followed.
- Unit tests cover Cubit logic and repository contracts; widget tests cover View
  behavior; integration tests cover user journeys end-to-end.
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
|-- data/          # Model layer: entities, repository interfaces, data sources
|-- cubit/         # ViewModel layer: Cubit class(es) + State class(es)
`-- view/          # View layer: Flutter widgets only
```

Rules:
- **Model layer** (`data/`): data entities and repository contracts. MUST NOT
  import Flutter widgets or Cubit classes.
- **ViewModel layer** (`cubit/`): one Cubit per logical feature unit. All
  business logic and state transitions live here. Cubits MUST NOT import Flutter
  widgets. Cubits call repository interfaces, never concrete data sources directly.
- **View layer** (`view/`): widgets render Cubit state via `BlocBuilder` /
  `BlocListener`. Views MUST NOT contain business logic; they call Cubit methods
  and display state only.
- `setState` is permitted ONLY for purely local, ephemeral UI state (e.g.,
  animation controllers, focus nodes) with no business significance.
- Cross-feature shared code (repositories, services, shared entities) lives in
  `lib/core/`. Feature modules MUST NOT import from sibling feature modules.

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

## Technology Stack

- **Language**: Dart (SDK ^3.10.4)
- **Framework**: Flutter (Material Design, `uses-material-design: true`)
- **Platforms**: iOS 15+ and Android API 26+ (primary); Web is out of scope for v1
- **Architecture**: MVVM - Model / Cubit (ViewModel) / View (see Principle IV)
- **State Management**: Cubit (`flutter_bloc`) - MANDATORY for all feature state.
  `setState` is allowed only for local ephemeral UI state with no business logic.
- **Storage**: Supabase PostgreSQL for authenticated shared group coordination;
  SQLite or local files for offline Quran part metadata, cached assignments, and
  pending personal completion operations; `shared_preferences` for user settings
- **Testing**: `flutter_test` (unit + widget), `bloc_test` (Cubit unit tests),
  `integration_test` (end-to-end)
- **Linting**: `flutter_lints` ^6.0.0; all lints MUST pass with no suppressions
  unless justified in a code comment

## Development Workflow

- Features follow the speckit workflow: `/speckit-specify` -> `/speckit-plan` ->
  `/speckit-tasks` -> `/speckit-implement`
- The Constitution Check in `plan-template.md` MUST pass before Phase 0 begins
- Each feature lives in `specs/<###-feature-name>/`
- Task order within a user story MUST respect layer dependencies:
  `data/` entities -> repository interface -> Cubit + State -> View widgets
- Widget tests and Cubit unit tests MUST pass before a feature is marked complete
- Run `flutter analyze` and `flutter test` before every commit; both MUST be
  green
- Breaking changes to the offline data schema require a migration plan documented
  in the feature's `plan.md`

## Governance

This constitution supersedes all other practices, conventions, and preferences.
Any deviation MUST be documented as a Complexity Tracking violation in the
relevant `plan.md` with explicit justification.

**Amendment procedure**:
1. Open a PR with the proposed constitution change.
2. Describe the rationale and any affected features/templates.
3. Update `LAST_AMENDED_DATE` and bump `CONSTITUTION_VERSION` per semver rules.
4. Run the consistency propagation checklist (templates, commands, docs).
5. Merge only after the sync impact report confirms all templates are aligned.

**Compliance**: All feature plans and code reviews MUST verify compliance with
these principles. Reviewers are empowered to block merges for constitution
violations.

**Version**: 2.0.0 | **Ratified**: 2026-06-20 | **Last Amended**: 2026-06-21
