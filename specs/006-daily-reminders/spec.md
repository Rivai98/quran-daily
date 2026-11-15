# Feature Specification: Local Daily Wird Reminders

**Feature Branch**: `006-daily-reminders`
**Created**: 2026-11-15
**Status**: Draft (needs `/speckit-clarify` before planning)
**Depends on**: spec 001 (groups, seats, rotation - implemented), spec 004 (portion units), spec 005 (Today home, settings)
**Input**: Owner request: "local (on-device) daily reminders inside the app to read the wird, 3 times a day: morning after Fajr, afternoon after Asr, night before sleep (about 22:00-23:00)."

## Clarifications

### Session 2026-11-15

- Q: Are reminders push notifications sent by a server or local notifications on the device? → A: Local notifications only (on-device scheduling). No server push infrastructure, no user tracking, and full functionality offline.
- Q: Which reminders are provided and can the user control them? → A: Exactly three daily reminders: morning (after Fajr), afternoon (after Asr), and night before sleep (target window 22:00–23:00, default 22:30). Each reminder can be independently toggled on or off, and its schedule can be customized.
- Q: How are the default reminder times computed? → A: Fajr and Asr reminder times are calculated offline from prayer times based on device location (or a user-chosen city if location permission is denied). Calculations use a standard prayer-times method chosen by the user (default: Egyptian General Authority of Survey). Post-prayer offsets (default: +20 minutes) are configurable. The night reminder uses a fixed clock time (default 22:30).
- Q: What happens if the user has already finished all their assigned portions for today? → A: When all assigned portions across active groups are marked completed (checked against local cache), the scheduled reminder is either skipped silently or replaced by a brief encouraging notification ("ما شاء الله، أتممت وردك اليوم").
- Q: What does notification copy look like? → A: Clear Modern Standard Arabic identifying the specific portion and group (e.g. "وردك اليوم: الحزب ١٢ في حلقة الفجر"). No Quranic aya text is ever included in notification content (constitution Principle VII).
- Q: Where does tapping a notification take the user? → A: Directly opens the Today screen (spec 005) or the specific pending assignment detail.
- Q: How are OS notification permissions handled? → A: Handled gracefully through an in-app introductory explanation before requesting OS permission on Android 13+ (API 33+) and iOS. If denied, the app continues normally and displays calm guidance in Settings.
- Q: How are reminders rescheduled? → A: Rescheduled automatically upon device timezone or clock change, upon date rollover, upon updating prayer settings, and upon completing all daily portions.
- Q: Where in the interface can users configure reminders? → A: Inside the Settings tab (spec 005) under a dedicated section labeled "التذكيرات".

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receive Daily Local Wird Reminders (Priority: P1)

A member who has pending Quran portions for the day receives timely, calm on-device notifications at morning, afternoon, and night reminding them to read their wird. Tapping the notification takes them directly to their daily assignment.

**Why this priority**: Daily consistency is the core spiritual goal of the app. Timely reminders help members maintain their habit without requiring network connectivity.

**Independent Test**: Schedule a local reminder for 1 minute in the future with a pending portion in "حلقة الفجر"; verify that the notification arrives offline with text "وردك اليوم: الحزب ١٢ في حلقة الفجر", and tapping it opens the Today screen.

**Acceptance Scenarios**:

1. **Given** an active group where the user has a pending portion (e.g. "الحزب ١٢" in "حلقة الفجر"), **When** the scheduled morning reminder fires, **Then** a local notification appears displaying "وردك اليوم: الحزب ١٢ في حلقة الفجر".
2. **Given** a user has multiple pending portions across groups, **When** a reminder fires, **Then** the notification mentions the next due portion or summarizes the pending count (e.g. "لديك وردان لم يكتمل قضاؤهما اليوم").
3. **Given** a visible wird notification, **When** the user taps it, **Then** the app launches directly into the Today screen (spec 005) with the pending portion visible.
4. **Given** the device is completely offline (airplane mode), **When** a reminder time arrives, **Then** the notification fires accurately from on-device scheduling without error.
5. **Given** all assigned portions for today are completed, **When** a reminder time arrives, **Then** no reminder to read is shown; instead, either no notification fires or a calm completion message appears ("ما شاء الله، أتممت وردك اليوم").

---

### User Story 2 - Configure Reminder Times and Offsets in Settings (Priority: P1)

A user opens the Settings screen and navigates to "التذكيرات" to enable or disable specific reminders, adjust prayer offsets, or change the night reminder time.

**Why this priority**: Users have diverse daily schedules and prayer routines; customization is essential to prevent notification fatigue.

**Independent Test**: Turn off the afternoon reminder, change the morning offset to +30 minutes, and set the night reminder to 23:00; verify that scheduled triggers reflect the new settings.

**Acceptance Scenarios**:

1. **Given** the Settings tab, **When** the user opens "التذكيرات", **Then** three reminder cards appear: "تذكير الصباح (بعد الفجر)", "تذكير المساء (بعد العصر)", and "تذكير الليل (قبل النوم)", each with an on/off toggle and schedule details.
2. **Given** the morning reminder card, **When** the user adjusts the offset from +20 to +30 minutes, **Then** the displayed calculated time updates and the underlying local schedule is refreshed.
3. **Given** the night reminder card, **When** the user opens the time picker and sets 23:00, **Then** the reminder schedule updates to 23:00 every night.
4. **Given** a user toggles off "تذكير المساء", **When** afternoon prayer time passes, **Then** no afternoon notification is delivered.

---

### User Story 3 - Prayer Calculation Method and Location Setup (Priority: P2)

To calculate Fajr and Asr prayer times accurately offline, the app determines the user's city via location or manual selection, and allows choosing the calculation authority.

**Why this priority**: Correct prayer times require geographical coordinates and an agreed calculation authority.

**Independent Test**: Switch calculation authority from Egyptian General Authority to Umm Al-Qura or select a manual city (e.g. "القاهرة"); verify recalculation of prayer times and reminder schedules.

**Acceptance Scenarios**:

1. **Given** first setup of prayer-based reminders, **When** the app asks for location permission, **Then** an Arabic explanation is presented explaining why location is needed for prayer times.
2. **Given** location permission is granted, **When** prayer times are computed, **Then** the device coordinates are used with the selected calculation method (default: الهيئة المصرية العامة للمساحة).
3. **Given** location permission is denied by the user, **When** the user visits reminder settings, **Then** the app provides a city picker allowing manual city selection from an offline list without degradation.
4. **Given** the calculation method selector, **When** the user chooses an alternative method (e.g. أم القرى, رابطة العالم الإسلامي), **Then** prayer times and dependent reminder times are recalculated immediately.

---

### User Story 4 - Reschedule on Timezone Change and Date Rollover (Priority: P3)

When the user travels to a different timezone or when midnight rolls over, the app recalculates prayer times and schedules the next day's notifications automatically.

**Independent Test**: Simulate a timezone transition; verify that pending notification triggers are re-anchored to the local time of the new timezone.

**Acceptance Scenarios**:

1. **Given** the device changes its system timezone, **When** the OS broadcasts the time change or the app is brought to foreground, **Then** the reminders are rescheduled using the new timezone.
2. **Given** the end of a group day, **When** the next day begins, **Then** the next 24 hours of reminder triggers are queued based on the new day's prayer times.

### Edge Cases

- **Battery Optimization / Doze Mode**: Platform power management may delay alarms; the scheduler requests exact alarms where supported and handles battery-saver constraints gracefully.
- **Permission Revoked in OS Settings**: If notification permission was granted and later revoked in system settings, the app detects this on next opening, updates the toggle state in Settings, and shows a helpful action button ("فتح إعدادات النظام").
- **Rest Day / No Assigned Portions**: When a group is in a rest day (spec 004 page unit where seat has no portion) or the user is not in any active group, reminders are suppressed.
- **Late Completion**: If a user marks their portion completed after the morning reminder, subsequent afternoon and night reminders for that day are suppressed.
- **Reboot / Device Restart**: Upon device restart, an on-boot receiver reschedules active reminders from stored preferences.
- **Extreme Latitudes / High Latitudes**: If prayer calculation library fails to calculate twilight times for a specific coordinate, it falls back to standard middle-latitude estimates or a fixed time fallback with a polite Arabic notice.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST schedule and deliver reminders solely as local on-device notifications; it MUST NOT rely on server push, FCM, APNs, or external network services.
- **FR-002**: The system MUST provide exactly three distinct daily reminder slots:
  - Morning (default: calculated Fajr + 20 minutes offset)
  - Afternoon (default: calculated Asr + 20 minutes offset)
  - Night (default: fixed clock time 22:30)
- **FR-003**: Each reminder slot MUST have an independent enable/disable toggle in the Settings screen under the section "التذكيرات".
- **FR-004**: The system MUST allow the user to customize the post-prayer offset in minutes (from 0 to +120 minutes) for morning and afternoon reminders.
- **FR-005**: The system MUST allow the user to customize the target time for the night reminder using a standard time picker.
- **FR-006**: The system MUST compute prayer times completely offline using astronomical algorithms and coordinates.
- **FR-007**: The system MUST support standard prayer calculation authorities, including:
  - الهيئة المصرية العامة للمساحة (Egyptian General Authority of Survey - default)
  - جامعة أم القرى (Umm Al-Qura University, Makkah)
  - رابطة العالم الإسلامي (Muslim World League)
  - جامعة العلوم الإسلامية بكراتشي (University of Islamic Sciences, Karachi)
  - الاتحاد الإسلامي بأمريكا الشمالية (ISNA)
- **FR-008**: The system MUST request device location permission with a preceding Arabic contextual explanation; if permission is denied, the system MUST allow selecting a city from an offline pre-populated directory of major cities.
- **FR-009**: The system MUST verify daily portion completion status against local cache prior to firing a reminder; if all assigned portions for today are completed, the system MUST skip the reminder or deliver a brief congratulatory message ("ما شاء الله، أتممت وردك اليوم").
- **FR-010**: Notification text MUST include the name of the assigned portion and group name (e.g. "وردك اليوم: الحزب ١٢ في حلقة الفجر") using Arabic-Indic numerals; the notification MUST NOT contain Quranic aya text (constitution Principle VII).
- **FR-011**: Tapping a notification MUST open the application directly to the Today home screen (spec 005) or the corresponding assignment view.
- **FR-012**: The system MUST request notification permissions on platforms requiring runtime consent (Android 13+ / iOS) before activating notifications, and show guidance if denied.
- **FR-013**: The system MUST automatically recalculate prayer times and reschedule notification triggers upon device boot, timezone change, daily rollover, or settings update.
- **FR-014**: All reminder settings UI MUST comply with constitution Principles II and VI (Cairo typography, RTL layout, status tokens, 48x48dp minimum targets, 320dp responsiveness).

### Key Entities

- **ReminderSlot**: Identifier for the reminder slot (`morning_fajr`, `afternoon_asr`, `night_sleep`).
- **ReminderPreferences**: Persistent configuration entity storing:
  - `slot`: ReminderSlot
  - `isEnabled`: boolean
  - `offsetMinutes`: integer (for prayer-based slots)
  - `customTime`: time of day (for fixed slots or manual override)
- **PrayerSettings**: Persistent configuration for prayer calculations:
  - `calculationMethod`: enum (Egyptian, UmmAlQura, MWL, Karachi, ISNA)
  - `locationMode`: enum (`device_gps`, `manual_city`)
  - `manualCityName`: string (nullable)
  - `latitude`: double
  - `longitude`: double
- **ScheduledTrigger**: Local system alarm record holding notification ID, trigger timestamp, slot type, and payload references.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of reminder calculations and scheduling operations execute successfully without internet connectivity.
- **SC-002**: Scheduled local notifications trigger within 60 seconds of their intended time on devices not restricted by battery saver.
- **SC-003**: 100% of tested notification taps launch the app directly to the Today screen in under 1.5 seconds.
- **SC-004**: 0 instances of handwritten or generated Quranic text inside notification titles or bodies (verified against constitution Principle VII).
- **SC-005**: 100% of completed-day scenarios correctly suppress reading reminder notifications or replace them with the completion message.
- **SC-006**: Users can adjust a reminder time or offset in the Settings screen in fewer than 3 taps.
- **SC-007**: When location permission is denied, 100% of users can select an offline city and have active prayer times within 30 seconds.

## Assumptions

- Offline prayer time calculations will be powered by a verified astronomical calculation package (e.g. `adhan` Dart package) bundled in the app.
- Local notification scheduling will use a platform-native integration package (e.g. `flutter_local_notifications`) supporting exact alarms on Android (`SCHEDULE_EXACT_ALARM`) and `UNUserNotificationCenter` on iOS.
- Target destinations rely on the Today screen and Settings tab defined in spec 005.
- Battery saver modes and OEM-specific aggressive process termination may affect background alarm delivery; documentation will guide users on exempting the app from aggressive battery optimization if needed.
- Audio recitation or custom athan audio files are out of scope for v1; notifications use system default notification tones.
