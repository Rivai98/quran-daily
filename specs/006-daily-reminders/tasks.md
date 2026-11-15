# Tasks: Local Daily Wird Reminders

**Plan**: [plan.md](./plan.md). Test-first.

## Phase 1: Backend
- [ ] T001 pgTAP `supabase/tests/006_group_reminders_test.sql`: owner sets schedule, member cannot, members read, non-members cannot; validation (offsets 0..180, message <= 80)
- [ ] T002 Migration `supabase/migrations/20261115110001_group_reminder_schedules.sql`: table, RLS, `set_group_reminder_schedule` RPC
- [ ] T003 Migration `20261115110002_reminder_schedule_in_reads.sql`: add `reminder_schedule` to `get_dashboard` (and `get_my_today` if present) additively
- [ ] T004 Apply to DEV; run ALL pgTAP files: 0 failed

## Phase 2: Scheduling core (app agent A)
- [ ] T005 [P] Tests `test/features/reminders/domain/planner_test.dart`: slot times from prayer times + offsets, night time, merge same-minute group slots, body lists only pending portions with group names, nothing pending → none, past times skipped, mutes, personal fallback when no group schedule
- [ ] T006 `lib/features/reminders/domain/reminder_planner.dart` (pure)
- [ ] T007 [P] Tests for prayer times adapter (adhan, Egyptian method default, method switch, known city sample computed by the library, not typed tables)
- [ ] T008 `lib/features/reminders/data/prayer_times_service.dart` + location/city provider (geolocator optional, bundled city list fallback)
- [ ] T009 `lib/features/reminders/data/notification_scheduler.dart` (flutter_local_notifications + timezone): schedule/cancel by id range, Android channels, payload → open Home/assignment
- [ ] T010 Permission flow: in-app explanation sheet before Android 13+/iOS request; denied → calm guidance
- [ ] T011 Reschedule triggers: app start, completion/undo (KhatmaRepository hook), settings change, timezone change, boot receiver, date change
- [ ] T012 DI + Android manifest/iOS config

## Phase 3: UI (app agent B)
- [ ] T013 [P] Cubit tests `test/features/reminders/cubit/` (personal settings, group schedule, mutes)
- [ ] T014 RemindersCubit + settings section "التذكيرات" (3 toggles, offsets, night time, calc method, location/city, test notification)
- [ ] T015 Owner screen "تذكيرات المجموعة" from group settings: slots, offsets/time, message
- [ ] T016 Member mute: per group / per slot in group menu
- [ ] T017 [P] Widget tests (RTL, dark, 320dp, 200%)
- [ ] T018 Strings block `// --- 006 reminders ---`

## Phase 4: Validation
- [ ] T019 Emulator: schedule a reminder 1 min ahead with a pending portion → notification text and tap opens Home; complete → later reminders cancelled
- [ ] T020 analyze 0, all tests green, pgTAP 0 failed; validation log; merge to main

## Validation log
_(filled at T020)_
