# Feature Specification: Configurable Daily Portion (Wird Unit)

**Feature Branch**: `004-portion-units`
**Created**: 2026-11-15
**Status**: Draft
**Depends on**: spec 001 (groups, seats, daily rotation) - implemented
**Input**: Owner request: "The owner chooses whether members read a quarter,
a hizb, a juz... each day; the wird does not have to be a full juz."

## Clarifications

### Session 2026-11-15

- Q: When the unit is smaller than a juz, how does the khatma work? → A: The
  khatma becomes a multi-day **cycle**. Seats stay at most 30; each seat reads
  one portion per day. A cycle of N portions takes `ceil(N / 30)` days (juz 1,
  half juz/hizb 2, quarter 8, page 21). Within a cycle, day k assigns the next
  block of 30 portions. When a new cycle starts, every seat shifts by one
  portion so members rotate across the whole Quran over successive khatmas.
  With the juz unit this is exactly today's behavior (1-day cycle, +1 shift).
- Q: Which units can the owner choose? → A: Juz (30), half juz (60), hizb
  (60), quarter hizb (240), page (604).
- Q: Where do portion boundaries come from? → A: Only from the bundled
  Tanzil metadata (`assets/quran/quran-data.xml`: juz, quarter, page
  elements); hizb = 4 quarters, half juz = 2 hizb (constitution Principle VII).
- Q: What if N is not a multiple of 30 (page: 604)? → A: The last day of the
  cycle assigns only the remaining portions (pages 601-604 to seats 1-4); the
  other seats have no portion that day and their status shows "لا ورد اليوم"
  (rest day). Rest days never count as missed.
- Q: Can the unit change after the khatma started? → A: Yes, owner only; the
  change takes effect when the next cycle starts (never mid-cycle). While the
  group is forming it applies immediately.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Owner picks the daily portion when creating a group (Priority: P1)

The owner chooses the daily portion unit while creating a group; the default
is juz. Members see the unit on the group card, the invite preview and the
dashboard.

**Why this priority**: It is the core of the request; every other story
depends on a group having a unit.

**Independent Test**: Create a group with unit "hizb"; the forming dashboard,
group card and invite preview show "حزب يوميًا" and a cycle length of 2 days.

**Acceptance Scenarios**:

1. **Given** the create-group form, **When** the owner opens it, **Then** a
   unit selector shows juz (selected), half juz, hizb, quarter hizb, page,
   each with its daily amount and khatma length in days.
2. **Given** a group created with unit hizb, **When** anyone views its card,
   preview or dashboard, **Then** the unit and "ختمة كل يومين" are shown.
3. **Given** an existing group from before this feature, **When** it loads,
   **Then** its unit is juz and nothing else changes.

---

### User Story 2 - Members read one portion per day in a multi-day cycle (Priority: P1)

Each seat gets one portion per day computed from the unit, the cycle day and
the cycle shift. The dashboard shows today's portion with its exact range
(from sura/aya to sura/aya, read from the metadata), the cycle progress
(day k of C, portions done of N) and the 30 seat tiles for today.

**Why this priority**: Without the rotation the unit has no effect.

**Independent Test**: Start a hizb group with start portion 1 and 30
members; day 1 seat s reads hizb s, day 2 seat s reads hizb s+30; day 3
(new cycle) seat s reads hizb s+1 (60 wraps to 1).

**Acceptance Scenarios**:

1. **Given** a quarter-hizb group (240 portions), **When** cycle day k
   (1..8) opens, **Then** seat s reads quarter `((shift + (k-1)*30 + s - 1)
   mod 240) + 1`.
2. **Given** a page group on cycle day 21, **When** the day opens, **Then**
   seats 1-4 read the last four pages of the cycle block and seats 5-30 show
   "لا ورد اليوم" (rest day), which is not missed.
3. **Given** the last day of a cycle closes, **When** the next day opens,
   **Then** a new cycle starts with shift + 1 and cycle day 1.
4. **Given** today's portion, **When** the member opens it, **Then** the
   portion name (e.g. "الحزب ١٢") and its sura/aya range come from the
   metadata repository; no Quran text is displayed.

---

### User Story 3 - Khatma completion is tracked per cycle (Priority: P2)

A khatma is complete when every portion of the cycle is completed or late.
History lists cycles (khatmas) with their days; the full-khatma badge appears
on the cycle, not on each day (except juz, where cycle = day).

**Why this priority**: Users need to know when the group finished a khatma.

**Independent Test**: In a hizb group complete all 30 portions on both days
of a cycle; history shows one completed khatma spanning 2 days.

**Acceptance Scenarios**:

1. **Given** a cycle whose portions are all completed or late, **When** its
   last day closes, **Then** the cycle is marked "ختمة كاملة".
2. **Given** a cycle with an unread portion, **When** it closes, **Then** it
   is incomplete and the unread portions are listed in the day detail.
3. **Given** volunteering and owner override from spec 001, **When** used in
   a non-juz group, **Then** they work on today's portions unchanged.

---

### User Story 4 - Owner changes the unit (Priority: P3)

The owner changes the unit in group settings; the change applies from the
next cycle (immediately while forming). Members see a notice "سيتغير الورد
إلى ... بداية الختمة القادمة".

**Independent Test**: Change an active juz group to hizb; tomorrow's cycle
uses hizb; today is unchanged.

**Acceptance Scenarios**:

1. **Given** an active group, **When** the owner picks a new unit, **Then** a
   confirmation explains when it applies, and a pending-change notice shows
   on the dashboard until it applies.
2. **Given** a supervisor or member, **When** they open settings, **Then**
   they cannot change the unit.

### Edge Cases

- Fewer than 30 active members: empty seats' portions are "available" and can
  be volunteered for (spec 001 rules); the cycle length is unchanged.
- The owner changes the unit twice before the next cycle: the last choice wins.
- Start portion when starting a khatma: the owner picks a start portion within
  the unit (1..N) instead of a start juz; default 1.
- Timezone/day boundaries, grace period, offline completion and undo behave
  exactly as in spec 001; only the portion assigned changes.
- Existing groups and history rows keep juz semantics (migration defaults).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A group MUST have a portion unit in {juz, half_juz, hizb,
  quarter, page}; default juz; existing groups become juz.
- **FR-002**: The create-group form MUST offer the unit selector with the
  daily amount and khatma length (days) for each option.
- **FR-003**: Portion counts and boundaries MUST be derived only from the
  bundled Tanzil metadata through the metadata repository; the server stores
  only unit, portion index and counts, never Quran text or hand-typed ranges.
- **FR-004**: Cycle length MUST be `ceil(N / 30)` days where N is the
  portion count of the unit.
- **FR-005**: On cycle day k (1-based) with shift h, seat s has offset
  `o = (k-1)*30 + (s-1)`; if `o >= N` the seat has a rest day (only possible
  on the last day of a partial cycle); otherwise it MUST be assigned portion
  `((h + o) mod N) + 1`. (h starts at start_portion - 1.)
- **FR-006**: When a cycle's last day closes, the next day MUST start a new
  cycle with `h = (h + 1) mod N` and k = 1.
- **FR-007**: Rest-day seats MUST show "لا ورد اليوم", MUST NOT be missed, and
  MUST NOT count toward completion totals.
- **FR-008**: A cycle MUST be a full khatma when all of its N portions are
  completed or late; history MUST group days by cycle.
- **FR-009**: The dashboard MUST show today's portion name and range (from
  metadata), cycle day k of C, and cycle progress (completed of N).
- **FR-010**: Only the owner MAY change the unit; it MUST take effect at the
  next cycle start (immediately while forming) and show a pending notice.
- **FR-011**: Starting a khatma MUST take a start portion 1..N (default 1).
- **FR-012**: Volunteering, override, leave/remove freeing rows, grace and
  offline sync from spec 001 MUST work unchanged for every unit.
- **FR-013**: Group card, invite preview and public discovery card MUST show
  the unit ("جزء يوميًا"، "حزب يوميًا"...).

### Key Entities

- **Group**: adds `portion_unit` (enum) and `pending_portion_unit` (nullable).
- **Khatma cycle**: group, cycle number, unit, N, shift h, start date, length
  C, completed/late/missed/unread counts, full_khatma.
- **Group day**: adds cycle reference and cycle day k.
- **Assignment**: `juz` generalizes to `portion_index` with the unit taken
  from the cycle; rest-day seats have no assignment row.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An owner creates a group with any of the 5 units in under 1
  minute; 100% of groups show their unit on card, preview and dashboard.
- **SC-002**: For every unit, automated tests confirm that one full cycle
  covers each portion exactly once (no gaps, no duplicates) and the next cycle
  shifts every seat by one.
- **SC-003**: Juz groups behave identically to spec 001 (all existing
  rotation, completion and history tests stay green).
- **SC-004**: 0 hand-typed Quran boundaries in code, tests or migrations
  (constitution Principle VII review).
- **SC-005**: Members identify today's portion and its range within 5 seconds
  of opening the dashboard (usability check with 3 users).

## Assumptions

- Seats remain capped at 30; units smaller than a juz lengthen the khatma
  rather than adding seats (owner decision 2026-11-15).
- Range display uses sura names and aya numbers from the metadata file; the
  in-app Mushaf (spec 003) is out of scope.
- No change to authentication, roles, invite flow or notifications.
