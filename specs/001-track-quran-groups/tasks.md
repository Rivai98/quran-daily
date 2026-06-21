# Tasks: Quran Group Reading Tracker UI

**Input**: Design documents from `specs/001-track-quran-groups/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`
**Tests**: Required by the quran_daily constitution. Write tests first and confirm they fail before implementation.
**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with other [P] tasks in the same phase when files do not overlap.
- **[Story]**: Maps to a user story from `spec.md`.
- Every task includes exact file paths.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the Flutter dependencies and create the feature-first project skeleton.

- [X] T001 Add Flutter dependencies `flutter_bloc`, `equatable`, `supabase_flutter`, `google_sign_in`, `get_it`, `sqflite`, `path_provider`, `shared_preferences`, `bloc_test`, and `mocktail` to `pubspec.yaml`
- [X] T002 Create the feature-first directory structure in `lib/app/`, `lib/core/`, `lib/features/auth/`, and `lib/features/quran_groups/`
- [X] T003 [P] Create the test directory structure in `test/core/`, `test/features/auth/`, `test/features/quran_groups/`, and `integration_test/`
- [X] T004 [P] Create Supabase workspace directories in `supabase/migrations/`, `supabase/functions/`, and `supabase/tests/`
- [X] T005 Replace the default counter app entry with app bootstrap wiring in `lib/main.dart`
- [X] T006 Create the root Flutter app shell in `lib/app/app.dart`
- [X] T007 Create the app router skeleton for auth, group selection, discovery, dashboard, assignment, organizer, member management, history, and settings routes in `lib/app/router.dart`
- [X] T008 Create application bootstrap initialization for dependencies and Supabase startup in `lib/app/bootstrap.dart`
- [X] T009 [P] Configure reusable test fixtures and mock builders in `test/helpers/test_fixtures.dart`
- [X] T010 [P] Configure widget test helpers with Arabic RTL `MaterialApp` wrappers in `test/helpers/widget_test_app.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that must be complete before any user story can be implemented.

**CRITICAL**: No user story work can begin until this phase is complete.

### Tests for Foundation

- [ ] T011 [P] Write failing unit tests for typed failures and result handling in `test/core/errors/result_test.dart`
- [ ] T012 [P] Write failing unit tests for Arabic copy keys and canonical status labels in `test/core/localization/arabic_strings_test.dart`
- [ ] T013 [P] Write failing unit tests for app configuration validation in `test/core/config/app_config_test.dart`
- [ ] T014 [P] Write failing unit tests for local database initialization and migrations in `test/core/storage/local_database_test.dart`
- [ ] T015 [P] Write failing unit tests for dependency registration in `test/core/di/service_locator_test.dart`

### Implementation for Foundation

- [ ] T016 Implement typed result and failure classes in `lib/core/errors/result.dart` and `lib/core/errors/failures.dart`
- [X] T017 Implement Arabic-first copy constants, canonical status labels, empty-state copy, and error copy in `lib/core/localization/arabic_strings.dart`
- [ ] T018 Implement app configuration loading for Supabase URL and anon key in `lib/core/config/app_config.dart`
- [ ] T019 Implement Supabase client initialization wrapper in `lib/core/network/supabase_client_provider.dart`
- [ ] T020 Implement local SQLite database opening and migration registry in `lib/core/storage/local_database.dart`
- [ ] T021 Implement shared sync operation primitives in `lib/core/sync/sync_operation.dart`
- [ ] T022 Implement dependency injection registration in `lib/core/di/service_locator.dart`
- [X] T023 Implement Arabic RTL app theme and status color tokens in `lib/core/theme/app_theme.dart`
- [ ] T024 [P] Implement shared data entities `AppUser`, `Group`, `GroupMembership`, and `JoinRequest` in `lib/features/quran_groups/data/entities/group_entities.dart`
- [ ] T025 [P] Implement shared data entities `QuranPart`, `DailyReadingCycle`, `Assignment`, and `CompletionRecord` in `lib/features/quran_groups/data/entities/reading_entities.dart`
- [ ] T026 [P] Implement user settings entity in `lib/features/quran_groups/data/entities/user_settings.dart`
- [ ] T027 [P] Implement Supabase DTO models and mappers for group/discovery data in `lib/features/quran_groups/data/models/group_models.dart`
- [ ] T028 [P] Implement Supabase DTO models and mappers for dashboard/assignment/history data in `lib/features/quran_groups/data/models/reading_models.dart`
- [ ] T029 Implement the repository interfaces from `contracts/repository-contracts.md` in `lib/features/auth/data/repositories/auth_repository.dart` and `lib/features/quran_groups/data/repositories/group_repository.dart`
- [ ] T030 Implement Quran part repository interface and Arabic 30-juz label fixture in `lib/features/quran_groups/data/repositories/quran_part_repository.dart`
- [ ] T031 Implement local cache repository interface in `lib/features/quran_groups/data/repositories/local_cache_repository.dart`
- [ ] T032 Create the initial Supabase schema migration for users, groups, public profiles, join requests, memberships, Quran parts, cycles, assignments, completion records, and concrete RLS policies for public discovery, approved-member reads, organizer-only writes, and non-member rejection in `supabase/migrations/001_quran_groups_schema.sql`
- [ ] T033 Create Supabase SQL tests for privacy boundaries and organizer/member permissions in `supabase/tests/001_quran_groups_rls_test.sql`
- [ ] T034 [P] Write failing auth repository, AuthCubit, and Arabic Auth Entry widget tests for Google Sign-In, loading, failure, signed-in routing, and sign-out in `test/features/auth/data/auth_repository_test.dart`, `test/features/auth/cubit/auth_cubit_test.dart`, and `test/features/auth/view/auth_entry_screen_test.dart`
- [ ] T035 Implement Supabase auth data source, `AuthRepositoryImpl`, `SignInWithGoogle` and `SignOut` use cases, AuthCubit/state, and Arabic Auth Entry screen in `lib/features/auth/data/data_sources/auth_remote_data_source.dart`, `lib/features/auth/data/repositories/auth_repository_impl.dart`, `lib/features/auth/data/use_cases/auth_use_cases.dart`, `lib/features/auth/cubit/auth_cubit.dart`, `lib/features/auth/cubit/auth_state.dart`, and `lib/features/auth/view/auth_entry_screen.dart`
- [ ] T036 Implement the Auth Entry route and app-level route guard decisions for signed-out, pending request, approved member, and organizer states in `lib/app/router.dart`

**Checkpoint**: Foundation ready. User story implementation can now begin.

---

## Phase 3: User Story 1 - View Today's Group Reading Progress (Priority: P1) MVP

**Goal**: Approved group members can open a selected group and immediately understand today's assignment, all 30 assignment statuses, completion counts, percentage, and stale/offline state.

**Independent Test**: Open an approved 30-member group with a published daily cycle and verify the member can identify their assigned part, completed count, remaining count, percentage, and complete/pending/missed/late status groups without any organizer flow.

### Tests for User Story 1

- [ ] T037 [P] [US1] Write failing Supabase RPC tests for `get_user_groups` and `get_group_dashboard` in `supabase/tests/002_dashboard_rpc_test.sql`
- [ ] T038 [P] [US1] Write failing repository tests for approved group loading, cached dashboard loading, stale flags, and privacy rejection for non-members in `test/features/quran_groups/data/group_repository_dashboard_test.dart`
- [ ] T039 [P] [US1] Write failing Cubit tests for loading, cached refresh, fresh dashboard, offline stale, no published cycle, and dashboard error states in `test/features/quran_groups/cubit/dashboard/group_dashboard_cubit_test.dart`
- [ ] T040 [P] [US1] Write failing widget tests for Arabic dashboard layout, 30-assignment status overview, no-reader boundary, and offline banner in `test/features/quran_groups/view/group_dashboard_screen_test.dart`
- [ ] T041 [P] [US1] Write failing integration test for opening an approved group dashboard from group selection in `integration_test/us1_dashboard_flow_test.dart`

### Implementation for User Story 1

- [ ] T042 [US1] Implement Supabase `get_user_groups` and `get_group_dashboard` functions in `supabase/migrations/002_dashboard_functions.sql`
- [ ] T043 [US1] Implement remote dashboard data source in `lib/features/quran_groups/data/data_sources/group_remote_data_source.dart`
- [ ] T044 [US1] Implement local dashboard cache data source in `lib/features/quran_groups/data/data_sources/group_local_data_source.dart`
- [ ] T045 [US1] Implement `LoadUserGroups`, `LoadGroupDashboard`, and `WatchCachedDashboard` use cases in `lib/features/quran_groups/data/use_cases/dashboard_use_cases.dart`
- [ ] T046 [US1] Implement dashboard repository methods in `lib/features/quran_groups/data/repositories/group_repository_impl.dart`
- [ ] T047 [US1] Implement GroupSelectionCubit and state, including selected group, approved group loading, create-group form state, timezone selection, and create failure state, in `lib/features/quran_groups/cubit/group_selection/group_selection_cubit.dart` and `lib/features/quran_groups/cubit/group_selection/group_selection_state.dart`
- [ ] T048 [US1] Implement GroupDashboardCubit in `lib/features/quran_groups/cubit/dashboard/group_dashboard_cubit.dart`
- [ ] T049 [US1] Implement dashboard state model and derived counts in `lib/features/quran_groups/cubit/dashboard/group_dashboard_state.dart`
- [ ] T050 [US1] Implement Arabic group selection screen with approved groups, empty state, cached selected group, create-group form/action, and public discovery entry in `lib/features/quran_groups/view/screens/group_selection_screen.dart`
- [ ] T051 [US1] Implement Arabic group dashboard screen in `lib/features/quran_groups/view/screens/group_dashboard_screen.dart`
- [ ] T052 [P] [US1] Implement dashboard progress header widget in `lib/features/quran_groups/view/widgets/dashboard_progress_header.dart`
- [ ] T053 [P] [US1] Implement 30-part status grid widget with non-color status indicators in `lib/features/quran_groups/view/widgets/assignment_status_grid.dart`
- [ ] T054 [P] [US1] Implement assignment list widget with Arabic labels and member identity format in `lib/features/quran_groups/view/widgets/assignment_list.dart`
- [ ] T055 [P] [US1] Implement offline/stale Arabic banner widget in `lib/features/quran_groups/view/widgets/offline_stale_banner.dart`
- [ ] T056 [US1] Wire group selection and dashboard routes in `lib/app/router.dart`

**Checkpoint**: MVP dashboard story is independently testable.

---

## Phase 4: User Story 2 - Assign One Quran Part to Each Group Member (Priority: P2)

**Goal**: Organizers can create public groups, review public join requests, maintain 30 active members, generate/review/swap assignments, and publish a daily cycle with exactly one unique Quran part per active member.

**Independent Test**: Sign in as an organizer, create or open a group, approve join requests until there are 30 active members, generate assignments, swap two parts, and publish a cycle with no duplicate part and no duplicate member.

### Tests for User Story 2

- [ ] T057 [P] [US2] Write failing Supabase RPC tests for `create_group`, `search_public_groups`, `submit_join_request`, and `review_join_request` in `supabase/tests/003_discovery_join_requests_rpc_test.sql`
- [ ] T058 [P] [US2] Write failing Supabase RPC tests for `publish_daily_cycle`, `swap_assignment_parts`, `reassign_assignment`, group-timezone cycle-date resolution, and day-cutoff validation in `supabase/tests/004_organizer_cycle_rpc_test.sql`
- [ ] T059 [P] [US2] Write failing repository tests for public discovery, create group, join request submission, organizer review, group full, and publish validation in `test/features/quran_groups/data/group_repository_organizer_test.dart`
- [ ] T060 [P] [US2] Write failing Cubit tests for discovery pending/rejected/approved states in `test/features/quran_groups/cubit/discovery/group_discovery_cubit_test.dart`
- [ ] T061 [P] [US2] Write failing Cubit tests for organizer join request approval/rejection and group-full validation in `test/features/quran_groups/cubit/join_requests/join_requests_cubit_test.dart`
- [ ] T062 [P] [US2] Write failing Cubit tests for assignment draft generation, duplicate warnings, swap, publish success, and publish failure in `test/features/quran_groups/cubit/organizer/organizer_cubit_test.dart`
- [ ] T063 [P] [US2] Write failing widget tests for create group UI, public discovery, pending Arabic message, organizer join requests, member management, and assignment review screens in `test/features/quran_groups/view/organizer_and_discovery_screens_test.dart`
- [ ] T064 [P] [US2] Write failing integration test for create group, discovery, join request, organizer approval, member management, and daily cycle publish in `integration_test/us2_organizer_flow_test.dart`

### Implementation for User Story 2

- [ ] T065 [US2] Implement Supabase functions `create_group`, `search_public_groups`, `submit_join_request`, and `review_join_request` in `supabase/migrations/003_discovery_join_request_functions.sql`
- [ ] T066 [US2] Implement Supabase functions `publish_daily_cycle`, `swap_assignment_parts`, and `reassign_assignment` with group-timezone cycle date and day-cutoff rules in `supabase/migrations/004_organizer_cycle_functions.sql`
- [ ] T067 [US2] Extend remote group data source with discovery, join request, organizer review, publish, swap, and reassign calls in `lib/features/quran_groups/data/data_sources/group_remote_data_source.dart`
- [ ] T068 [US2] Extend local data source with public discovery cache and organizer draft cache in `lib/features/quran_groups/data/data_sources/group_local_data_source.dart`
- [ ] T069 [US2] Implement `CreateGroup`, `SearchPublicGroups`, `SubmitJoinRequest`, `LoadOrganizerJoinRequests`, and `ReviewJoinRequest` use cases in `lib/features/quran_groups/data/use_cases/discovery_join_request_use_cases.dart`
- [ ] T070 [US2] Implement `PublishDailyCycle`, `SwapAssignmentParts`, and `ReassignAssignment` use cases in `lib/features/quran_groups/data/use_cases/organizer_cycle_use_cases.dart`
- [ ] T071 [US2] Extend repository implementation for discovery, join requests, member management, and publishing in `lib/features/quran_groups/data/repositories/group_repository_impl.dart`
- [ ] T072 [US2] Implement GroupDiscoveryCubit and state in `lib/features/quran_groups/cubit/discovery/group_discovery_cubit.dart` and `lib/features/quran_groups/cubit/discovery/group_discovery_state.dart`
- [ ] T073 [US2] Implement JoinRequestsCubit and state in `lib/features/quran_groups/cubit/join_requests/join_requests_cubit.dart` and `lib/features/quran_groups/cubit/join_requests/join_requests_state.dart`
- [ ] T074 [US2] Implement OrganizerCubit and state in `lib/features/quran_groups/cubit/organizer/organizer_cubit.dart` and `lib/features/quran_groups/cubit/organizer/organizer_state.dart`
- [ ] T075 [US2] Implement Arabic public discovery screen with no-results, cached results, submit error, and pending status in `lib/features/quran_groups/view/screens/public_group_discovery_screen.dart`
- [ ] T076 [US2] Implement Arabic organizer join requests screen with empty, approve, reject, group full, and review failed states in `lib/features/quran_groups/view/screens/organizer_join_requests_screen.dart`
- [ ] T077 [US2] Implement Arabic member management screen with active count, slot readiness, role labels, and pending-request entry in `lib/features/quran_groups/view/screens/member_management_screen.dart`
- [ ] T078 [US2] Implement Arabic organizer assignment review screen with draft readiness, duplicate/missing warnings, swap, reassign, publish, and failure states in `lib/features/quran_groups/view/screens/organizer_assignment_review_screen.dart`
- [ ] T079 [P] [US2] Implement reusable public group profile card widget in `lib/features/quran_groups/view/widgets/public_group_profile_card.dart`
- [ ] T080 [P] [US2] Implement reusable join request tile widget in `lib/features/quran_groups/view/widgets/join_request_tile.dart`
- [ ] T081 [P] [US2] Implement reusable member slot readiness widget in `lib/features/quran_groups/view/widgets/member_slot_readiness.dart`
- [ ] T082 [P] [US2] Implement reusable assignment draft row widget in `lib/features/quran_groups/view/widgets/assignment_draft_row.dart`
- [ ] T083 [US2] Wire public discovery, organizer join request, member management, and organizer assignment routes in `lib/app/router.dart`

**Checkpoint**: Organizer and discovery story is independently testable.

---

## Phase 5: User Story 3 - Mark Personal Reading Completion (Priority: P3)

**Goal**: Members can open their assigned Quran part label/range, mark it complete, see completion reflected, undo through the confirmation flow, and queue completion offline.

**Independent Test**: Sign in as a member with a pending assignment, open assignment detail, mark complete, see dashboard count update, prevent duplicate completion, undo when allowed, and queue completion while offline.

### Tests for User Story 3

- [ ] T084 [P] [US3] Write failing Supabase RPC tests for `mark_assignment_complete` and `undo_assignment_completion` in `supabase/tests/005_assignment_completion_rpc_test.sql`
- [ ] T085 [P] [US3] Write failing repository tests for online completion, group-timezone late completion, undo, duplicate completion, closed cycle, and offline queueing in `test/features/quran_groups/data/group_repository_completion_test.dart`
- [ ] T086 [P] [US3] Write failing Cubit tests for pending, completing, completed, group-timezone late, offline queued, undo available, undo failed, and completion error states in `test/features/quran_groups/cubit/assignment/assignment_cubit_test.dart`
- [ ] T087 [P] [US3] Write failing widget tests for Arabic assignment detail, completion confirmation, undo copy, offline queued copy, no-reader controls, and enlarged text in `test/features/quran_groups/view/personal_assignment_detail_screen_test.dart`
- [ ] T088 [P] [US3] Write failing integration test for mark-complete, duplicate prevention, undo, and offline queued completion in `integration_test/us3_completion_flow_test.dart`

### Implementation for User Story 3

- [ ] T089 [US3] Implement Supabase functions `mark_assignment_complete` and `undo_assignment_completion` in `supabase/migrations/005_assignment_completion_functions.sql`
- [ ] T090 [US3] Extend remote data source with mark complete and undo completion calls in `lib/features/quran_groups/data/data_sources/group_remote_data_source.dart`
- [ ] T091 [US3] Extend local data source with pending completion sync operation persistence in `lib/features/quran_groups/data/data_sources/group_local_data_source.dart`
- [ ] T092 [US3] Implement `MarkAssignmentComplete`, `UndoAssignmentCompletion`, and `SyncPendingCompletionOperations` use cases in `lib/features/quran_groups/data/use_cases/completion_use_cases.dart`
- [ ] T093 [US3] Extend repository implementation for online completion, undo, offline queueing, and dashboard cache update in `lib/features/quran_groups/data/repositories/group_repository_impl.dart`
- [ ] T094 [US3] Implement AssignmentCubit and state in `lib/features/quran_groups/cubit/assignment/assignment_cubit.dart` and `lib/features/quran_groups/cubit/assignment/assignment_state.dart`
- [ ] T095 [US3] Implement Arabic personal assignment detail screen in `lib/features/quran_groups/view/screens/personal_assignment_detail_screen.dart`
- [ ] T096 [P] [US3] Implement reusable Arabic completion action panel widget in `lib/features/quran_groups/view/widgets/completion_action_panel.dart`
- [ ] T097 [P] [US3] Implement reusable Arabic offline queued sync status widget in `lib/features/quran_groups/view/widgets/offline_completion_status.dart`
- [ ] T098 [US3] Wire personal assignment route and dashboard completion refresh behavior in `lib/app/router.dart` and `lib/features/quran_groups/cubit/dashboard/group_dashboard_cubit.dart`

**Checkpoint**: Personal completion story is independently testable.

---

## Phase 6: User Story 4 - Review Daily Group History (Priority: P4)

**Goal**: Organizers can review previous daily cycles, see completed/missed/late counts and percentages, and inspect missed or late assignments by member and Quran part.

**Independent Test**: Open a group with at least seven previous daily cycles and verify the organizer can identify each day's completion percentage and missed or late member/part details.

### Tests for User Story 4

- [ ] T099 [P] [US4] Write failing Supabase RPC tests for `get_daily_history` organizer-only summary/detail access and non-organizer rejection in `supabase/tests/006_daily_history_rpc_test.sql`
- [ ] T100 [P] [US4] Write failing repository tests for organizer-only history summary, history detail, offline cached history, and non-organizer rejection in `test/features/quran_groups/data/group_repository_history_test.dart`
- [ ] T101 [P] [US4] Write failing Cubit tests for loading, available, empty, cached offline, selected-day detail, and error states in `test/features/quran_groups/cubit/history/history_cubit_test.dart`
- [ ] T102 [P] [US4] Write failing widget tests for Arabic history summary, empty history, missed/late detail, and enlarged text behavior in `test/features/quran_groups/view/daily_history_screen_test.dart`
- [ ] T103 [P] [US4] Write failing integration test for organizer history review flow in `integration_test/us4_history_flow_test.dart`

### Implementation for User Story 4

- [ ] T104 [US4] Implement Supabase function `get_daily_history` in `supabase/migrations/006_daily_history_function.sql`
- [ ] T105 [US4] Extend remote data source with history summary and detail calls in `lib/features/quran_groups/data/data_sources/group_remote_data_source.dart`
- [ ] T106 [US4] Extend local data source with cached history summaries and detail snapshots in `lib/features/quran_groups/data/data_sources/group_local_data_source.dart`
- [ ] T107 [US4] Implement `LoadDailyHistory` use case in `lib/features/quran_groups/data/use_cases/history_use_cases.dart`
- [ ] T108 [US4] Extend repository implementation for online and cached history loading in `lib/features/quran_groups/data/repositories/group_repository_impl.dart`
- [ ] T109 [US4] Implement HistoryCubit and state in `lib/features/quran_groups/cubit/history/history_cubit.dart` and `lib/features/quran_groups/cubit/history/history_state.dart`
- [ ] T110 [US4] Implement Arabic daily history screen in `lib/features/quran_groups/view/screens/daily_history_screen.dart`
- [ ] T111 [P] [US4] Implement reusable history day summary widget in `lib/features/quran_groups/view/widgets/history_day_summary_tile.dart`
- [ ] T112 [P] [US4] Implement reusable missed/late assignment detail widget in `lib/features/quran_groups/view/widgets/history_assignment_detail.dart`
- [ ] T113 [US4] Wire daily history route for organizers only in `lib/app/router.dart`

**Checkpoint**: Daily history story is independently testable.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improve quality across all stories and prove the v1 boundaries.

- [ ] T114 [P] Add widget tests proving no notification permission prompt, reminder control, push settings, FCM setup, or disabled future-feature navigation item appears in v1 UI in `test/features/quran_groups/view/no_notification_surface_test.dart`
- [ ] T115 [P] Add widget tests proving no full Quran reader, bookmark, reading-position, Quran text navigation, audio, chat, contact import, donation, analytics, or public directory ranking entry point appears in v1 UI in `test/features/quran_groups/view/no_quran_reader_surface_test.dart`
- [ ] T116 [P] Audit and complete Arabic empty-state copy for all v1 screens in `lib/core/localization/arabic_strings.dart`
- [ ] T117 [P] Audit and complete Arabic error-message copy for auth, discovery, join requests, publishing, completion, history, and offline states in `lib/core/localization/arabic_strings.dart`
- [ ] T118 [P] Implement settings Cubit and screen for Quran label/range text size in `lib/features/quran_groups/cubit/settings/settings_cubit.dart` and `lib/features/quran_groups/view/screens/settings_screen.dart`
- [ ] T119 [P] Add widget tests for settings text-size behavior and Arabic RTL layout stability in `test/features/quran_groups/view/settings_screen_test.dart`
- [X] T120 [P] Update generated UX checklist findings and mark resolved requirement-quality items in `specs/001-track-quran-groups/checklists/ux.md`
- [ ] T121 [P] Update quickstart validation notes with any final command or setup changes in `specs/001-track-quran-groups/quickstart.md`
- [ ] T122 Run `flutter analyze` and fix all lint issues found in `analysis_options.yaml`
- [ ] T123 Run `flutter test` and fix all failing unit and widget tests referenced under `test/`
- [ ] T124 Run `flutter test integration_test` and fix all failing flows referenced under `integration_test/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies.
- **Phase 2 Foundational**: Depends on Phase 1 and blocks all user stories.
- **Phase 3 User Story 1**: Depends on Phase 2. This is the MVP.
- **Phase 4 User Story 2**: Depends on Phase 2. Can run in parallel with US1 after foundation, but publishing works best after shared dashboard entities exist.
- **Phase 5 User Story 3**: Depends on Phase 2. Integrates most naturally after US1 because dashboard refresh behavior is reused.
- **Phase 6 User Story 4**: Depends on Phase 2. Can run after history schema and shared entities are ready.
- **Phase 7 Polish**: Depends on all selected stories being complete.

### User Story Dependencies

- **US1 View Today's Group Reading Progress**: MVP; no dependency on other user stories after foundation.
- **US2 Assign One Quran Part to Each Group Member**: Independent after foundation, but validates against shared group/member/cycle entities.
- **US3 Mark Personal Reading Completion**: Independent after foundation, but uses dashboard cache and assignment entities from US1 when implemented sequentially.
- **US4 Review Daily Group History**: Independent after foundation, but uses cycle/assignment entities shared with US1 and US2.

### Within Each User Story

- Tests must be written first and confirmed failing before implementation.
- Supabase RPC tests before SQL functions.
- Repository tests before repository implementation.
- Cubit tests before Cubit implementation.
- Widget/integration tests before screen wiring.
- Entities and models before repositories.
- Repositories and use cases before Cubits.
- Cubits before View screens.
- Screens before route wiring.

---

## Parallel Opportunities

- Setup tasks T003, T004, T009, and T010 can run in parallel.
- Foundation tests T011 through T015 can run in parallel.
- Foundation entity/model tasks T024 through T028 can run in parallel after T016 through T023.
- US1 test tasks T037 through T041 can run in parallel.
- US1 widget tasks T052 through T055 can run in parallel after T051.
- US2 test tasks T057 through T064 can run in parallel.
- US2 widget tasks T079 through T082 can run in parallel after T075 through T078.
- US3 test tasks T084 through T088 can run in parallel.
- US3 widget tasks T096 and T097 can run in parallel after T095.
- US4 test tasks T099 through T103 can run in parallel.
- US4 widget tasks T111 and T112 can run in parallel after T110.
- Polish tasks T114 through T121 can run in parallel after all selected stories are complete.

---

## Parallel Example: User Story 1

```text
Task: "T037 Write failing Supabase RPC tests for get_user_groups and get_group_dashboard in supabase/tests/002_dashboard_rpc_test.sql"
Task: "T038 Write failing repository tests for approved group loading, cached dashboard loading, stale flags, and privacy rejection for non-members in test/features/quran_groups/data/group_repository_dashboard_test.dart"
Task: "T039 Write failing Cubit tests for loading, cached refresh, fresh dashboard, offline stale, no published cycle, and dashboard error states in test/features/quran_groups/cubit/dashboard/group_dashboard_cubit_test.dart"
Task: "T040 Write failing widget tests for Arabic dashboard layout, 30-assignment status overview, no-reader boundary, and offline banner in test/features/quran_groups/view/group_dashboard_screen_test.dart"
Task: "T041 Write failing integration test for opening an approved group dashboard from group selection in integration_test/us1_dashboard_flow_test.dart"
```

## Parallel Example: User Story 2

```text
Task: "T057 Write failing Supabase RPC tests for create_group, search_public_groups, submit_join_request, and review_join_request in supabase/tests/003_discovery_join_requests_rpc_test.sql"
Task: "T059 Write failing repository tests for public discovery, join request submission, organizer review, group full, and publish validation in test/features/quran_groups/data/group_repository_organizer_test.dart"
Task: "T060 Write failing Cubit tests for discovery pending/rejected/approved states in test/features/quran_groups/cubit/discovery/group_discovery_cubit_test.dart"
Task: "T061 Write failing Cubit tests for organizer join request approval/rejection and group-full validation in test/features/quran_groups/cubit/join_requests/join_requests_cubit_test.dart"
```

## Parallel Example: User Story 3

```text
Task: "T084 Write failing Supabase RPC tests for mark_assignment_complete and undo_assignment_completion in supabase/tests/005_assignment_completion_rpc_test.sql"
Task: "T085 Write failing repository tests for online completion, group-timezone late completion, undo, duplicate completion, closed cycle, and offline queueing in test/features/quran_groups/data/group_repository_completion_test.dart"
Task: "T086 Write failing Cubit tests for pending, completing, completed, group-timezone late, offline queued, undo available, undo failed, and completion error states in test/features/quran_groups/cubit/assignment/assignment_cubit_test.dart"
Task: "T087 Write failing widget tests for Arabic assignment detail, completion confirmation, undo copy, offline queued copy, no-reader controls, and enlarged text in test/features/quran_groups/view/personal_assignment_detail_screen_test.dart"
```

## Parallel Example: User Story 4

```text
Task: "T099 Write failing Supabase RPC tests for get_daily_history organizer-only summary/detail access and non-organizer rejection in supabase/tests/006_daily_history_rpc_test.sql"
Task: "T100 Write failing repository tests for organizer-only history summary, history detail, offline cached history, and non-organizer rejection in test/features/quran_groups/data/group_repository_history_test.dart"
Task: "T101 Write failing Cubit tests for loading, available, empty, cached offline, selected-day detail, and error states in test/features/quran_groups/cubit/history/history_cubit_test.dart"
Task: "T102 Write failing widget tests for Arabic history summary, empty history, missed/late detail, and enlarged text behavior in test/features/quran_groups/view/daily_history_screen_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 1.
4. Stop and validate US1 independently with the dashboard tests and quickstart Scenario 5.
5. Demo the approved-member dashboard before adding organizer, completion, and history flows.

### Incremental Delivery

1. Setup + Foundation: app shell, Arabic/RTL infrastructure, Supabase/local cache boundaries, shared entities, and repository contracts.
2. US1: approved member dashboard MVP.
3. US2: public discovery, join requests, organizer member management, and assignment publishing.
4. US3: personal completion and offline queued completion.
5. US4: daily history review.
6. Polish: no-notification/no-reader boundaries, Arabic empty/error copy, settings, analyze, and full tests.

### Parallel Team Strategy

1. Team completes Phase 1 and Phase 2 together.
2. After foundation:
   - Developer A: US1 dashboard flow.
   - Developer B: US2 discovery, join requests, and organizer publishing.
   - Developer C: US3 completion flow.
   - Developer D: US4 history flow.
3. Integrate only through repository interfaces, Cubit contracts, and route wiring defined in this task list.

## Notes

- [P] tasks use different files and can be done in parallel when dependencies are satisfied.
- [US1], [US2], [US3], and [US4] labels map directly to user stories in `spec.md`.
- Keep all user-facing copy Arabic-first.
- Do not add `firebase_messaging`, notification prompts, Quran reader controls, audio, chat, contact import, or public directory ranking in v1.
- Commit after each task or small logical group.
