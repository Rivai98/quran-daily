# Feature Specification: Reader Visibility, Member Profiles, and Group Info

**Feature Branch**: `007-reader-visibility-profiles`
**Created**: 2026-11-15
**Status**: Clarified (2026-11-15)
**Depends on**: spec 001 (groups, seats, rotation, history, volunteering - implemented), spec 002 (email/password auth & user accounts), spec 004 (portion units), spec 005 (Today home, tabs, cards, avatar styling)
**Input**: Owner request: "today it is not visible WHO read a portion and how. Members should see, for each portion on the dashboard and history, who read it (name, avatar), when (on time / late / volunteered / overridden), and open that member's profile." Added 2026-11-15: "Each group needs more
details and a group photo; tapping the group header (like WhatsApp) shows the
group info and who is inside it."

## Clarifications

### Session 2026-11-15

- Q: Where is reader information displayed? → A: On every juz/portion tile in the dashboard grid and every row in the group list and history. It shows the reader's avatar (initials) and display name. For completed portions, it displays the completion timestamp and whether it was read on time or late.
- Q: What happens when a user taps a portion tile or row? → A: Tapping opens a bottom sheet (`ConfirmSheet` / detail sheet) detailing: reader display name, avatar initials, portion status (completed / pending / missed / late / available / unread), completion time, reading kind (seat assignment, volunteer, or supervisor override), and a button/link to open the member's profile.
- Q: What information is included in a Member Profile? → A: Accessible only to members who share an active or historical group with that user. The profile displays: display name, avatar initials, role (مالك / مشرف / عضو) and seat number in this group, member since date, current reading streak in this group, overall completion rate (%) in this group, and recent days activity.
- Q: Are user profile photos supported? → A: No; user profile photos are explicitly out of scope for v1. Avatars use member name initials styled with Design System color tokens (Principle VI).
- Q: What can a user edit on their own profile ("ملفي الشخصي")? → A: A user can view their account overview, edit their display name (2–50 characters), and add/edit an optional short bio of up to 120 characters.
- Q: What are the privacy and access control boundaries? → A: Profiles are strictly visible only to co-members of shared groups. Non-members cannot view or search user profiles. A user's email address is NEVER displayed to other members, supervisors, or owners under any circumstance.
- Q: How does this interact with empty seats, volunteering, and overrides? → A: An empty seat with no reader shows the status "متاح" (available) and an action to volunteer (for today's active day); if volunteered, the tile updates to the volunteer's avatar and name tagged as "تطوع". An override displays the assigned reader tagged as "تعيين المشرف".

- Q: Can a group have a photo and richer details? → A: Yes. The owner can set
  a group photo (picked from the gallery or camera, cropped square, stored in
  app storage with group-member-only read access) and the group shows its
  description, unit/schedule, created date, member count and khatma count.
  Without a photo the group shows a generated avatar (initials over the
  geometric ornament).
- Q: How do members see who is in the group? → A: Like WhatsApp: tapping the
  group header on the dashboard opens a "Group info" screen with the photo,
  name, description, stats, invite link (owner/supervisor), and the member
  list (avatar, name, role, seat); tapping a member opens their profile.

- Q: Who can see that a member MISSED a portion? → A: Only the owner and
  supervisors. Regular members see who read (name, time, on time/late/
  volunteered) and see other members' unread/missed portions only as neutral
  "لم يُقرأ بعد" / "متاح" without naming the member. A member always sees
  their own status.
- Q: Does a late completion count toward the streak? → A: Yes (same rule as
  spec 005 FR-010): late keeps the streak, missed breaks it.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Reader Attribution on Dashboard and History (Priority: P1)

A group member views the group dashboard or past history and can clearly see which member is assigned to or read each portion, their avatar initials, their completion status, and how the portion was fulfilled.

**Why this priority**: Accountability, encouragement, and community awareness require knowing who read each part and when.

**Independent Test**: Open a group dashboard where 3 portions are completed (one by seat member, one volunteered, one late); verify that each tile displays the reader's name and initials, and completed items show timestamps and status tags.

**Acceptance Scenarios**:

1. **Given** an active group day, **When** a member views the dashboard grid or portion list, **Then** each portion displays the assigned or completing reader's avatar initials and display name.
2. **Given** a completed portion, **When** viewed on the dashboard, **Then** it shows the completion time formatted with Arabic-Indic numerals and indicates if it was completed on time or late ("قُرئ متأخرًا").
3. **Given** an empty seat's portion that has not been read, **When** viewed on the dashboard, **Then** it displays status "متاح" without a reader avatar, and provides a volunteer action.
4. **Given** past history days, **When** a member opens a day's details, **Then** every portion row shows who read it and whether it was completed on time, late, volunteered, or unread ("لم يقرأه أحد").

---

### User Story 2 - Open Portion Detail Sheet and Navigate to Member Profile (Priority: P1)

A member taps a portion tile or list row to open a detailed bottom sheet displaying the reader's information, completion details, and a link to view that member's profile within the group.

**Why this priority**: Tiles on mobile screens have limited space; the detail sheet gives full context without cluttering the primary dashboard.

**Independent Test**: Tap a completed portion tile; verify that a bottom sheet opens showing reader name, status chip, completion timestamp, kind ("ورد المقعد" / "تطوع" / "تعيين المشرف"), and a button "عرض الملف الشخصي" that opens the profile.

**Acceptance Scenarios**:

1. **Given** a portion tile on the dashboard, **When** a member taps it, **Then** a bottom sheet opens displaying the portion title, reader avatar and name, status chip, completion kind, and completion time.
2. **Given** the portion detail sheet, **When** the member taps "عرض الملف الشخصي", **Then** the member's group profile screen opens.
3. **Given** a vacant portion ("متاح"), **When** a member taps it, **Then** the sheet explains that the seat is vacant and presents the primary action "تطوع لقراءة هذا الورد" (spec 001 volunteering rule).

---

### User Story 3 - View Member Profile in Group Context (Priority: P2)

A member opens a co-member's profile to see their devotional participation in this group: their role, seat number, join date, current streak, completion rate, and recent days record.

**Why this priority**: Recognizes commitment and fosters healthy companionship in Quran completion without social media clutter.

**Independent Test**: Open member profile for a co-member with 10 days in the group and 9 completed portions; verify it shows role, seat number, 90% completion rate, current streak, and recent days list.

**Acceptance Scenarios**:

1. **Given** a co-member who shares an active group, **When** their profile is opened, **Then** the screen shows their display name, avatar initials, role ("مالك المجموعة" / "مشرف" / "عضو"), seat number ("المقعد ٧"), and member since date.
2. **Given** the member profile screen, **When** viewed, **Then** it shows the current active streak (e.g. "٥ أيام متتالية") and overall completion percentage in this group (e.g. "٩٠٪").
3. **Given** the member profile screen, **When** scrolling to "الأيام الأخيرة", **Then** the last 7 to 14 days of reading status in this group are displayed with status chips.
4. **Given** a user who does not share any group with the requested profile ID, **When** they attempt to access the profile, **Then** access is denied with a clear Arabic message.

---

### User Story 4 - View and Edit My Profile (Priority: P2)

A user opens their own profile from the app navigation or Settings to review their account details, change their display name, or add a short personal bio.

**Why this priority**: Users need autonomy over how they are identified by fellow group members.

**Independent Test**: Open "ملفي الشخصي", update display name from "أحمد" to "أحمد مصطفى" and add a 50-character bio; save and verify that the updated name appears immediately on group dashboards.

**Acceptance Scenarios**:

1. **Given** the user's own profile screen, **When** the user taps "تعديل الملف الشخصي", **Then** an edit sheet or screen opens with display name and short bio fields.
2. **Given** the display name input, **When** the user enters a valid name (2 to 50 characters) and saves, **Then** the updated name reflects across all active group screens and portion sheets.
3. **Given** the short bio input, **When** the user enters up to 120 characters and saves, **Then** the bio is saved and visible on the user's profile card to co-members.
4. **Given** an invalid display name (empty or whitespace only), **When** save is tapped, **Then** saving is prevented and an Arabic error explains the requirement.

---

### User Story 5 - Privacy Protection: No Email Exposure (Priority: P1)

The system ensures that user email addresses remain completely private and are never exposed to other members, supervisors, or group owners in any UI, sheet, or network payload.

**Why this priority**: Devotional group apps must protect personal contact privacy and prevent unsolicited contact or data harvesting.

**Independent Test**: Inspect all member lists, profile views, and network payloads; verify that email addresses are absent and only display names and stable IDs are exchanged.

**Acceptance Scenarios**:

1. **Given** any group member viewing another member's profile or sheet, **When** rendered, **Then** no email address is displayed.
2. **Given** group query responses from backend / local cache, **When** payload is inspected, **Then** the email field is omitted from all public/member-facing queries.
3. **Given** an owner or supervisor managing group members, **When** viewing seat assignments, **Then** members are identified solely by display name and seat number.

### User Story 6 - Group Info Screen (WhatsApp-style) (Priority: P1)

Tapping the group header (photo + name) on the dashboard opens "معلومات
المجموعة": large photo, name, description, daily portion unit, created date,
member count (e.g. "١٢ عضوًا من ٣٠"), completed khatmas count, invite link and
code (owner/supervisor), and the member list sorted by role then seat, each
row with avatar, name, role badge and seat. Members can leave from here; the
owner sees management shortcuts (members, join requests, settings).

**Why this priority**: Members need to know who they read with; it is the
most familiar pattern for the target users.

**Independent Test**: Open a 12-member group's dashboard, tap the header, see
12 member rows with avatars and roles; tap one to open the profile.

**Acceptance Scenarios**:

1. **Given** the dashboard, **When** the user taps the group header, **Then**
   the group info screen opens with photo/avatar, details and member list.
2. **Given** a member row, **When** tapped, **Then** that member's profile
   (User Story 3) opens.
3. **Given** a plain member, **When** viewing group info, **Then** no invite
   regeneration or management actions are shown.

---

### User Story 7 - Group Photo and Richer Group Card (Priority: P2)

The owner sets or changes the group photo from group settings or group info.
The photo appears on the group card in "مجموعاتي", the dashboard header, the
invite preview and the public discovery card (public groups only).

**Independent Test**: Owner uploads a photo; all four places show it; a
non-member opening a private group's invite preview sees no photo.

**Acceptance Scenarios**:

1. **Given** the owner, **When** they pick and crop a photo, **Then** it is
   uploaded (max 1 MB after compression) and shown everywhere within one
   refresh.
2. **Given** a failed upload (offline), **When** it fails, **Then** the old
   photo stays and a retry action is shown.
3. **Given** the owner removes the photo, **Then** the generated avatar shows.

---

### Edge Cases

- **Arabic Initials Generation**: If display name has multiple parts (e.g. "محمد عبد الله"), avatar initials take the first letter of the first word and first letter of the last significant word (e.g. "م ع"). If single word (e.g. "عمر"), it uses the first letter ("ع").
- **Member Leaves or is Removed**: When a member who completed portions leaves or is removed from the group, historical portion records preserve their display name at the time of completion. Tapping their profile shows their status as "عضو سابق".
- **Volunteer Portion Overlap**: If member A volunteers for vacant seat B, seat B's tile shows member A's avatar with a distinct "تطوع" badge; member A's own seat remains assigned to member A.
- **Offline Profile Access**: Cached member profiles (name, avatar, cached stats) are viewable offline with the `OfflineBanner`. Editing "My Profile" is disabled offline with a calm explanation.
- **Very Long Display Names**: Display names wrap cleanly or ellipsize gracefully on small (320dp) screens without causing horizontal layout overflow.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every portion tile on the group dashboard and every row in portion lists MUST display the assigned or completing reader's avatar initials and display name.
- **FR-002**: For completed portions, the system MUST display the completion timestamp (in Arabic-Indic numerals) and whether it was completed on time or late ("قُرئ متأخرًا").
- **FR-003**: Tapping any portion tile or list row MUST open a detail bottom sheet displaying:
  - Portion title and reading range (derived from metadata repository)
  - Reader display name and avatar initials
  - Portion status chip (completed, pending, late, missed, available, unread)
  - Completion kind: seat assignment ("ورد المقعد"), volunteer ("تطوع"), or supervisor override ("تعيين المشرف")
  - Completion timestamp (if completed)
  - A primary navigation action to view the member's profile (disabled for empty seats)
- **FR-004**: When a portion belongs to an empty seat and is unread, the tile and sheet MUST display status "متاح" (available) and provide an immediate action to volunteer (for today's active day).
- **FR-005**: The system MUST provide a Member Profile screen visible to co-members of shared groups displaying:
  - Display name and avatar initials
  - Role in this group (مالك المجموعة / مشرف / عضو)
  - Assigned seat number in this group (e.g. "المقعد ١٢")
  - Date joined ("عضو منذ ...")
  - Current reading streak in this group ("سلسلة القراءة الحالية")
  - Overall completion rate percentage in this group ("نسبة الإتمام")
  - Recent days history (last 7 to 14 days summary)
- **FR-006**: Member profiles MUST be accessible ONLY to authenticated users who share at least one active or historical group with that user; arbitrary public profile lookups MUST be blocked.
- **FR-007**: User email addresses MUST NEVER be displayed or exposed to any member, supervisor, or owner in any UI view, sheet, dialog, or member-facing query payload.
- **FR-008**: User profile photos and image uploads MUST NOT be supported in v1; all avatars MUST be generated programmatically from initials using Design System color tokens (Principle VI).
- **FR-009**: The system MUST allow users to view and edit their own profile ("ملفي الشخصي"), including display name (2–50 characters) and an optional short bio (up to 120 characters).
- **FR-010**: Group history day detail views MUST display the reader avatar, name, and completion kind for each past portion.
- **FR-011**: All numbers in profiles, stats, and timestamps MUST use Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩) and follow RTL layout rules (Principle II).
- **FR-012**: Reader attribution and cached member profiles MUST work offline from local storage, accompanied by the `OfflineBanner` when data may be stale (Principle I).
- **FR-013**: Tapping the group header on the dashboard MUST open the Group
  Info screen with photo/avatar, name, description, unit, created date, member
  count, completed khatma count and the member list (avatar, name, role, seat).
- **FR-014**: The owner MUST be able to set, change and remove a group photo;
  photos are compressed to at most 1 MB, square-cropped, and readable only by
  group members (and by anyone for public groups' discovery cards).
- **FR-015**: Groups without a photo MUST show a generated avatar (initials
  on the geometric ornament) consistently in all places.
- **FR-016**: Photo upload failures MUST keep the previous photo and offer retry.

### Key Entities

- **PortionReaderAttribution**: Read model capturing reader context for a portion:
  - `portionIndex`: integer (1..30 or 1..N per spec 004)
  - `readerId`: stable user UUID (nullable for empty seat)
  - `displayName`: string
  - `avatarInitials`: string (1-2 Arabic characters)
  - `status`: enum (`completed`, `pending`, `missed`, `late`, `available`, `unread`)
  - `completionKind`: enum (`seat_holder`, `volunteer`, `supervisor_override`, `none`)
  - `completedAt`: timestamp (nullable)
  - `isLate`: boolean
- **MemberGroupProfile**: Aggregated profile entity within group context:
  - `userId`: stable UUID
  - `groupId`: stable UUID
  - `displayName`: string
  - `bio`: string (nullable, max 120 characters)
  - `role`: enum (`owner`, `supervisor`, `member`, `former_member`)
  - `seatNumber`: integer (nullable if unassigned)
  - `joinedAt`: timestamp
  - `currentStreak`: integer (days)
  - `completionRate`: double (percentage 0..100)
  - `recentDays`: list of recent day statuses (date, status, completionKind)
- **UserProfile**: User account profile entity:
  - `id`: stable UUID
  - `displayName`: string
  - `bio`: string (nullable, max 120 characters)
  - `updatedAt`: timestamp

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Any group member can identify who read any portion on today's dashboard within 1 tap and under 2 seconds.
- **SC-002**: Tapping a portion tile opens the reader detail sheet in under 200 milliseconds from local cache.
- **SC-003**: 100% of tested API responses and UI screens confirm 0 exposure of user email addresses to other users.
- **SC-004**: 100% of unauthorized profile access attempts between non-shared group users are blocked.
- **SC-005**: Updating display name or bio updates co-member screens on the next refresh or within 2 seconds under active connection.
- **SC-006**: All profile and attribution screens render without horizontal overflow at 320dp width and support 200% text scale.
- **SC-007**: Users reach the list of group members in one tap from the dashboard.
- **SC-008**: A group photo set by the owner appears on card, header, preview and discovery within one refresh.

## Assumptions

- Backend database views or Edge Functions compute streak and completion rate within group scope while respecting Row-Level Security (RLS) so non-members cannot read profiles.
- Display name and initials are stored or computed on profile read; no third-party avatar services (e.g. Gravatar) or image hosting are used.
- Bio text is plain Modern Standard Arabic text up to 120 characters; no rich text or external links.
- Email addresses remain strictly confined to private authentication tables (`auth.users`) and are never mirrored into shared profile views.
