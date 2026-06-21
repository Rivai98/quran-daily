# Feature Specification: Quran Group Reading Tracker UI

**Feature Branch**: `001-track-quran-groups`

**Created**: 2026-06-20

**Status**: Draft

**Input**: User description: "design the app ui, the idea of the app to make group of people to manage together through read quran for everyone and assign 1 part of quran for everyone, the people in one group are 30 and assign to anyone in specific group have part to finish in day, the idea of the app to track the process"

## Clarifications

### Session 2026-06-21

- Q: Should v1 include an in-app Quran reader, or only show Quran part labels/ranges and track completion? → A: Show Quran part label/range only; no in-app reader in v1.
- Q: Which calendar day should determine the daily cycle cutoff and late completions? → A: Group-level timezone chosen by organizer.
- Q: How should members join a Quran group in v1? → A: Public group discovery with join request.
- Q: What should v1 do with push notifications? → A: No push notification work in v1; notifications are later.
- Q: What should public group discovery show before a user is approved to join? → A: Group name, short description, member count, and timezone only; show the Arabic pending status "بانتظار القبول من مالك المجموعة".

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Today's Group Reading Progress (Priority: P1)

A group member opens the app and immediately sees the group's daily Quran reading cycle: their assigned Quran part, the status of all 30 parts, and how close the group is to completing the full daily reading.

**Why this priority**: The core value is daily visibility. Without a clear group progress view, members cannot coordinate or know whether the group is on track.

**Independent Test**: Can be fully tested by opening an active 30-member group with published daily assignments and verifying that the member can identify their own part, the number of completed parts, the number remaining, and the current daily completion percentage.

**Acceptance Scenarios**:

1. **Given** a group has 30 assigned Quran parts for today, **When** a member opens the group dashboard, **Then** the app shows today's overall progress, all 30 part statuses, and the member's assigned part.
2. **Given** 12 members have marked their parts complete, **When** any member views the dashboard, **Then** the app shows 12 of 30 parts complete and visually separates complete, pending, and missed statuses.
3. **Given** a member has not completed today's part, **When** they view the dashboard, **Then** their assigned part is highlighted with a clear action to open or mark progress.

---

### User Story 2 - Assign One Quran Part to Each Group Member (Priority: P2)

A group organizer creates or manages a 30-person group and publishes a daily assignment where each active member receives exactly one Quran part to finish that day.

**Why this priority**: Assignment is required before progress can be tracked. The organizer must be able to prepare a complete daily reading cycle without confusion or duplicate assignments.

**Independent Test**: Can be tested by creating a group with 30 active members, generating today's assignments, confirming each member has one unique Quran part, and publishing the daily cycle.

**Acceptance Scenarios**:

1. **Given** a group has 30 active members, **When** the organizer creates today's reading cycle, **Then** the app assigns all 30 Quran parts with no duplicates and no unassigned active member.
2. **Given** the organizer reviews the proposed assignments, **When** they swap two members' parts before publishing, **Then** the app preserves one unique part per member and displays the updated assignment list.
3. **Given** the group has fewer than 30 active members, **When** the organizer attempts to publish a daily cycle, **Then** the app blocks publishing and explains that 30 active members are required for one part per person.

---

### User Story 3 - Mark Personal Reading Completion (Priority: P3)

A member reads their assigned Quran part for the day and marks it as complete so the group can see progress update.

**Why this priority**: Tracking depends on members reporting completion. The action must be fast, obvious, and reversible only in controlled cases to prevent accidental status changes.

**Independent Test**: Can be tested by signing in as a member with an assigned part, marking it complete, and verifying that the personal status and group completion count update.

**Acceptance Scenarios**:

1. **Given** a member has a pending part for today, **When** they mark the part complete, **Then** the app records the part as complete for that member and updates the daily group count.
2. **Given** a member has already marked today's part complete, **When** they view their assignment, **Then** the app shows the completed state and prevents accidental duplicate completion.
3. **Given** a member marked completion by mistake, **When** they undo the action within the allowed confirmation flow, **Then** the app returns the part to pending and updates the group count.

---

### User Story 4 - Review Daily Group History (Priority: P4)

A group organizer reviews previous daily cycles to understand consistency, identify missed parts, and follow up with members when the group did not complete the full Quran reading.

**Why this priority**: History is not required for the first daily tracking loop, but it helps the group improve accountability over time.

**Independent Test**: Can be tested by opening a group with at least seven past daily cycles and verifying that the organizer can see completion outcomes by day and identify missed assignments.

**Acceptance Scenarios**:

1. **Given** a group has completed several daily cycles, **When** the organizer opens history, **Then** the app shows each day with total completed parts, missed parts, and completion percentage.
2. **Given** a previous day had missed parts, **When** the organizer views that day, **Then** the app identifies which parts and members were missed.

### Edge Cases

- A group cannot publish a daily one-part-per-member cycle until it has exactly 30 active member slots.
- If a member leaves or becomes inactive after assignments are published, the organizer can reassign that member's part before the daily cycle ends.
- If the day changes according to the group's timezone while a member is viewing the app, the app clearly switches to the new daily cycle and preserves access to the previous day in history.
- If a member is offline, the app still shows their last available assignment and personal completion state, with a clear indication that shared group progress may not be current.
- If all 30 parts are completed before the day ends, the group dashboard shows the day as complete while still allowing members to review their assigned parts.
- If a completion is submitted after the day ends, the app records it as late and keeps the original daily result distinguishable from on-time completion.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST allow users to create and join named Quran reading groups.
- **FR-002**: Each group MUST support exactly 30 active member slots for the daily one-Quran-part-per-member model.
- **FR-003**: The app MUST distinguish between organizer actions and member actions, so only organizers can publish or change group-wide assignments.
- **FR-004**: Organizers MUST be able to create a daily reading cycle for a specific group.
- **FR-005**: Each daily reading cycle MUST include all 30 Quran parts, with each active member assigned exactly one unique part.
- **FR-006**: Organizers MUST be able to review and adjust assignments before publishing the daily cycle.
- **FR-007**: Members MUST be able to see their assigned Quran part for the current day from the primary group view.
- **FR-008**: Members MUST be able to mark their assigned part as complete for the current day.
- **FR-009**: The app MUST show group progress as completed parts out of 30 and as a percentage for the current daily cycle.
- **FR-010**: The app MUST show each assignment with member identity, Quran part number, and status.
- **FR-011**: Assignment statuses MUST include at minimum pending, completed, missed, and late completion.
- **FR-012**: The app MUST prevent duplicate assignment of the same Quran part within one daily cycle.
- **FR-013**: The app MUST prevent one active member from receiving more than one Quran part in the same daily cycle for v1.
- **FR-014**: Organizers MUST be able to reassign a pending or missed part when a member cannot complete it.
- **FR-015**: The app MUST preserve daily history showing completion results for previous cycles.
- **FR-016**: The app MUST make today's assignment and the user's own completion state available without an internet connection after the group has been opened on the device.
- **FR-017**: The app MUST clearly indicate when shared group progress may be outdated because the user is offline.
- **FR-018**: The app MUST support Arabic Quran labels and right-to-left reading presentation where Quran content or Arabic labels are shown.
- **FR-019**: The app MUST provide readable mobile layouts for the group dashboard, assignment list, personal assignment view, organizer assignment review, and history view.
- **FR-020**: The app MUST allow users to adjust reading text size for Quran-related content.
- **FR-021**: The app MUST limit v1 Quran content display to Quran part labels and reading ranges; full in-app Quran reading text is outside v1.
- **FR-022**: Each group MUST use one organizer-selected timezone to determine the daily cycle date, day cutoff, missed status, and late completion status.
- **FR-023**: Organizers MUST be able to make a group publicly discoverable for users who want to request membership.
- **FR-024**: Users MUST be able to find public Quran groups and submit a request to join.
- **FR-025**: Organizers MUST be able to approve or reject join requests; approved users become active members only when the group has an available active member slot.
- **FR-026**: The app MUST NOT implement push notification registration, delivery, reminder scheduling, or notification settings in v1.
- **FR-027**: Public group discovery MUST show only group name, short description, member count, and group timezone before approval; member lists and reading progress MUST remain hidden from non-members.
- **FR-028**: The app MUST present all v1 user-facing interface copy in Arabic.

### UI Surface Requirements

- **UI-001**: The first app version MUST include an authentication entry screen, group selection screen, group dashboard, personal assignment detail, organizer assignment review, member management, daily history, and settings for text size and offline status.
- **UI-002**: The group dashboard MUST make the user's assigned part, daily completion count, completion percentage, and all 30 assignment statuses visible without requiring navigation to another screen.
- **UI-003**: The personal assignment view MUST provide the assigned part label, reading range, current completion status, primary completion action, and confirmation or undo flow.
- **UI-004**: The organizer assignment review MUST show every member and Quran part pairing before publishing, including duplicate or missing assignment warnings.
- **UI-005**: The history view MUST separate current-day tracking from previous daily cycles and make missed or late parts easy to identify.
- **UI-006**: Future feature entry points MUST be absent from the v1 UI unless they are fully supported by this feature's requirements.
- **UI-007**: The v1 UI MUST NOT include an in-app Quran reader or Quran text navigation; it only shows assigned part labels, reading ranges, status, and completion actions.
- **UI-008**: The v1 group selection and member management UI MUST support public group discovery, join requests, and organizer request review; it MUST NOT expose contact-import entry points.
- **UI-009**: The v1 UI MUST NOT include notification permission prompts, reminder controls, or push-notification settings.
- **UI-010**: After a user requests to join a public group, the UI MUST show the Arabic pending status "بانتظار القبول من مالك المجموعة" until an organizer approves or rejects the request.

### Key Entities *(include if feature involves data)*

- **User**: A person using the app. Key attributes include display name, membership status, and role within each group.
- **Group**: A named reading circle that contains up to 30 active member slots, has one organizer-selected timezone, and coordinates one collective daily Quran reading cycle.
- **Group Membership**: The relationship between a user and a group, including whether the user is active, inactive, organizer, or regular member.
- **Join Request**: A user's request to join a public group, including pending, approved, or rejected status.
- **Quran Part**: One of the 30 daily Quran reading parts assigned during a cycle. Key attributes include part number, display label, and reading range.
- **Daily Reading Cycle**: A group-specific day of coordinated reading where all 30 Quran parts are assigned and tracked.
- **Assignment**: A link between one active group member, one Quran part, and one daily reading cycle, including status and completion time.
- **Completion Record**: The recorded result of a member's assignment, including whether completion was on time, late, undone, or missed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new organizer can create a 30-member group and publish the first daily assignment in under 5 minutes during usability testing.
- **SC-002**: At least 90% of members can identify their assigned Quran part within 10 seconds of opening the group dashboard.
- **SC-003**: At least 90% of members can mark their assigned part complete in under 20 seconds after opening the app.
- **SC-004**: Organizers can confirm whether the group completed all 30 parts for the current day in under 15 seconds.
- **SC-005**: The group dashboard accurately shows completion counts for all 30 assignments in 100% of acceptance test cases.
- **SC-006**: In usability testing, at least 85% of participants can explain which parts are pending, completed, missed, and late without help.
- **SC-007**: A member who has previously opened today's assignment can view it and update personal completion state while offline in 100% of offline acceptance test cases.
- **SC-008**: Arabic Quran labels and right-to-left content remain readable at default and enlarged text sizes in 100% of visual acceptance test cases.

## Assumptions

- A "part" means one of the Quran's 30 juz divisions.
- v1 groups use exactly 30 active member slots so each member receives one Quran part per day.
- A user can belong to more than one group, but the primary experience focuses on one selected group at a time.
- One group has at least one organizer who can manage membership and assignments.
- Daily cycles follow the group's organizer-selected timezone, not each member's device timezone.
- The first version focuses on assignment, completion, progress, and history. Social chat, audio playback, and advanced reminders are outside this feature scope.
- Shared group progress may require connectivity to reflect other members' latest updates, but each member's own assignment and completion flow must remain usable offline after the relevant day has been opened.
- "Quran-related content" in v1 means part labels and reading ranges, not full Quran text.
- Push notifications, reminder delivery, and notification device registration are deferred until a later feature.
- The v1 app interface is Arabic-first; English copy is not part of the user-facing v1 experience.

## Out of Scope for v1

- Social chat, group comments, reactions, and direct messaging.
- In-app Quran reader, full Quran text navigation, bookmarks, and reading-position tracking.
- Audio playback, recitation playlists, tajweed lessons, and memorization plans.
- Push notifications, device token registration, reminder delivery, and notification settings.
- Advanced public directory ranking, subscriptions, donations, and admin analytics.
- Contact import and phone contacts invitation.
- Multi-group dashboards beyond selecting and opening one group at a time.
