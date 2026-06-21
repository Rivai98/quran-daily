# Implementation Plan: Quran Group Reading Tracker UI

**Branch**: `001-track-quran-groups` feature directory; no Git branch detected | **Date**: 2026-06-21 | **Spec**: [spec.md](./spec.md)

**Input**: Clarified feature specification from `specs/001-track-quran-groups/spec.md`. Approved implementation direction: Flutter and Dart, MVVM, Cubit as ViewModel/state management, feature-first structure, Repository Pattern, use cases, dependency injection, Supabase Auth with Google Sign-In, Supabase PostgreSQL, and Supabase backend/database functions for critical operations. Firebase Cloud Messaging and push notifications are explicitly deferred outside v1.

## Summary

Build the first Quran group reading tracker as an Arabic-first Flutter mobile feature. Users sign in, discover public Quran groups, request to join, wait for organizer approval, and then use one selected group dashboard to track a daily 30-juz reading cycle. Organizers approve join requests, manage the exactly-30-active-member group, publish daily assignments, review/reassign parts, and inspect history. v1 shows Quran part labels and reading ranges only; it does not include an in-app Quran reader, audio, chat, reminders, notification setup, or multi-group dashboard.

The implementation uses feature-first MVVM. Cubits act as ViewModels, repositories hide Supabase/local-cache details, use cases hold business operations, and the View layer renders Arabic phone-first screens with clear offline/stale states.

## Technical Context

**Language/Version**: Dart SDK `^3.10.4` from `pubspec.yaml`; Flutter mobile app.

**Primary Dependencies**: Flutter Material widgets, `flutter_bloc` Cubit, `equatable` for value states, `supabase_flutter`, `google_sign_in`, `get_it` for dependency injection, `sqflite` plus `path_provider` for local cache, and `shared_preferences` for lightweight settings. Do not add `firebase_messaging` in v1.

**Storage**: Supabase PostgreSQL is the server source of truth for users, public group profiles, join requests, memberships, cycles, assignments, and completion records. Local SQLite cache stores the selected group dashboard, today's assignment, history summaries, Quran part metadata, pending personal completion operations, and cached public discovery results. `shared_preferences` stores text-size and selected-group settings.

**Testing**: `flutter_test` for unit and widget tests, `bloc_test` for Cubit tests, `mocktail` or equivalent mocks for repository/use-case tests, and `integration_test` for end-to-end mobile journeys. Tests must be written before implementation for business logic and widget behavior.

**Target Platform**: iOS 15+ and Android API 26+ as primary targets. Web, desktop, and server-rendered UI are out of scope for v1.

**Project Type**: Mobile app with Supabase backend services. Push notifications and Firebase Cloud Messaging are out of scope for v1.

**Performance Goals**: Cached group dashboard renders in under 1 second after app launch on a mid-range mobile device; network refresh completes in under 3 seconds on normal mobile connectivity; member completion action updates local UI in under 300 ms; public discovery search returns usable results within 3 seconds; dashboard scrolling and progress grid remain at 60 fps for 30 assignments.

**Constraints**: Arabic-first user-facing interface; RTL presentation for Arabic labels; offline-first viewing for previously opened daily assignments; personal completion can be queued offline and synced later; public discovery must not expose member list or reading progress to non-members; shared group progress may be stale offline and must be labeled clearly; organizer-only operations must be enforced in both UI and backend contracts; each published cycle has exactly 30 active member assignments; group timezone determines daily cutoff and late status.

**Scale/Scope**: v1 focuses on public group discovery, join request approval, one selected group at a time, exactly 30 active members per daily cycle, all 30 Quran juz assignments, current-day dashboard, personal completion, organizer assignment review, member management, and daily history. The data model supports multiple groups per user, but multi-group dashboards are deferred.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate

- **I. Offline-Resilient Core**: PASS. The personal assignment loop remains usable from local cache after a group/day has been opened. Supabase Auth, public discovery, join requests, membership approval, assignment publishing, and shared progress sync are network-backed shared coordination operations allowed by the constitution.
- **II. Mobile-First UX & Accessibility**: PASS. Plan targets phone-first iOS/Android layouts, Arabic-first copy, RTL support, adjustable Quran label/range text size, and contrast-sensitive visual states.
- **III. Test-First**: PASS. The plan requires Cubit, repository/use-case, widget, and integration tests before implementation.
- **IV. MVVM Architecture with Cubit**: PASS. Feature folders use `data/`, `cubit/`, and `view/`; Cubits act as ViewModels; Views call Cubit methods and render state.
- **V. Simplicity & YAGNI**: PASS. Scope is limited to Quran group discovery/requesting and daily tracking. Notifications, reader, audio, chat, advanced public directory ranking, and multi-group dashboards are excluded from v1.

### Post-Design Gate

- **I. Offline-Resilient Core**: PASS. `data-model.md`, `supabase-rpc.md`, and `repository-contracts.md` include local cache and sync queue boundaries for offline assignment viewing and queued completion. Network-backed shared operations are limited to auth, discovery, join requests, organizer approvals, publishing, and shared sync.
- **II. Mobile-First UX & Accessibility**: PASS. `ui-contract.md` defines Arabic-first phone screens, RTL handling, offline/stale states, public discovery privacy, join-request pending copy, and text-size settings.
- **III. Test-First**: PASS. `quickstart.md` defines unit, Cubit, widget, and integration validation paths.
- **IV. MVVM Architecture with Cubit**: PASS. Project structure, contracts, and quickstart preserve Model/ViewModel/View separation.
- **V. Simplicity & YAGNI**: PASS. Contracts avoid push notifications, in-app Quran reader, chat, audio, advanced reminders, analytics, and multi-group dashboard behavior.

## Project Structure

### Documentation (this feature)

```text
specs/001-track-quran-groups/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- repository-contracts.md
|   |-- supabase-rpc.md
|   `-- ui-contract.md
|-- checklists/
|   `-- requirements.md
`-- tasks.md              # Created later by /speckit-tasks
```

### Source Code (repository root)

```text
lib/
|-- main.dart
|-- app/
|   |-- app.dart
|   |-- router.dart
|   `-- bootstrap.dart
|-- core/
|   |-- config/
|   |-- di/
|   |-- errors/
|   |-- localization/
|   |-- network/
|   |-- storage/
|   |-- sync/
|   `-- theme/
|-- features/
|   |-- auth/
|   |   |-- data/
|   |   |   |-- data_sources/
|   |   |   |-- entities/
|   |   |   |-- repositories/
|   |   |   `-- use_cases/
|   |   |-- cubit/
|   |   `-- view/
|   `-- quran_groups/
|       |-- data/
|       |   |-- data_sources/
|       |   |-- entities/
|       |   |-- models/
|       |   |-- repositories/
|       |   `-- use_cases/
|       |-- cubit/
|       |   |-- assignment/
|       |   |-- dashboard/
|       |   |-- discovery/
|       |   |-- history/
|       |   |-- join_requests/
|       |   `-- organizer/
|       `-- view/
|           |-- screens/
|           `-- widgets/
supabase/
|-- migrations/
`-- functions/
test/
|-- core/
|-- features/
|   |-- auth/
|   `-- quran_groups/
`-- widget_test.dart
integration_test/
`-- quran_group_flow_test.dart
```

**Structure Decision**: Use one Flutter app with feature-first MVVM modules. `features/auth` is a minimal support feature for Supabase Google Sign-In. `features/quran_groups` owns public discovery, join requests, organizer membership management, assignment publishing, dashboard tracking, personal completion, and history. Cross-feature infrastructure lives in `core/`; feature modules do not import sibling feature modules. Supabase migrations/functions live under `supabase/` so backend contracts and critical operations are versioned with the app.

## Complexity Tracking

No active constitution violations. Supabase-backed auth and group coordination are treated as permitted network-backed shared coordination under the Offline-Resilient Core principle.
