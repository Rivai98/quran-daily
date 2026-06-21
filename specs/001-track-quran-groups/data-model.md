# Data Model: Quran Group Reading Tracker UI

## Entity Overview

```text
AppUser 1--* GroupMembership *--1 Group
AppUser 1--* JoinRequest *--1 Group
Group 1--* DailyReadingCycle
DailyReadingCycle 1--30 Assignment
QuranPart 1--* Assignment
Assignment 0--* CompletionRecord
AppUser 1--* LocalSyncOperation
Group 1--1 PublicGroupProfile
```

## AppUser

Represents a signed-in person using the app.

**Fields**
- `id`: stable Supabase Auth user id.
- `display_name`: user-facing Arabic display name when available.
- `avatar_url`: optional Google profile image URL.
- `created_at`: account creation timestamp.
- `last_seen_at`: last app activity timestamp.

**Validation Rules**
- `id` is unique and comes from Supabase Auth.
- `display_name` must be non-empty after sign-in.

## Group

Represents a named Quran reading circle.

**Fields**
- `id`: group id.
- `name`: group display name.
- `short_description`: short public description.
- `created_by_user_id`: organizer who created the group.
- `created_at`: creation timestamp.
- `local_day_timezone`: organizer-selected timezone used to resolve daily cycles.
- `is_public`: whether the group appears in public discovery.
- `status`: `active` or `archived`.

**Validation Rules**
- `name` must be non-empty.
- `short_description` must be safe to display publicly when `is_public` is true.
- Active v1 groups must publish cycles only when exactly 30 active memberships exist.
- Archived groups cannot publish new cycles or accept join requests.

## PublicGroupProfile

Read model shown to users before they are approved to join a group.

**Fields**
- `group_id`: linked group.
- `name`: public group name.
- `short_description`: public short description.
- `active_member_count`: current active member count.
- `local_day_timezone`: group timezone.
- `current_user_request_status`: optional `none`, `pending`, `approved`, or `rejected`.

**Validation Rules**
- Must not include member list, assignment details, dashboard progress, history, or organizer-only data.
- If a user has a pending request, the UI shows `بانتظار القبول من مالك المجموعة`.

## JoinRequest

Represents a user's request to join a public group.

**Fields**
- `id`: join request id.
- `group_id`: requested group.
- `user_id`: requesting user.
- `status`: `pending`, `approved`, `rejected`, or `cancelled`.
- `requested_at`: request creation timestamp.
- `reviewed_by_user_id`: organizer who reviewed the request.
- `reviewed_at`: optional review timestamp.
- `decision_note`: optional organizer-facing note.

**Validation Rules**
- A user can have at most one pending join request for the same group.
- Users cannot request to join archived or non-public groups through discovery.
- Only active organizers of the group can approve or reject requests.
- Approval can create an active membership only if the group has fewer than 30 active members.
- Rejected and cancelled requests do not create memberships.

## GroupMembership

Represents a user's role and active slot within a group.

**Fields**
- `id`: membership id.
- `group_id`: linked group.
- `user_id`: linked user.
- `role`: `organizer` or `member`.
- `status`: `active`, `inactive`, or `removed`.
- `slot_number`: optional 1-30 active slot position.
- `joined_at`: join timestamp.
- `left_at`: optional leave/removal timestamp.

**Validation Rules**
- One user can have at most one active membership in the same group.
- A group can have at most 30 active memberships.
- At least one active organizer must remain in an active group.
- Only active memberships receive daily assignments.

## QuranPart

Represents one Quran juz division.

**Fields**
- `part_number`: integer 1-30.
- `display_label`: Arabic label for the part.
- `reading_range_label`: Arabic reading range label.
- `sort_order`: 1-30.

**Validation Rules**
- Exactly 30 parts exist.
- `part_number` is unique and between 1 and 30.
- v1 stores labels and reading ranges only, not full Quran text.
- Labels must support Arabic display and RTL presentation.

## DailyReadingCycle

Represents one group-specific day of coordinated reading.

**Fields**
- `id`: cycle id.
- `group_id`: linked group.
- `cycle_date`: local date resolved by the group's timezone.
- `status`: `draft`, `published`, `complete`, or `closed`.
- `published_by_user_id`: organizer who published the cycle.
- `published_at`: optional publish timestamp.
- `closed_at`: optional close timestamp.
- `completion_percentage`: derived from assignment statuses.

**Validation Rules**
- One cycle per group per local date.
- A cycle cannot publish unless it has 30 assignments.
- Published cycles must have exactly one assignment per active member and exactly one assignment per Quran part.
- Day cutoff, missed status, and late completion status use the group's timezone.

## Assignment

Links one active group member to one Quran part for one daily reading cycle.

**Fields**
- `id`: assignment id.
- `cycle_id`: linked daily cycle.
- `membership_id`: assigned active member.
- `part_number`: linked Quran part.
- `status`: `pending`, `completed`, `missed`, or `late`.
- `assigned_at`: assignment timestamp.
- `completed_at`: optional completion timestamp.
- `updated_at`: last status change timestamp.
- `reassigned_from_membership_id`: optional prior membership when reassigned.

**Validation Rules**
- Within a cycle, each `part_number` appears exactly once.
- Within a cycle, each active `membership_id` appears exactly once.
- Members can complete only their own current assignment.
- Organizers can reassign pending or missed assignments before the cycle is closed.
- Late completion is recorded separately from on-time completion when submitted after the group day cutoff.

## CompletionRecord

Records the history of completion actions and reversals.

**Fields**
- `id`: completion record id.
- `assignment_id`: linked assignment.
- `user_id`: user who performed the action.
- `action`: `completed`, `undone`, or `marked_late`.
- `recorded_at`: action timestamp.
- `source`: `online` or `offline_sync`.

**Validation Rules**
- Duplicate completion actions must not create duplicate completed states.
- Undo is allowed only through the confirmation flow while the cycle is not closed.
- Offline completions must retain their original local action timestamp and sync timestamp.

## UserSettings

Represents local app preferences.

**Fields**
- `selected_group_id`: last opened group.
- `quran_text_scale`: user-selected Quran label/range text size.
- `preferred_locale`: Arabic locale setting for v1.
- `last_dashboard_cache_at`: timestamp of last cached dashboard snapshot.

**Validation Rules**
- `quran_text_scale` must stay within the supported readability range.
- Selected group must be one of the user's approved memberships when online validation is available.

## LocalSyncOperation

Represents a queued offline operation waiting to sync.

**Fields**
- `id`: local operation id.
- `operation_type`: `mark_complete` or `undo_completion` for v1.
- `assignment_id`: affected assignment.
- `payload`: serialized operation details.
- `created_at`: local creation timestamp.
- `sync_status`: `pending`, `syncing`, `synced`, or `failed`.
- `last_error`: optional sync failure message.

**Validation Rules**
- v1 queues only personal assignment completion operations.
- Public discovery, join requests, organizer approvals, publishing, reassignment, and membership changes require online confirmation.
- Failed operations remain visible to the repository layer so Cubits can show retry/error states.

## State Transitions

### JoinRequest

```text
none -> pending
pending -> approved
pending -> rejected
pending -> cancelled
rejected -> pending   # if product allows a later retry
```

- `pending`: show `بانتظار القبول من مالك المجموعة`.
- `approved`: creates or links an active membership if a slot is available.
- `rejected`: user is not a group member.
- `cancelled`: requester withdrew before organizer review.

### DailyReadingCycle

```text
draft -> published -> complete -> closed
draft -> published -> closed
```

- `draft`: organizer can review and change assignments.
- `published`: members can view and complete assignments.
- `complete`: all 30 parts are complete before close.
- `closed`: daily result is final; late completions remain distinguishable.

### Assignment

```text
pending -> completed
pending -> missed
missed -> late
completed -> pending   # undo only before cycle close
pending -> pending     # reassignment changes member, not status
missed -> pending      # organizer reassignment before close
```

## Derived Views

## GroupDashboardSnapshot

Read model used by the dashboard Cubit and local cache.

**Contains**
- Group summary.
- Current daily cycle summary.
- Current user's assignment.
- All 30 assignment rows.
- Counts by status.
- Completion percentage.
- Offline/stale indicator.
- Last synced timestamp.

## HistoryDaySummary

Read model used by the history view.

**Contains**
- Cycle date.
- Completed count.
- Missed count.
- Late count.
- Completion percentage.
- Final daily result status.
