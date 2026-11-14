# Feature Specification: Quran Group Reading Tracker

**Feature Branch**: `001-track-quran-groups`

**Created**: 2026-06-20

**Updated**: 2026-11-14 (group lifecycle, automatic rotation, vacant seats)

**Status**: Draft

**Input**: User description: "design the app ui, the idea of the app to make group of people to manage together through read quran for everyone and assign 1 part of quran for everyone, the people in one group are 30 and assign to anyone in specific group have part to finish in day, the idea of the app to track the process"

**Amendment input (2026-11-14)**: The real group runs today on WhatsApp. A group has numbered seats 1-30; each day every seat reads one juz, members reply "تم" when done, and the next day every seat moves to the next juz (30 wraps to 1). Some seats are empty and the group still runs. Juz 30 is read with دعاء الختم. Any user may create a group; groups need joining, invites, and roles. Full amendment brief: `docs/prompts/01-amend-001-group-lifecycle.md`.

## Clarifications

### Session 2026-06-21

- Q: Should v1 include an in-app Quran reader, or only show Quran part labels/ranges and track completion? → A: Show Quran part label/range only; no in-app reader in v1. *(Superseded 2026-11-14: the Mushaf is delivered by spec 003; this feature provides only the entry point.)*
- Q: Which calendar day should determine the daily cycle cutoff and late completions? → A: Group-level timezone chosen by organizer.
- Q: How should members join a Quran group in v1? → A: Public group discovery with join request. *(Extended 2026-11-14: also auto-accept groups and invite links.)*
- Q: What should v1 do with push notifications? → A: No push notification work in v1; notifications are later.
- Q: What should public group discovery show before a user is approved to join? → A: Group name, short description, member count, and timezone only; show the Arabic pending status "بانتظار القبول من مالك المجموعة".

### Session 2026-11-14

- Q: Who can create groups? → A: Any signed-in user; the creator becomes the Owner. One account can own at most 3 non-archived groups.
- Q: Must a group have 30 members before it runs? → A: No. A group has 30 numbered seats; the Owner can start the khatma with any number of members (at least 1). Empty seats are allowed.
- Q: Who distributes the juz each day? → A: Nobody. Assignments rotate automatically: each new group day, every seat advances by one juz (30 wraps to 1). The daily manual publish flow is removed.
- Q: What happens to the juz of an empty seat? → A: It is shown as "متاح"; any active member can volunteer to read it for that day only. If nobody reads it, history records it as "لم يقرأه أحد".
- Q: How do users join? → A: Public discovery (with join request or auto-accept, chosen by the Owner), a one-tap "join any group that needs members", and invite links/codes for private or public groups.
- Q: What roles exist? → A: Owner, optional Supervisor (appointed by the Owner), and Member.
- Q: How long after the day ends can a member still record completion? → A: Until the end of the following group day; such completions are recorded as late. After that the day is closed.
- Q: Who can see group history? → A: All active members see daily summaries and their own record; Owner and Supervisors also see which seat/member missed each juz.
- Q: Can a member volunteer for more than one vacant juz per day? → A: Yes, any number, one tap per juz; first volunteer wins each juz.
- Q: What happens when the Owner wants to leave? → A: The Owner must transfer ownership to another active member first, or archive the group.
- Q: Which groups does "join any group that needs members" pick? → A: Only public, auto-accept, non-archived groups with at least one empty seat; prefer groups whose timezone matches the user's device timezone, then fewest empty seats.
- Q: Can a removed member rejoin the same group? → A: Only through Owner/Supervisor approval; their join attempts become pending requests even in auto-accept groups or via invite.
- Q: Does a day count as a full khatma if some juz were read late? → A: Yes, a day is a full khatma when all 30 juz are completed or late; history still shows the late count separately.
- Q: Can the Owner assign an available juz (empty seat) directly to a member for today? → A: Yes, using the same today-only override as for occupied seats.
- Q: What are the limits on group name and description? → A: Name 3-60 characters, short description up to 200 characters, both trimmed; names need not be unique.
- Q: How quickly must a new group day appear after rollover? → A: Within 1 minute of the group's rollover for any member opening the app online; offline members see it as soon as they reconnect.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Today's Group Reading Progress (Priority: P1)

A member opens the app and immediately sees today's khatma for their group: their own juz, the status of all 30 juz, which juz are available because their seat is empty, and how close the group is to completing the full Quran today.

**Why this priority**: Daily visibility is the core value. Without it members cannot coordinate or know whether the group is on track.

**Independent Test**: Open an active group with some empty seats and verify the member can identify their juz, completed count, remaining count, available juz, and the completion percentage.

**Acceptance Scenarios**:

1. **Given** an active group on its current day, **When** a member opens the group dashboard, **Then** the app shows today's overall progress, all 30 juz with their status, and the member's own juz highlighted with its primary action.
2. **Given** 12 juz are completed, 15 pending, and 3 belong to empty seats, **When** any member views the dashboard, **Then** the app shows 12 of 30 completed and visually distinguishes completed, pending, and available juz.
3. **Given** the member has not completed today's juz, **When** they view the dashboard, **Then** their juz, its reading range, and the action to mark it complete are visible without scrolling.
4. **Given** today the member's seat reads juz 30, **When** they view their assignment, **Then** the app indicates that juz 30 is read with دعاء الختم.

---

### User Story 2 - Create a Group and Start the Khatma (Priority: P1)

Any signed-in user creates a group, invites or accepts members into seats, and starts the daily khatma when ready. From then on assignments rotate automatically every day.

**Why this priority**: Without groups there is nothing to track. Starting must be simple and must not require a full 30 members.

**Independent Test**: Create a group, add 5 members, start the khatma with seat 1 on juz 1, and verify that today seat k reads juz k and tomorrow seat k reads juz k+1, with juz 30 wrapping to juz 1.

**Acceptance Scenarios**:

1. **Given** a signed-in user owning fewer than 3 groups, **When** they submit a name, short description, timezone, daily start time, visibility, and join mode, **Then** a forming group is created and they occupy seat 1 as Owner.
2. **Given** a user already owns 3 non-archived groups, **When** they try to create another, **Then** creation is blocked with an Arabic explanation.
3. **Given** a forming group with at least 1 member, **When** the Owner taps "ابدأ الختمة" and chooses the starting juz for seat 1, **Then** the group becomes active and today's assignments are created for every seat.
4. **Given** an active group, **When** the group's day rolls over, **Then** every seat advances to the next juz automatically, without any Owner action.
5. **Given** a forming group, **When** the Owner moves members between seats, **Then** each member occupies exactly one seat and no seat holds two members.

---

### User Story 3 - Mark Personal Reading Completion (Priority: P1)

A member reads their juz for the day and marks it complete so the group sees progress update.

**Why this priority**: Tracking depends on members reporting completion. The action must be fast, obvious, and reversible only through confirmation.

**Independent Test**: Sign in as a member with today's juz, mark it complete, and verify the personal status and the group count update; undo it and verify both revert.

**Acceptance Scenarios**:

1. **Given** a pending juz for today, **When** the member marks it complete, **Then** it is recorded as completed and the group count increases by one.
2. **Given** the member already completed today's juz, **When** they view it, **Then** the completed state is shown and a duplicate completion is not possible.
3. **Given** the member marked completion by mistake, **When** they confirm undo before the day closes, **Then** the juz returns to pending and the group count decreases by one.
4. **Given** the member is offline, **When** they mark completion, **Then** their own state updates immediately and the group is updated when connectivity returns.
5. **Given** the day has ended but the following day has not, **When** the member marks yesterday's juz complete, **Then** it is recorded as late.

---

### User Story 4 - Discover and Join Groups (Priority: P2)

A user without a group finds a group that needs members and joins it, through discovery, one-tap matching, or an invite link.

**Why this priority**: Groups fill up through joining; without it only the Owner can be in a group.

**Independent Test**: As a new user, see the list of groups that need members, join an auto-accept group immediately, request to join an approval group and see the pending state, and join a private group through an invite link.

**Acceptance Scenarios**:

1. **Given** public groups with empty seats exist, **When** the user opens discovery, **Then** groups are listed with name, short description, "N / 30", timezone, and forming/active status, with groups closest to full first; member lists and progress are hidden.
2. **Given** an auto-accept group with an empty seat, **When** the user taps join, **Then** they become an active member in an empty seat immediately.
3. **Given** an approval group, **When** the user requests to join, **Then** they see "بانتظار القبول من مالك المجموعة" until the Owner or a Supervisor decides.
4. **Given** at least one eligible auto-accept group, **When** the user taps "انضم لأي مجموعة ناقصة", **Then** they are placed in the best matching group in one step.
5. **Given** a valid invite link or code, **When** the user opens it, **Then** they see the group's public profile and can join (subject to the group's join mode and free seats).
6. **Given** an active group, **When** a new member takes an empty seat, **Then** they get that seat's juz for today immediately.
7. **Given** a group with no empty seat, **When** a user tries to join, **Then** joining is blocked with a clear "group full" explanation.

---

### User Story 5 - Volunteer for an Available Juz (Priority: P2)

A member sees juz whose seats are empty today and volunteers to read one or more of them so the group completes the full khatma.

**Why this priority**: The real group runs with empty seats; volunteering lets the daily khatma still complete.

**Independent Test**: In a group with 2 empty seats, volunteer for one available juz, verify it becomes assigned to the volunteer for today only, and verify another member cannot take it.

**Acceptance Scenarios**:

1. **Given** an available juz today, **When** a member taps "أتطوع بقراءته", **Then** the juz is assigned to them for today and shown as pending under their name.
2. **Given** two members volunteer for the same juz at the same time, **When** both requests arrive, **Then** exactly one succeeds and the other sees that it was taken.
3. **Given** a volunteered juz, **When** the next day starts, **Then** the volunteer assignment does not carry over.
4. **Given** an available juz nobody read, **When** the day closes, **Then** history records it as "لم يقرأه أحد", distinct from "فائت".

---

### User Story 6 - Manage Members and Requests (Priority: P2)

The Owner (and Supervisors) review join requests, arrange seats, remove members, override today's assignment for a seat, and appoint Supervisors.

**Why this priority**: The group needs basic management to stay healthy, but tracking works before it is used.

**Independent Test**: As Owner, approve one request, reject one, move a member to an empty seat, appoint a Supervisor, and reassign today's juz of one seat to another member.

**Acceptance Scenarios**:

1. **Given** pending requests and empty seats, **When** the Owner or a Supervisor approves a request, **Then** the user becomes an active member in an empty seat.
2. **Given** no empty seat, **When** they try to approve, **Then** approval is blocked with a "group full" explanation.
3. **Given** an active member, **When** the Owner removes them with confirmation, **Then** their seat becomes empty and every juz they had not yet completed today (seat, volunteered, or overridden) becomes available.
4. **Given** a member cannot read today, **When** the Owner reassigns that seat's juz for today to another member, **Then** the change applies to today only.
5. **Given** an active member, **When** the Owner appoints them Supervisor, **Then** they can review requests and arrange seats but cannot archive the group, transfer ownership, or appoint Supervisors.
6. **Given** the Owner wants to leave, **When** they try to leave, **Then** they must first transfer ownership to an active member or archive the group.
7. **Given** a private group, **When** the Owner regenerates the invite link, **Then** the old link stops working.

---

### User Story 7 - Review Daily Group History (Priority: P3)

Members review previous days; the Owner and Supervisors also see which seats missed so they can follow up.

**Why this priority**: History improves accountability but is not required for the daily loop.

**Independent Test**: Open a group with at least seven past days and verify summaries by day, and that Owner/Supervisor can see per-seat misses while regular members see only summaries and their own record.

**Acceptance Scenarios**:

1. **Given** several past days, **When** a member opens history, **Then** each day shows completed, late, missed, and unread counts and the completion percentage, and full-khatma days are marked.
2. **Given** a past day with misses, **When** the Owner or a Supervisor opens it, **Then** the app shows which juz, seats, and members missed.
3. **Given** a regular member, **When** they open a past day, **Then** they see the summary and their own result, not other members' misses.

### Edge Cases

- The group day rolls over while a member is viewing the dashboard: the app switches to the new day and yesterday remains open for late completion until it closes.
- A member leaves or is removed during the day: every juz they had not yet completed today (seat, volunteered, or overridden) becomes available for the rest of that day.
- A member joins mid-day: they receive their seat's juz for today immediately.
- All 30 juz completed before the day ends: the dashboard shows the day as a full khatma while members can still review their juz.
- Completion submitted after the day ends but before it closes: recorded as late; after close it is rejected with an explanation.
- Member offline: their juz and their own completion state remain available; shared progress is labeled as possibly outdated.
- Two volunteers for the same juz: exactly one wins.
- The Owner changes the group timezone: the change applies from the next group day and never rewrites past days.
- The Owner deletes their account or is removed by an administrator: ownership must be transferred by an administrator before the group can continue being managed (members keep reading).
- An invite link for an archived or full group: the app explains why joining is not possible.
- A group with only the Owner: still runs; 29 juz are available daily.
- A removed member opens the invite link again: their join becomes a pending request.

## Requirements *(mandatory)*

### Functional Requirements

**Groups and seats**

- **FR-001**: Any signed-in user MUST be able to create a group with name (3-60 characters), short description (up to 200 characters), timezone, daily start time, visibility (public/private), and join mode (auto-accept/approval). Names and descriptions are trimmed; names need not be unique.
- **FR-002**: A user MUST NOT own more than 3 non-archived groups.
- **FR-003**: Each group MUST have exactly 30 seats numbered 1-30; each active member occupies exactly one seat; seats may be empty.
- **FR-004**: The group creator MUST become Owner and occupy seat 1.
- **FR-005**: Groups MUST have a lifecycle of forming, active, and archived; archived groups accept no joins and generate no new days.
- **FR-006**: The Owner MUST be able to start the khatma at any time with at least one member, choosing the starting juz for seat 1 (default juz 1).
- **FR-007**: The Owner or a Supervisor MUST be able to move members between seats; in an active group a seat move takes effect from the next group day.

**Daily rotation**

- **FR-008**: On the start day, seat k MUST be assigned juz ((s + k − 2) mod 30) + 1, where s is the starting juz of seat 1.
- **FR-009**: Each new group day, every seat MUST advance by exactly one juz, with juz 30 followed by juz 1, regardless of whether the previous day was completed.
- **FR-010**: Each group day MUST be created automatically at the group's day rollover (timezone + daily start time) without Owner action.
- **FR-011**: Each group day MUST contain all 30 juz exactly once; occupied seats produce member assignments and empty seats produce available juz.
- **FR-012**: The Owner MUST be able to assign any juz of the current day (occupied seat or available) to an active member; the override applies to that day only.
- **FR-013**: The app MUST indicate that juz 30 is read with دعاء الختم.

**Completion**

- **FR-014**: Members MUST be able to mark their own assignment (seat or volunteered) complete for the current day.
- **FR-015**: Members MUST be able to undo a completion through a confirmation step until the day closes.
- **FR-016**: Completion after the day ends and before the end of the following group day MUST be recorded as late; after that the day MUST be closed and further changes rejected. Online completions are timed by the server clock; a completion recorded offline is timed by the device time at which it was recorded, never earlier than the day's start nor later than its arrival at the server.
- **FR-017**: Duplicate completion actions MUST NOT create duplicate results.
- **FR-017a**: A day MUST be marked as a full khatma when all 30 juz are completed or late; the late count remains visible separately.
- **FR-018**: Statuses MUST include: completed (تمت القراءة), pending (لم يُقرأ بعد), missed (فائت), late (قُرئ متأخرًا), available (متاح, current day, empty seat), and unread (لم يقرأه أحد, closed day, empty seat nobody volunteered for).

**Volunteering**

- **FR-019**: Any active member MUST be able to volunteer for any available juz of the current day, for that day only, with no limit on the number of juz.
- **FR-020**: Only the first volunteer for a juz MUST succeed; others MUST be told it was taken.

**Joining and roles**

- **FR-021**: Public groups MUST appear in discovery listing name, short description, "N / 30", timezone, and forming/active status, sorted with groups having the fewest empty seats first; member lists and progress MUST remain hidden from non-members.
- **FR-022**: Private groups MUST NOT appear in discovery and MUST be joinable only through invite link or code.
- **FR-023**: Each group MUST have an invite link and code that the Owner can regenerate, invalidating the previous one.
- **FR-024**: In auto-accept groups a joining user MUST become active immediately in an empty seat; in approval groups a join request MUST stay pending, shown as "بانتظار القبول من مالك المجموعة", until approved or rejected.
- **FR-025**: "انضم لأي مجموعة ناقصة" MUST place the user in a public, auto-accept, non-archived group with an empty seat, preferring the user's device timezone and then the fewest empty seats; if none exists the app MUST explain and offer discovery or group creation.
- **FR-026**: Joining or approval MUST be blocked when the group has no empty seat.
- **FR-027**: A member joining an active group MUST receive that seat's juz for the current day immediately.
- **FR-028**: A member MUST be able to leave a group; their seat becomes empty. The Owner MUST transfer ownership or archive the group before leaving.
- **FR-028a**: A user removed from a group MUST only be able to rejoin it through Owner/Supervisor approval; their join attempts (discovery, matching, or invite) become pending requests even in auto-accept groups.
- **FR-029**: The Owner MUST be able to appoint and remove Supervisors; Supervisors MUST be able to review join requests and arrange seats only.
- **FR-030**: The Owner MUST be able to remove members (with confirmation), edit group settings, regenerate invites, archive the group, and transfer ownership.
- **FR-031**: Only the Owner and Supervisors MUST be able to perform management actions; this MUST be enforced by the server, not only hidden in the UI.

**History, offline, presentation**

- **FR-032**: Daily history MUST be preserved; all active members see daily summaries and their own results; Owner and Supervisors also see per-seat and per-member results.
- **FR-033**: Today's assignment and the user's own completion state MUST be available without internet after the group has been opened on the device, and personal completion MUST be recordable offline and synced later.
- **FR-034**: The app MUST clearly indicate when shared progress may be outdated because the user is offline.
- **FR-035**: Juz labels and reading ranges MUST come from verified Quran metadata (constitution Principle VII).
- **FR-036**: The member's assignment MUST offer an "اقرأ الآن" entry point reserved for the Mushaf feature (spec 003); it is hidden until that feature ships.
- **FR-037**: All user-facing copy MUST be Arabic, right-to-left, and follow the design system (constitution Principle VI).
- **FR-038**: The app MUST allow users to adjust the text size of Quran labels and ranges.
- **FR-039**: The app MUST NOT implement push notification registration, delivery, reminders, or notification settings in this feature.
- **FR-040**: A user MUST be able to belong to multiple groups and switch the selected group.

### UI Surface Requirements

- **UI-001**: Screens: group selection (my groups + entry points), discovery, invite join, create group, group dashboard, personal assignment, seat arrangement / member management, join requests, group settings, daily history, and app settings (text size, sign-out). Authentication screens are delivered by spec 002.
- **UI-002**: The dashboard MUST show the user's juz with its primary action, completion count, percentage, and all 30 juz statuses (including available) without navigating away.
- **UI-003**: The personal assignment view MUST show juz label, reading range, status, primary completion action, undo with confirmation, and the reserved "اقرأ الآن" entry point.
- **UI-004**: Available juz MUST show "متاح" with the "أتطوع بقراءته" action.
- **UI-005**: A forming group MUST show "N / 30", "ناقص X", the invite link/code, and (for the Owner) the "ابدأ الختمة" action.
- **UI-006**: Group selection for a user with no groups MUST offer: groups that need members, "انضم لأي مجموعة ناقصة", "أنشئ مجموعة", and "عندي رابط دعوة".
- **UI-007**: History MUST separate today from past days and make missed, late, and unread juz easy to identify.
- **UI-008**: Every screen MUST define loading, content, empty, error, and offline states per constitution Principle VI.
- **UI-009**: No notification prompts, reminder controls, contact import, chat, or Quran text are shown in this feature.

### Key Entities *(include if feature involves data)*

- **User**: A signed-in person (identity and profile from spec 002).
- **Group**: A named reading circle with timezone, daily start time, visibility, join mode, lifecycle status, starting juz, start date, and invite link/code.
- **Seat**: One of 30 numbered positions in a group, occupied by at most one active member.
- **Group Membership**: A user's relationship to a group: role (owner, supervisor, member), status (active, left, removed), and seat.
- **Join Request**: A user's request to join an approval group: pending, approved, rejected, or cancelled.
- **Invite**: The current invite link/code of a group; regenerating it invalidates the previous one.
- **Quran Part (Juz)**: One of 30 juz with label and reading range from verified metadata.
- **Group Day**: One day of a group's khatma, identified by the group-local date, with status open, closed, and a full-khatma flag.
- **Assignment**: One juz in one group day, linked to a seat; holds the reading member (seat occupant, override, or volunteer), the kind (seat, override, volunteer, unassigned), status, and completion time.
- **Completion Record**: The history of completion actions on an assignment (completed, undone, late), including whether it came from offline sync.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new user can create a group and share its invite in under 2 minutes in usability testing.
- **SC-002**: An Owner can start the khatma in under 30 seconds once members have joined.
- **SC-003**: At least 90% of members identify their juz within 10 seconds of opening the dashboard.
- **SC-004**: At least 90% of members mark their juz complete in under 20 seconds after opening the app.
- **SC-005**: In 100% of acceptance tests, every group day contains all 30 juz exactly once and each seat advances by exactly one juz per day with 30 wrapping to 1.
- **SC-006**: In 100% of concurrency tests, an available juz is taken by exactly one volunteer.
- **SC-007**: A new user can join a group (auto-accept, matching, or invite) in under 60 seconds.
- **SC-008**: At least 85% of participants can explain completed, pending, missed, late, available, and unread without help.
- **SC-009**: A member who opened today's assignment can view it and update their own completion offline in 100% of offline acceptance tests.
- **SC-010**: In 100% of permission tests, non-members cannot see member lists or progress, and members cannot perform Owner/Supervisor actions.
- **SC-011**: Arabic labels, empty states, and errors remain readable at default and 200% text size in light and dark themes on all screens.
- **SC-012**: A new group day is visible within 1 minute of the group's rollover to any member opening the app online.

## Assumptions

- A "part" means one of the Quran's 30 juz.
- Authentication (email/password) and user profiles are provided by spec 002; this feature requires a signed-in user.
- The rotation continues every day even if some juz were not read; there is no pause in this feature.
- A user's own groups are capped at 3 owned groups; membership in other groups is not capped.
- The group timezone and daily start time are set by the Owner; changes apply from the next group day.
- Volunteering is for the current day only; it never changes seats.
- History is kept for the lifetime of the group.
- دعاء الختم text itself is displayed by the Mushaf feature (spec 003); this feature only indicates it on juz 30.
- The interface is Arabic-only; English is not part of the user experience.

## Out of Scope

- In-app Mushaf/Quran text (spec 003), audio, tafsir, translation.
- Push notifications, reminders, device tokens (separate feature).
- Chat, comments, reactions, direct messaging.
- Contact import.
- Pausing a group, multiple khatma plans per group, custom portions other than one juz per seat.
- Public ranking, donations, analytics dashboards.
- Combined multi-group dashboard (one selected group at a time).
