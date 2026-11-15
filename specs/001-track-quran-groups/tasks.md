# Tasks: Quran Group Reading Tracker (amended 2026-11-14)

**Input**: `specs/001-track-quran-groups/` – plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md
**Also implements**: `specs/002-email-password-auth/` (Phase 2B) – read its plan.md and contracts/ before Phase 2B.
**Binding rules**: `.specify/memory/constitution.md` v2.4.0 and `docs/design/design-system-mock.html`.
**Tests**: REQUIRED (constitution III). Write each test task first, run it, confirm it fails, then implement.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: parallelizable (different files, no dependency on an unfinished task in the same phase).
- **[USn]**: user story from spec.md. Story order: US2 → US1 → US3 → US4 → US5 → US6 → US7.
- **OWNER-PROVIDED**: the project owner supplies these files. Agents MUST NOT create, download, or fabricate them; if missing, stop and report.

## Global rules for every task

- Feature code uses only `lib/core/design_system/` tokens and widgets; no `Color(0x…)`, `fontSize:`, or `BorderRadius.circular(` literals under `lib/features/`.
- All user-facing strings go in `lib/core/localization/arabic_strings.dart`; numbers through `ArabicNumerals`.
- Cubits never import `package:flutter/material.dart`; states are `Equatable` with a status enum and no Arabic copy.
- Never type Quranic text, surah names, or juz ranges; read them via `QuranMetadataRepository`.
- Every screen widget test runs in RTL, at 200% text scale, in dark theme, and at 320 dp width (helper in `test/helpers/widget_test_app.dart`); "all variants" in a task means these runs.
- Every screen widget test covers the five constitution states: loading (skeleton), content, empty, error (`StatePanel` with next action), offline/stale (`OfflineBanner`).
- Feature modules never import sibling features: auth is reached only via `lib/core/auth/session_gateway.dart`; settings storage via `lib/core/settings/`. Cubits never depend on other Cubits.
- Legacy scaffold files under `lib/features/quran_groups/view/` and `lib/core/theme/` are replaced; delete a legacy file when its replacement lands, together with its legacy test.

---

## Phase 1: Setup

- [X] T001 Create the feature-first directory structure in `lib/app/`, `lib/core/`, `lib/features/auth/`, `lib/features/quran_groups/`
- [X] T002 [P] Create test directory structure in `test/core/`, `test/features/`, `test/helpers/`, `integration_test/`
- [X] T003 Replace the default counter app with bootstrap wiring in `lib/main.dart`, `lib/app/app.dart`, `lib/app/bootstrap.dart`
- [X] T004 Update `pubspec.yaml`: remove `google_sign_in`; add `intl`, `flutter_timezone`, `share_plus`, `app_links`, `connectivity_plus`; dev: `sqflite_common_ffi`; declare `assets/quran/` and font families under `flutter: fonts:`: `Cairo` = single variable font `assets/fonts/cairo/Cairo-Variable.ttf` (weight axis 200-1000), `Amiri` = `assets/fonts/amiri/Amiri-Regular.ttf` (400) and `Amiri-Bold.ttf` (700); run `flutter pub get`
- [X] T005 [P] Initialize Supabase workspace (no Docker; research R16): `supabase/config.toml` (via `supabase init`; the project is already linked to `zwkvijapswwutwozbvgy` by the owner), empty `supabase/migrations/`, `supabase/functions/`, `supabase/tests/`. Extensions are not enabled in `config.toml`: `pg_cron` is created by `004_rotation_jobs.sql` (`create extension if not exists pg_cron`), and every pgTAP file starts with `create extension if not exists pgtap with schema extensions`. Migrations apply in filename order; `001_email_password_auth.sql` must precede `002_core_schema.sql`
- [X] T006 [P] Add `.env.example` with `SUPABASE_URL` and `SUPABASE_ANON_KEY` placeholders and document `--dart-define-from-file` usage in `README.md`; ensure `.env` is in `.gitignore`
- [X] T007 **OWNER-PROVIDED** (done 2026-11-14 at owner's request) Fonts in `assets/fonts/`: `cairo/Cairo-Variable.ttf` (Google Fonts variable font) + `cairo/OFL.txt`, `amiri/Amiri-Regular.ttf`, `amiri/Amiri-Bold.ttf` + `amiri/OFL.txt`, `checksums.sha256`
- [X] T008 **OWNER-PROVIDED** (done 2026-11-14 at owner's request) `assets/quran/quran-data.xml` (Tanzil metadata v1.0, byte-exact), `assets/quran/SOURCE.md`, `assets/quran/checksums.sha256` (format `<sha256> *<file>`); `.gitattributes` keeps these files byte-exact

---

## Phase 2A: Design System Foundation (Principle VI) – blocks all screens

- [X] T009 [P] Write failing tests for color tokens (light/dark values exactly as constitution tables, status fg/bg pairs) in `test/core/design_system/app_colors_test.dart`
- [X] T010 [P] Write failing tests for type scale (8 tokens: size/height/weight, Cairo vs Amiri, min size 13) in `test/core/design_system/app_typography_test.dart`
- [X] T011 [P] Write failing tests for `ArabicNumerals.format` (digits, percentages, `١٢ / ٣٠`) in `test/core/localization/arabic_numerals_test.dart`
- [X] T012 Implement `lib/core/design_system/app_colors.dart` (`AppColors.light`/`AppColors.dark` as `ThemeExtension` incl. status colors)
- [X] T013 Implement `lib/core/design_system/app_typography.dart` (Cairo is a variable font: every Cairo `TextStyle` sets both `fontWeight` and `fontVariations: [FontVariation('wght', <same weight>)]` so weights render correctly), `app_spacing.dart` (4-pt scale + gutters), `app_radius.dart` (sm/md/lg/xl/pill)
- [X] T014 Implement `lib/core/design_system/app_theme.dart` (Material 3 light + dark `ThemeData` from tokens: buttons, inputs, cards, chips, NavigationBar, AppBar)
- [X] T015 Implement `lib/core/localization/arabic_numerals.dart`
- [X] T016 [P] Write failing widget tests for `AppButton` (6 variants, heights 52/48, loading keeps width and ignores taps, disabled 38%, icon at start) in `test/core/design_system/widgets/app_button_test.dart`
- [X] T017 [P] Write failing widget tests for `StatusChip` and `PartTile` (6 statuses per constitution v2.4.0 status table, incl. `available`/`unread` on existing tokens, always render color + icon + Arabic label; `PartTile` semantics "الجزء ٥، …، جزؤك") in `test/core/design_system/widgets/status_widgets_test.dart`
- [X] T018 [P] Write failing widget tests for `StatePanel`, `OfflineBanner`, `ConfirmSheet`, `AppSnackBar`, `SkeletonBox`, `ProgressHeader`, `AppTextField`, `AppCard`, `AppSectionHeader` in `test/core/design_system/widgets/shared_widgets_test.dart`
- [X] T019 Implement `AppButton` in `lib/core/design_system/widgets/app_button.dart`
- [X] T020 Implement `StatusChip`, `PartTile` and the `AssignmentStatus` → label/icon mapping in `lib/core/design_system/widgets/status_chip.dart` and `part_tile.dart`
- [X] T021 Implement remaining shared widgets in `lib/core/design_system/widgets/` (`state_panel.dart`, `offline_banner.dart`, `confirm_sheet.dart`, `app_snack_bar.dart`, `skeleton.dart`, `progress_header.dart`, `app_text_field.dart`, `app_card.dart`, `app_section_header.dart`) and barrel `widgets.dart`
- [X] T022 Update `test/helpers/widget_test_app.dart` to pump with Arabic locale, RTL, light/dark, text scale, and screen size params; add `pumpAllVariants` helper (RTL, 200% text, dark, 320 dp width)
- [X] T023 Add design-lint test that scans `lib/features/**/*.dart` for `Color(0x`, `fontSize:`, `BorderRadius.circular(` and fails on any match in `test/core/design_system/design_lint_test.dart`
- [X] T024 Wire theme in `lib/app/app.dart` (light/dark follow system, `Locale('ar')`, RTL, `flutter_localizations` delegates); delete `lib/core/theme/`

**Checkpoint**: design system tests green; `flutter analyze` clean.

---

## Phase 2B: Authentication (implements spec 002) – blocks all stories

Read `specs/002-email-password-auth/{spec,plan,data-model,research}.md` and its `contracts/` first.

- [X] T025 Write pgTAP tests for profiles trigger, owner-only RLS, `app_admins`/audit protection in `supabase/tests/000_auth_test.sql`
- [X] T026 Create migration `supabase/migrations/001_email_password_auth.sql` per spec 002 supabase-backend contract (profiles, trigger, RLS, private.app_admins, private.admin_auth_audit)
- [X] T027 [P] Implement Edge Functions `supabase/functions/admin-create-user/index.ts`, `supabase/functions/admin-reset-password/index.ts`, shared auth/validation in `supabase/functions/_shared/` per spec 002 contract (service key from function secrets only)
- [X] T028 [P] Write failing tests for `AuthRepositoryImpl` (sign up, sign in, sign out, session restore, profile load, error mapping to non-revealing codes) in `test/features/auth/data/auth_repository_test.dart`
- [X] T029 [P] Write failing `bloc_test`s for `AuthCubit` (checking → unauthenticated/authenticated, profile failure, submit guards, sign-out, expiry event) in `test/features/auth/cubit/auth_cubit_test.dart`
- [X] T030 Implement `lib/features/auth/data/` (entities `AppUser`, `UserProfile`; `AuthRepository` interface; `SupabaseAuthDataSource`; `AuthRepositoryImpl`) per spec 002 repository contract; define `SessionGateway` (`currentUserId`, `signOut()`) in `lib/core/auth/session_gateway.dart` and have `AuthRepositoryImpl` implement it
- [X] T031 Implement `lib/features/auth/cubit/auth_cubit.dart` and `auth_state.dart`
- [X] T032 Write failing widget tests for Auth Entry (login/signup modes, validation on submit, LTR email field, password clear on failure, forgot-password guidance, no Google button) in `test/features/auth/view/auth_entry_screen_test.dart`
- [X] T033 Rebuild `lib/features/auth/view/auth_entry_screen.dart` with design-system widgets per spec 002 ui-contract
- [X] T034 Implement the auth startup gate in `lib/app/app.dart` and guarded routes in `lib/app/router.dart` (no private flash; back/deep link cannot bypass)

**Checkpoint**: user can sign up, sign in, restart with session, sign out.

---

## Phase 2C: Core Data, Backend Schema, Quran Metadata – blocks all stories

- [X] T035 [P] Extend `lib/core/errors/failures.dart` with `FailureKind` (unauthenticated, forbidden, validation, network, offlineQueued, notFound, conflict, dayClosed, limitReached, unknown) and backend `code`; update `test/core/errors/result_test.dart`
- [X] T036 [P] Write failing tests for `AppConfig` (reads dart-defines, rejects missing values) and implement `lib/core/config/app_config.dart`; update `test/core/config/app_config_test.dart`
- [X] T037 [P] Implement `lib/core/network/supabase_client_provider.dart` and a `RpcClient` wrapper mapping Postgres error codes to `Failure` in `lib/core/network/rpc_client.dart` with tests in `test/core/network/rpc_client_test.dart`
- [X] T038 [P] Write failing tests (sqflite_common_ffi) for `LocalDatabase` v1 migrations and DAOs (`cached_snapshots`, `cached_groups`, `cached_history`, `sync_queue`) in `test/core/storage/local_database_test.dart`
- [X] T039 Implement `lib/core/storage/local_database.dart` and DAOs in `lib/core/storage/daos/`
- [X] T040 Implement `lib/core/sync/sync_operation.dart` (op types, statuses) and `lib/core/network/connectivity_service.dart` (connectivity_plus stream)
- [X] T041 Write failing tests for `QuranMetadataRepository` (30 juz; juz 1 starts at the first ayah of the first sura; juz 30 ends at the last ayah of the last sura per the file's ayah counts; every other end = one ayah before the next start, crossing sura boundaries via the file's ayah counts; ranges are contiguous and non-overlapping; sura names and counts read from file; checksum matches `assets/quran/checksums.sha256`, missing file throws) in `test/core/quran/quran_metadata_repository_test.dart` – compare only against values read from the file and structural invariants; never hard-code names
- [X] T042 Implement `lib/core/quran/quran_metadata_repository.dart` and `juz_info.dart` (depends on T008)
- [X] T043 Add juz ordinal names (الجزء الأول … الجزء الثلاثون), status labels, role markers, and error-code → copy map to `lib/core/localization/arabic_strings.dart`; update `test/core/localization/arabic_strings_test.dart`
- [X] T044 Write pgTAP tests for `juz_for_seat` (start 1/15/30, wrap, 30 distinct per day) and table constraints (seat uniqueness, ≤ 30 active, one owner, unique juz/seat per day) in `supabase/tests/001_schema_test.sql`; add test-only helper `supabase/tests/helpers/seed_members.sql` (direct inserts of profiles + active memberships as the test superuser) used by US2/US1/US3 tests until US4 join flows exist
- [X] T045 Create migration `supabase/migrations/002_core_schema.sql`: enums, tables `groups`, `group_memberships`, `join_requests`, `group_days`, `assignments`, `completion_records` per data-model, constraints, indexes, `juz_for_seat`, `group_local_date(group, ts)`, RLS enabling with member-select policies and deny-all writes
- [X] T046 Write pgTAP privacy tests (non-member cannot select any group table; member cannot write directly) in `supabase/tests/001_rls_test.sql`
- [X] T047 Implement shared entities in `lib/features/quran_groups/data/entities/` (`GroupSummary`, `MyGroupSummary`, `PendingJoinRequest`, `MyGroupsOverview`, `PublicGroupProfile`, `Membership`, `SeatMap`, `JoinOutcome`, `GroupDay`, `Assignment`, `AssignmentStatus`, `AssignmentKind`, `DashboardSnapshot`, `HistoryDaySummary`) as immutable `Equatable` classes
- [X] T048 [P] Implement JSON models/mappers in `lib/features/quran_groups/data/models/` with round-trip tests in `test/features/quran_groups/data/models_test.dart`
- [X] T049 Define `GroupsRepository` and `KhatmaRepository` interfaces in `lib/features/quran_groups/data/repositories/` per repository contract; `SettingsRepository` in `lib/core/settings/settings_repository.dart`
- [X] T050 Register dependencies in `lib/core/di/service_locator.dart` (config, Supabase, RpcClient, LocalDatabase, connectivity, Quran metadata, `SessionGateway`, repositories, use cases); update `test/core/di/service_locator_test.dart`
- [X] T051 Implement `SelectedGroupCubit` + `SettingsRepository` impl (shared_preferences, `lib/core/settings/`) with tests in `test/features/quran_groups/cubit/selected_group_cubit_test.dart`
- [X] T052 Replace legacy fixtures in `test/helpers/test_fixtures.dart` with builders for the new entities (groups, seat maps, 30-row snapshots, history)

**Checkpoint**: foundation ready; `supabase db push --remote`, `supabase test db --remote` and `flutter test` green.

---

## Phase 3: User Story 2 – Create a Group and Start the Khatma (P1)

**Goal**: any user creates a group, members occupy seats, owner starts; days rotate automatically.
**Independent test**: create group, add members with `supabase/tests/helpers/seed_members.sql` (real join flows arrive in US4), start at juz 1 → seat k juz k; next day seat k juz k+1; 30 wraps to 1.

- [X] T053 [P] [US2] pgTAP tests for `create_group` (validation, owner seat 1, 3-group limit), `start_khatma` (forming only, ≥ 1 member, creates 30 assignments, empty seats unassigned/available), `generate_due_group_days` (rotation +1, idempotent, timezone + day_start_time boundary) in `supabase/tests/001_us2_lifecycle_test.sql`
- [X] T054 [US2] Implement `create_group`, `update_group_settings`, `start_khatma`, `ensure_current_group_day`, `generate_due_group_days`, `get_my_groups` (groups + own pending requests), `regenerate_invite` (8-char code) in `supabase/migrations/003_group_lifecycle_functions.sql` `ensure_current_group_day` and `generate_due_group_days` MUST backfill every missing group-local date since the last existing day (rotation by date index, past states applied immediately) so history has no gaps; include a pgTAP case in T053. Also implement `move_member_seat` here for forming groups (US2 acceptance 5); US6 extends it to active groups.
- [X] T055 [US2] Schedule `generate_due_group_days()` every minute with `pg_cron` in `supabase/migrations/004_rotation_jobs.sql`
- [X] T056 [P] [US2] Failing tests for `GroupsRepositoryImpl` create/start/settings/myGroups (online, offline cache fallback, error mapping) in `test/features/quran_groups/data/groups_repository_test.dart`
- [X] T057 [US2] Implement `GroupsRepositoryImpl` (create, settings, start, myGroups, regenerateInvite) + `GroupsRemoteDataSource` in `lib/features/quran_groups/data/`
- [X] T058 [P] [US2] Failing `bloc_test`s for `GroupListCubit` and `CreateGroupCubit` (validation 3-60 / ≤ 200, submit guard, limit error, success navigates) in `test/features/quran_groups/cubit/group_list_cubit_test.dart` and `create_group_cubit_test.dart`
- [X] T059 [P] [US2] Failing `bloc_test`s for `GroupSettingsCubit` (start khatma with start juz, regenerate invite, owner-only actions) in `test/features/quran_groups/cubit/group_settings_cubit_test.dart`
- [X] T060 [US2] Implement `GroupListCubit`, `CreateGroupCubit`, `GroupSettingsCubit` in `lib/features/quran_groups/cubit/`
- [X] T061 [P] [US2] Failing widget tests (all variants) for S1 Group Selection (list, empty entry points, pending rows) and S4 Create Group in `test/features/quran_groups/view/group_selection_screen_test.dart` and `create_group_screen_test.dart`
- [X] T062 [US2] Rebuild S1 `lib/features/quran_groups/view/screens/group_selection_screen.dart` and build S4 `create_group_screen.dart` (timezone picker defaulting to `flutter_timezone`, time picker, visibility/join-mode segmented controls)
- [X] T063 [P] [US2] Failing widget tests for forming dashboard (N / ٣٠, ناقص X, seat list, invite share, owner "ابدأ الختمة" sheet) and S9 Group Settings in `test/features/quran_groups/view/forming_dashboard_test.dart` and `group_settings_screen_test.dart`
- [X] T064 [US2] Build forming state of S5 in `lib/features/quran_groups/view/widgets/forming_group_view.dart`, start-khatma sheet `start_khatma_sheet.dart`, and S9 `screens/group_settings_screen.dart` (share via `share_plus` text with code + `qurandaily://join/<code>`)
- [X] T065 [US2] Add routes `/groups`, `/groups/new`, `/g/:id`, `/g/:id/settings`, the in-group `NavigationBar` shell, and the non-member guard (redirect to `/groups` with "لست عضوًا في هذه المجموعة") in `lib/app/router.dart`; later stories add their routes: `/g/:id/assignment/:aid` (T081), `/discover` and `/join/:code` (T089), `/g/:id/members` and `/g/:id/requests` (T103), `/g/:id/history` (T109), `/settings` (T110)

**Checkpoint**: US2 independently demoable (with seeded members).

---

## Phase 4: User Story 1 – View Today's Group Reading Progress (P1) – MVP view

**Goal**: member sees own juz, 30 statuses, available juz, progress.
**Independent test**: active group with empty seats → own juz visible without scrolling, counts and % correct, juz 30 note.

- [X] T066 [P] [US1] pgTAP tests for `get_dashboard` (members only, calls ensure day, 30 rows, `is_me`, counts, forming shape) in `supabase/tests/001_us1_dashboard_test.sql`
- [X] T067 [US1] Implement `get_dashboard` in `supabase/migrations/005_dashboard_functions.sql`
- [X] T068 [P] [US1] Failing tests for `KhatmaRepositoryImpl.getDashboard`/`watchCachedDashboard` (cache on success, stale fallback with `cachedAt`, no cache → network failure) in `test/features/quran_groups/data/khatma_repository_dashboard_test.dart`
- [X] T069 [US1] Implement `KhatmaRepositoryImpl` dashboard methods + `KhatmaRemoteDataSource` + snapshot cache in `lib/features/quran_groups/data/`
- [X] T070 [P] [US1] Failing `bloc_test`s for `DashboardCubit` (loading → success/empty/offline-stale/failure, refresh, resume refresh, day rollover detection) in `test/features/quran_groups/cubit/dashboard_cubit_test.dart`
- [X] T071 [US1] Implement `DashboardCubit` in `lib/features/quran_groups/cubit/dashboard/`
- [X] T072 [P] [US1] Failing widget tests for active S5 (my juz card above the fold at 360×640, `ProgressHeader`, 30 `PartTile`s with semantics, available list, juz-30 دعاء الختم note, full-khatma banner, offline banner, all variants) in `test/features/quran_groups/view/group_dashboard_screen_test.dart` (replace legacy test)
- [X] T073 [US1] Rebuild S5 `lib/features/quran_groups/view/screens/group_dashboard_screen.dart` with widgets `my_juz_card.dart`, `juz_grid.dart`, `available_juz_list.dart` (juz names/ranges from `QuranMetadataRepository`); delete superseded legacy widgets and their tests

**Checkpoint**: MVP read path (US2 + US1).

---

## Phase 5: User Story 3 – Mark Personal Reading Completion (P1)

**Goal**: complete/undo with confirmation, offline queue, late in grace, closed rejection.
**Independent test**: complete → +1; undo → −1; offline complete syncs; grace → late; closed → rejected.

- [X] T074 [P] [US3] pgTAP tests for `mark_assignment_complete`/`undo_assignment_completion` (reader only, idempotent, open/grace/closed rules, online uses server time, offline_sync uses `client_recorded_at` clamped to `[opens_at, now()]`, counts, full_khatma incl. late) and `advance_day_states` (pending→missed, available→unread, close) in `supabase/tests/001_us3_completion_test.sql`
- [X] T075 [US3] Implement completion functions and `advance_day_states` in `supabase/migrations/006_completion_functions.sql`; schedule `advance_day_states()` every minute in the same migration
- [X] T076 [P] [US3] Failing tests for `MarkAssignmentComplete`, `UndoAssignmentCompletion`, `SyncPendingCompletions` use cases (optimistic cache update, enqueue on network failure, replay order, day_closed → failed) in `test/features/quran_groups/data/use_cases/completion_use_cases_test.dart`
- [X] T077 [US3] Implement completion methods in `KhatmaRepositoryImpl` and use cases in `lib/features/quran_groups/data/use_cases/`; trigger sync on connectivity regained, app resume, dashboard refresh (wire in `lib/app/app.dart` lifecycle observer)
- [X] T078 [P] [US3] Failing `bloc_test`s for `AssignmentCubit` (complete, undo after confirm, queued offline state, failed sync with retry, duplicate tap ignored) in `test/features/quran_groups/cubit/assignment_cubit_test.dart`
- [X] T079 [US3] Implement `AssignmentCubit` in `lib/features/quran_groups/cubit/assignment/`
- [X] T080 [P] [US3] Failing widget tests for S6 Personal Assignment (primary action, completed state, undo `ConfirmSheet`, queued/failed states, hidden "اقرأ الآن" slot) and dashboard grace banner in `test/features/quran_groups/view/personal_assignment_screen_test.dart`
- [X] T081 [US3] Rebuild S6 `lib/features/quran_groups/view/screens/personal_assignment_screen.dart` (replace `personal_assignment_detail_screen.dart`), connect my-juz card primary action, add grace banner; add `kMushafEnabled = false` flag in `lib/core/config/feature_flags.dart`

**Checkpoint**: P1 complete (US2 + US1 + US3), validated with seeded members. First real-user release also needs US4 (joining).

---

## Phase 6: User Story 4 – Discover and Join Groups (P2)

**Goal**: discovery, auto-accept/approval join, join-any, invite codes/links.
**Independent test**: see quickstart scenario 6.

- [X] T082 [P] [US4] pgTAP tests for `search_public_groups` (no members/progress, sort, private hidden), `get_invite_preview`, `join_group` (auto-accept lowest seat, approval pending, removed → pending, full, already member, mid-day seat takeover unless volunteered), `join_any_group` (filter + order), `cancel_join_request`, pending request listed by `get_my_groups` and `my_join_request_id` in previews in `supabase/tests/001_us4_join_test.sql`
- [X] T083 [US4] Implement join/discovery functions in reserved migrations `20261115030001_join_functions.sql`, `20261115030002_join_group_error_codes.sql`, and `20261115030003_block_full_group_requests.sql`
- [X] T084 [P] [US4] Failing repository tests for discovery/join methods in `test/features/quran_groups/data/groups_repository_join_test.dart`
- [X] T085 [US4] Reused the already-present discovery/join methods in `GroupsRepositoryImpl`; covered their mapping, RPC arguments, offline, and cancel behavior.
- [X] T086 [P] [US4] Failing `bloc_test`s for `DiscoveryCubit` (search debounce, paging, per-card join state) and `JoinCubit` (code validation, preview, join, join-any no-group case, pending) in `test/features/quran_groups/cubit/discovery_cubit_test.dart` and `join_cubit_test.dart`
- [X] T087 [US4] Implement `DiscoveryCubit` and `JoinCubit` in `lib/features/quran_groups/cubit/`
- [X] T088 [P] [US4] Failing widget tests for S2 Discovery and S3 Invite Join (all variants) in `test/features/quran_groups/view/discovery_screen_test.dart` and `invite_join_screen_test.dart`
- [X] T089 [US4] Rebuild S2 `screens/discovery_screen.dart` (replace `public_group_discovery_screen.dart`) with `widgets/public_group_card.dart`; build S3 `screens/invite_join_screen.dart`
- [X] T090 [US4] Handle `qurandaily://join/<code>` via `app_links` in `lib/app/router.dart` (deferred until signed in); configure Android intent filter in `android/app/src/main/AndroidManifest.xml` and iOS URL type in `ios/Runner/Info.plist`

---

## Phase 7: User Story 5 – Volunteer for an Available Juz (P2)

**Independent test**: volunteer once → assigned to me today; concurrent volunteer → exactly one wins; not carried next day; unread at grace.

- [X] T091 [P] [US5] pgTAP tests for `volunteer_for_juz` (open only, active member, multiple juz allowed, concurrent conflict via two sessions, next-day reset) in `supabase/tests/001_us5_volunteer_test.sql`
- [X] T092 [US5] Implement `volunteer_for_juz` in `supabase/migrations/008_volunteer_functions.sql`
- [X] T093 [P] [US5] Failing tests for `KhatmaRepositoryImpl.volunteer` and `DashboardCubit.volunteer` (success updates snapshot, `juz_already_taken` → conflict message + refresh, offline → network failure) in `test/features/quran_groups/cubit/dashboard_volunteer_test.dart`
- [X] T094 [US5] Implement volunteer in repository and `DashboardCubit`; volunteered juz render as extra cards in `my_juz_card.dart` area
- [X] T095 [US5] Widget tests + UI for "أتطوع بقراءته" action and taken state in `test/features/quran_groups/view/available_juz_list_test.dart` and `widgets/available_juz_list.dart`

---

## Phase 8: User Story 6 – Manage Members and Requests (P2)

**Independent test**: quickstart scenario 8.

- [X] T096 [P] [US6] pgTAP tests for `list_join_requests`, `review_join_request` (seat allocation, group full), `get_group_members`, `move_member_seat` (swap, next-day effect), `set_member_role`, `remove_member` (today pending → available), `leave_group` (owner blocked), `transfer_ownership`, `archive_group`, `override_assignment`, supervisor limits in `supabase/tests/001_us6_manage_test.sql` Include: leaving/removal frees ALL of today's non-completed rows read by that member (seat, volunteer, override), not only the seat row.
- [X] T097 [US6] Implement management functions in `supabase/migrations/009_management_functions.sql`
- [X] T098 [P] [US6] Failing repository tests for management methods in `test/features/quran_groups/data/groups_repository_manage_test.dart`
- [X] T099 [US6] Implement management methods in `GroupsRepositoryImpl` and `KhatmaRepositoryImpl.overrideAssignment`
- [X] T100 [P] [US6] Failing `bloc_test`s for `MembersCubit` and `JoinRequestsCubit` (role-based actions, confirmations, group full, owner leave blocked) in `test/features/quran_groups/cubit/members_cubit_test.dart` and `join_requests_cubit_test.dart`
- [X] T101 [US6] Implement `MembersCubit` and `JoinRequestsCubit` in `lib/features/quran_groups/cubit/`
- [X] T102 [P] [US6] Failing widget tests for S7 Members & Seats and S8 Join Requests (owner vs supervisor vs member views, all variants) in `test/features/quran_groups/view/members_screen_test.dart` and `join_requests_screen_test.dart`
- [X] T103 [US6] Rebuild S7 `screens/members_screen.dart` (replace `member_management_screen.dart`), S8 `screens/join_requests_screen.dart` (replace `organizer_join_requests_screen.dart`), owner override sheet from dashboard `widgets/override_assignment_sheet.dart`; add archive/transfer/regenerate confirmations to S9; delete `organizer_assignment_review_screen.dart` and `assignment_draft_row.dart` (daily publish removed)

---

## Phase 9: User Story 7 – Review Daily Group History (P3)

**Independent test**: quickstart scenario 9.

- [X] T104 [P] [US7] pgTAP tests for `get_history` and `get_history_day` (members summary + own row only; owner/supervisor per-seat detail; full khatma with late) in `supabase/tests/001_us7_history_test.sql`
- [X] T105 [US7] Implement history functions in `supabase/migrations/010_history_functions.sql`
- [X] T106 [P] [US7] Failing tests for history repository methods (cache last page) and `HistoryCubit` (paging, detail by role) in `test/features/quran_groups/cubit/history_cubit_test.dart`
- [X] T107 [US7] Implement history in `KhatmaRepositoryImpl` and `HistoryCubit` in `lib/features/quran_groups/cubit/history/`
- [X] T108 [P] [US7] Failing widget tests for S10 History list and day detail (all variants) in `test/features/quran_groups/view/history_screen_test.dart`
- [X] T109 [US7] Rebuild S10 `screens/history_screen.dart` (replace `daily_history_screen.dart`) with `widgets/history_day_card.dart` and `widgets/history_day_detail.dart`

---

## Phase 10: Polish & Cross-Cutting

- [X] T110 [P] App settings S11: `SettingsCubit` (depends on `SettingsRepository` + `SessionGateway`, not `AuthCubit`) + tests + `lib/features/settings/view/settings_screen.dart` (text scale 0.85-1.6 applied to `quranLabel`, sign-out with confirm); remove `lib/features/quran_groups/view/screens/settings_screen.dart`
- [X] T111 [P] Integration test `integration_test/group_flow_test.dart`: sign up → create → invite second user → start → complete → undo → history (hosted dev project via .env)
- [X] T112 [P] Integration test `integration_test/offline_completion_test.dart`: cached dashboard offline → complete → reconnect → synced (host-runnable; device command documented in `integration_test/README.md`)
- [X] T113 Remove remaining legacy files under `lib/features/quran_groups/view/` and legacy tests not replaced; ensure `test/widget_test.dart` is a real smoke test or deleted
- [X] T114 Design system compliance review (constitution Principle VI): no raw colors/sizes/radii in features, shared components used, RTL + 200% text scale + dark theme verified on every screen
- [X] T115 Quran integrity review (Principle VII): grep code, tests, fixtures for any Arabic ayah text; only metadata repository reads Quran data; checksum test green
- [X] T116 Run `flutter analyze`, `flutter test`, `supabase test db --remote`, and all `quickstart.md` scenarios on Android emulator and iOS simulator; record results in `specs/001-track-quran-groups/quickstart.md` "Validation log" section

---

## Dependencies & Execution Order

- Phase 1 → 2A → 2B → 2C (2A and 2B may overlap after T004/T005; 2B UI needs 2A widgets).
- T008 (owner) blocks T041-T042 and every screen that shows juz ranges (T073+). T007 (owner) blocks visual verification only; tests use the theme without real font files if absent, but T114 needs them.
- US2 → US1 → US3 (sequential; US1 needs a started group, US3 needs the dashboard).
- US4, US5, US6 depend on US1; they can proceed in parallel with each other after US3 (different files except `GroupsRepositoryImpl`, which US4 and US6 must edit sequentially).
- US7 depends on US3 (needs closed days).
- Polish after all desired stories.

### Within each story

pgTAP test → migration → repository test → repository → cubit test → cubit → widget test → screen. Tests must fail before implementation.

## Parallel Examples

- Phase 2A: T009, T010, T011 together; then T016, T017, T018 together.
- US2: T053 (SQL) with T056/T058/T059 (Dart tests) – different files.
- US4: T082, T084, T086, T088 together; then implement in order.
- US6: T096, T098, T100, T102 together.

## Implementation Strategy

1. **MVP** = Phases 1-5 (setup, foundations, US2 + US1 + US3): users create a group, start the khatma, see the dashboard, and mark completion with offline support. Validate quickstart scenarios 2-5 with seeded members (scenario 1 needs US4).
2. Increment 2 (first real-user release): US4 (joining) + US5 (volunteering); then run scenario 1 end to end.
3. Increment 3: US6 (management) + US7 (history).
4. Polish, then hand over to spec 003 (Mushaf) which enables `kMushafEnabled`.

