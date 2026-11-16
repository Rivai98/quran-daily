# Tasks: Local Daily Wird Reminders

**Plan**: [plan.md](./plan.md). Test-first.

## Phase 1: Backend
- [x] T001 pgTAP `supabase/tests/006_group_reminders_test.sql`: owner sets schedule, member cannot, members read, non-members cannot; validation (offsets 0..180, message <= 80)
- [x] T002 Migration `supabase/migrations/20261115110001_group_reminder_schedules.sql`: table, RLS, `set_group_reminder_schedule` RPC
- [x] T003 Migration `20261115110002_reminder_schedule_in_reads.sql`: add `reminder_schedule` to `get_dashboard` (and `get_my_today` if present) additively
- [x] T004 Apply to DEV; run ALL pgTAP files: 0 failed

## Phase 2: Scheduling core (app agent A)
- [X] T005 [P] Tests `test/features/reminders/domain/planner_test.dart`: slot times from prayer times + offsets, night time, merge same-minute group slots, body lists only pending portions with group names, nothing pending → none, past times skipped, mutes, personal fallback when no group schedule
- [X] T006 `lib/features/reminders/domain/reminder_planner.dart` (pure)
- [X] T007 [P] Tests for prayer times adapter (adhan, Egyptian method default, method switch, known city sample computed by the library, not typed tables)
- [X] T008 `lib/features/reminders/data/prayer_times_service.dart` + location/city provider (geolocator optional, bundled city list fallback)
- [X] T009 `lib/features/reminders/data/notification_scheduler.dart` (flutter_local_notifications + timezone): schedule/cancel by id range, Android channels, payload → open Home/assignment
- [X] T010 Permission flow: in-app explanation sheet before Android 13+/iOS request; denied → calm guidance
- [X] T011 Reschedule triggers: app start, completion/undo (KhatmaRepository hook), settings change, timezone change, boot receiver, date change
- [X] T012 DI + Android manifest/iOS config

## Phase 3: UI (app agent B)
- [X] T013 [P] Cubit tests `test/features/reminders/cubit/` (personal settings, group schedule, mutes)
- [X] T014 RemindersCubit + settings section "التذكيرات" (3 toggles, offsets, night time, calc method, location/city, test notification)
- [X] T015 Owner screen "تذكيرات المجموعة" from group settings: slots, offsets/time, message
- [X] T016 Member mute: per group / per slot in group menu
- [X] T017 [P] Widget tests (RTL, dark, 320dp, 200%)
- [X] T018 Strings block `// --- 006 reminders ---`

## Phase 4: Validation
- [X] T019 Emulator: schedule a reminder 1 min ahead with a pending portion → notification text and tap opens Home; complete → later reminders cancelled
- [X] T020 analyze 0, all tests green, pgTAP 0 failed; validation log; merge to main

## Validation log
`flutter analyze`: No issues found. `flutter test`: All tests passed (341 tests). Backend pgTAP remains green from T004; no SQL changes were made in this app worktree. T019 device-level notification/tap check was not run because it requires an authenticated test group and assignment on the emulator.

### 2026-11-16 (qa) T019
`integration_test/spec_validation_test.dart` on emulator-5554 @ 28c435e, fresh test accounts:
- scheduled: 3 reminders for 09:05 with a pending juz; title «وردك اليوم», body «الجزء الأول في تحقق 1794812584060» (pendingNotificationRequests);
- delivered: the same text appeared in the active notifications;
- tap: the plugin's tap handler (`openHomeFromReminder`) shows الرئيسية with the Home tab selected. App bug fixed first: the tap used to push مجموعاتي on the root stack (16fd999). The OS-level tap itself was not automated (outside Flutter's test driver);
- cancel: after «تمت القراءة» on Home, no reminders remained for that group.
- Gates on qa @ 4a49987: `flutter analyze` No issues; `flutter test` 595 passed, 0 failed.
- pgTAP (hosted DEV, `scripts/run_remote_pgtap.py`, every file in `supabase/tests`): 24 files, 593 passed, 0 failed.
- Integration tests on emulator-5554 (Android, swiftshader) @ 4a49987: group_flow, home_flow, mushaf_flow, offline_completion, portion_flow all passed.
- `integration_test/spec_validation_test.dart` passed in full @ 28c435e (log below). Its re-run in the final pass, and the screenshot tour re-run, were stopped by the owner's publish request, so they were not repeated after 92564cd/fab9d47/745f152.
