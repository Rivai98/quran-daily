# Implementation Plan: Local Daily Wird Reminders

**Branch**: `006-daily-reminders` | **Date**: 2026-11-15 | **Spec**: [spec.md](./spec.md)
**Constitution**: v2.4.0 (binding) | **Builds on**: 001, 004, 005 (Today data, حسابي/Settings)

## Summary

On-device notifications 3 times a day (after Fajr, after Asr, night 22:30),
computed offline from prayer times. A group owner can set the group's schedule;
members can mute a group or a slot for themselves. When a user is in two groups,
each firing time sends ONE combined notification listing the still-pending
portions. Finishing all portions cancels the rest of the day silently.

## Technical Context

Flutter, MVVM + Cubit, get_it, sqflite, hosted Supabase. New packages (pub.dev,
widely used): `flutter_local_notifications`, `timezone`, `flutter_timezone`,
`adhan` (tested prayer-time calculation, Egyptian General Authority method
default), `geolocator` (optional coarse location; manual city fallback).
Android: `POST_NOTIFICATIONS` (13+), `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`
policy: use inexact `AndroidScheduleMode.inexactAllowWhileIdle` unless the user
grants exact alarms; `RECEIVE_BOOT_COMPLETED` for rescheduling.
Migration range: `2026111511NNNN`.

## Constitution Check

| Principle | Compliance |
|-----------|------------|
| I Offline core | Scheduling, prayer times and pending check all local (cached Today data) |
| II Arabic/RTL | Notification copy and settings in ArabicStrings, Arabic numerals |
| III Test-first | Pure scheduler tests (times, merging, cancel rules), cubit/widget tests, pgTAP for schedules |
| IV MVVM + Cubit | ReminderScheduler service (pure), RemindersCubit, GroupScheduleCubit |
| V Simplicity | One planner function: (settings, group schedules, pending items, prayer times) → list of notifications |
| VI Design system | Settings section "التذكيرات" with design-system tiles/switches |
| VII Quran integrity | Notifications show portion names from metadata only; never ayah text |

Gate: PASS.

## Data

- `group_reminder_schedules(group_id pk, fajr_on bool, fajr_offset_min int, asr_on bool, asr_offset_min int, night_on bool, night_time time, message text <= 80, updated_by, updated_at)`; RLS: members read, owner writes. RPC `set_group_reminder_schedule(...)` (owner only), included in `get_dashboard`/`get_my_today` as `reminder_schedule`.
- Local (sqflite/shared prefs): personal settings (3 toggles, offsets, night time, calc method, location or city), per-group mute flags.

## Planner (pure Dart, the heart)

`planReminders(date, prayerTimes, personal, groupSchedules, mutes, pending)` →
list of `{fireAt, title, body, payload}`:
1. Slots from each non-muted group schedule (or personal settings when the user
   has no group with a schedule).
2. Group slots with the same minute merge into one notification.
3. Body lists only portions pending for those groups (portion names via
   QuranMetadataRepository), e.g. "وردك اليوم: الحزب ١٢ في حلقة الفجر، والجزء ٣ في حلقة العائلة".
4. If nothing is pending → no notification. Past times today are skipped.
Schedule today + next 2 days; reschedule on app start, completion/undo,
settings change, timezone change, boot, date change.

## Work split

| Agent | Scope |
|-------|-------|
| backend agent | T001-T004 (schedule table, RPC, dashboard/today fields, pgTAP) |
| app agent A | T005-T012 (planner, prayer times, scheduler service, permissions, boot/tz) |
| app agent B | T013-T018 (settings UI "التذكيرات", group schedule screen for owner, mute UI) |
