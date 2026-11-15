# Feature Specification: Today Home, Bottom Tabs, and Personal Daily Log

**Feature Branch**: `005-home-today`
**Created**: 2026-11-15
**Status**: Draft (needs `/speckit-clarify` before planning)
**Depends on**: spec 001 (implemented), spec 004 (portion units; in progress)
**Input**: Owner feedback after using the app on a phone (2026-11-15): "The
user should not see only 'مجموعاتي'. Show their group or their wird for today
so they can open it directly (quick access). Add the bottom tabs. Add a daily
log. Put icons on the cards. Make it feel more spiritual."

## Clarifications

### Session 2026-11-15

- Q: What is the first screen after sign-in? → A: A "Today" home that lists
  the user's portions for today across all their active groups, each with a
  direct open action and a mark-complete action.
- Q: Which tabs? → A: Four bottom tabs: اليوم (Today), مجموعاتي (My groups),
  السجل (Log), الإعدادات (Settings). (To confirm in clarify.)
- Q: What does the home tab show versus "مجموعاتي"? → A: The home tab
  ("الرئيسية/اليوم") shows the user's MAIN group first (a large card: photo,
  name, today's progress, their portion with open/complete actions), then
  today's portions in their other groups. "مجموعاتي" is a separate tab that
  lists all groups the user belongs to (and pending requests) with richer
  cards. The main group defaults to the most recently opened active group and
  the user can pin another one as main ("اجعلها مجموعتي الرئيسية").
- Q: What is the daily log? → A: A personal history across all groups: per
  day, the portions the user read (on time / late), missed, and volunteered.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Today home with quick access (Priority: P1)

After sign-in the user lands on "اليوم". It greets them, shows today's date
(Gregorian and Hijri), and one card per portion assigned to them today across
all active groups (seat portion, volunteered portions, overrides). Each card
shows the group name, the portion name and range (from the metadata), the
status, the time left before the day ends, a primary "افتح الورد" action and a
"تمت القراءة" action (with undo per spec 001 rules).

**Why this priority**: It removes two taps from the most frequent daily
action and is the owner's main request.

**Independent Test**: A user in two active groups opens the app and sees two
portion cards; marking one complete updates it in place and in its group
dashboard.

**Acceptance Scenarios**:

1. **Given** a user with portions in 2 groups, **When** they open the app,
   **Then** Today shows 2 cards ordered by day end time.
2. **Given** a card, **When** the user taps "تمت القراءة", **Then** the card
   shows completed and the action becomes undo (confirmation sheet).
3. **Given** no active groups, **When** Today opens, **Then** it shows the
   spec 001 entry points (join any group primary, search, create, invite).
4. **Given** all of today's portions are done, **When** Today opens, **Then**
   it shows a calm completion message and the group progress summaries.
5. **Given** offline, **When** Today opens, **Then** cached cards show with the
   offline banner and completions queue (spec 001 offline rules).

---

### User Story 1b - Main group on the home tab (Priority: P1)

The home tab opens with the user's main group as a hero card: group photo or
generated avatar, name, today's group progress (e.g. "١٨ من ٣٠"), the user's
portion with "افتح الورد" and "تمت القراءة", and a shortcut to the group
dashboard. Below it, compact cards for today's portions in other groups. The
user can change the main group from any group's menu.

**Independent Test**: A user in 3 groups pins group B as main; the home tab
shows B as the hero card and A, C as compact cards.

**Acceptance Scenarios**:

1. **Given** no pinned group, **When** home opens, **Then** the most recently
   opened active group is the hero card.
2. **Given** the user pins another group, **When** home reopens, **Then** that
   group is the hero card (stored per user, synced across devices).
3. **Given** only one group, **When** home opens, **Then** it shows the hero
   card only, without an empty "other groups" section.

---

### User Story 2 - Bottom tabs navigation (Priority: P1)

A persistent bottom navigation with four tabs replaces the current
group-list-first flow. Each tab keeps its own navigation stack; group
dashboards open inside "مجموعاتي".

**Independent Test**: Switching tabs preserves each tab's scroll and stack;
back from a group dashboard returns to "مجموعاتي".

**Acceptance Scenarios**:

1. **Given** the signed-in app, **When** it opens, **Then** the "اليوم" tab is
   selected and four tabs are visible with icon + Arabic label.
2. **Given** a deep link `qurandaily://join/<code>`, **When** it opens,
   **Then** the join screen opens above the tabs (spec 001 behavior).
3. **Given** RTL, **When** the tabs render, **Then** order and icons follow
   RTL and each target is at least 48dp.

---

### User Story 3 - Personal daily log (Priority: P2)

"السجل" lists the user's days (newest first): per day, each portion with its
group, status (completed / late / missed / volunteered) and time; plus a
streak counter and a monthly summary (days fully completed).

**Independent Test**: After 3 days with one missed portion, the log shows 3
days, one missed item, and a streak that resets at the miss.

**Acceptance Scenarios**:

1. **Given** past days, **When** the log opens, **Then** days are grouped by
   week with clear statuses (color + icon + label).
2. **Given** a day, **When** tapped, **Then** its detail shows each portion
   and links to that group's history day.
3. **Given** no history yet, **When** the log opens, **Then** a friendly empty
   state explains it fills after the first day.

---

### User Story 4 - Richer, more spiritual visuals (Priority: P3)

Icons and avatars on cards and lists (member initial avatars, role and seat
icons, group status icons), the Islamic geometric ornament from the design
pass C on headers and empty states, muted gold accents only for ornaments.

**Independent Test**: Members, group list and Today cards show avatars/icons;
contrast checks pass in light and dark.

### Edge Cases

- A portion volunteered today appears on Today as its own card.
- Group day boundaries differ by timezone: each card uses its group's day.
- A group in a rest day (spec 004 page unit) shows "لا ورد اليوم" for that
  group, not an error.
- Sign-out returns to auth and clears the tab stacks.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After sign-in the app MUST open the Today tab.
- **FR-002**: Today MUST list every portion assigned to the user for the
  current day of each active group (seat, volunteer, override).
- **FR-003**: Each Today card MUST offer open and mark-complete/undo actions
  with spec 001 rules (grace, offline queue, undo confirmation).
- **FR-004**: The app MUST provide four bottom tabs (Today, My groups, Log,
  Settings) with independent navigation stacks.
- **FR-004a**: The home tab MUST show the user's main group as a hero card
  (photo/avatar, name, today's progress, the user's portion with actions),
  followed by today's portions in other groups; "مجموعاتي" is a separate tab.
- **FR-004b**: Users MUST be able to pin a main group; default is the most
  recently opened active group; the choice is stored per user server-side.
- **FR-005**: The Log MUST list the user's past days across groups with
  per-portion status, a streak, and a monthly summary.
- **FR-006**: Portion names/ranges MUST come from the metadata repository
  (constitution Principle VII); no Quran text is shown.
- **FR-007**: Hijri date display MUST use a tested conversion library or the
  platform calendar, not hand-written tables. (To confirm in clarify.)
- **FR-008**: All new screens MUST follow constitution Principles II and VI
  (RTL, 200% text, dark, 320dp, one primary per screen, status triplets).
- **FR-009**: Today and Log MUST work offline from cache with the offline
  banner.

### Key Entities

- **TodayItem**: group, assignment, portion (unit + index), status, day end.
- **PersonalLogDay**: date, items (group, portion, status, time), streak flag.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users mark today's portion complete in at most 2 taps from app
  open (was 4+).
- **SC-002**: Today loads in under 2 seconds on a mid-range phone (cached
  under 300 ms).
- **SC-003**: 3 of 3 test users find their portion and mark it within 10
  seconds without guidance.
- **SC-004**: All new screens pass RTL, 200% text, dark and 320dp widget tests.

## Assumptions

- A new read RPC (e.g. `get_my_today`, `get_my_log`) aggregates across groups;
  defined in the plan.
- Notifications/reminders remain out of scope (future feature).
- The in-app Mushaf (spec 003) is still separate; "افتح الورد" opens the
  personal assignment screen until 003 lands.
