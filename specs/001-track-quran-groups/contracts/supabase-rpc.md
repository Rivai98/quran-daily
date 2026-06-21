# Contract: Supabase Database and Backend Functions

These contracts describe the backend operations the Flutter app depends on. Exact SQL and migration code are implementation tasks, but the function behavior, validation, and returned shapes are fixed by this plan.

## Shared Rules

- All functions require an authenticated Supabase user unless explicitly noted.
- Row-level security must prevent users from reading private group data where they are not approved members.
- Migrations must create concrete RLS policies for public discovery, approved-member reads, organizer-only writes, and non-member rejection; placeholders are not sufficient.
- Public discovery returns only group name, short description, active member count, group timezone, and the current user's request status.
- Organizer-only mutations must verify active organizer membership inside the database operation.
- Critical write operations must be atomic and must not rely on client-only validation.
- Returned timestamps are UTC; the app converts display dates using the group's timezone.
- Assignment status values are `pending`, `completed`, `missed`, and `late`.
- v1 has no push notification registration, device token storage, or notification delivery functions.

## Function: `create_group`

Creates a group and makes the current user an active organizer.

**Input**
- `name`: non-empty Arabic group name.
- `short_description`: public short description.
- `local_day_timezone`: timezone string.
- `is_public`: whether users can discover and request to join the group.

**Output**
- `group_id`
- `membership_id`
- `role`: `organizer`

**Errors**
- `invalid_group_name`
- `invalid_description`
- `invalid_timezone`
- `unauthenticated`

## Function: `search_public_groups`

Returns minimal public group profiles for discovery.

**Input**
- `query`: optional text query.
- `limit`
- `offset`

**Output**
- Array of `{ group_id, name, short_description, active_member_count, local_day_timezone, current_user_request_status }`

**Validation**
- Only active public groups are returned.
- Member lists, assignment rows, reading progress, and history are never returned to non-members.

## Function: `submit_join_request`

Creates a pending request for the current user to join a public group.

**Input**
- `group_id`

**Output**
- `join_request_id`
- `status`: `pending`
- `pending_message_key`: `waiting_for_group_owner_approval`

**Validation**
- Group must be active and public.
- User must not already be an active member.
- User must not already have a pending request for the same group.

**Errors**
- `group_not_public`
- `already_active_member`
- `join_request_already_pending`
- `group_archived`

## Function: `review_join_request`

Approves or rejects a pending join request.

**Input**
- `join_request_id`
- `decision`: `approve` or `reject`
- Optional `decision_note`

**Output**
- `join_request_id`
- `status`: `approved` or `rejected`
- Optional `membership_id` when approved.
- Updated `active_member_count`.

**Validation**
- Caller must be active organizer of the target group.
- Join request must be pending.
- Approval requires fewer than 30 active members.
- Rejection must not create a membership.

**Errors**
- `not_organizer`
- `join_request_not_pending`
- `group_full`
- `group_archived`

## Function: `get_user_groups`

Returns groups where the current user is an approved member.

**Input**
- None.

**Output**
- Array of approved group summaries with user role and active status.

## Function: `publish_daily_cycle`

Publishes a daily cycle with exactly 30 unique Quran part assignments.

**Input**
- `group_id`
- `cycle_date`
- `assignments`: array of `{ membership_id, part_number }`

**Output**
- `cycle_id`
- `status`: `published`
- `assignment_count`: `30`

**Validation**
- Caller must be active organizer.
- Group must have exactly 30 active memberships.
- Each active membership appears exactly once.
- Each Quran part number 1-30 appears exactly once.
- Cycle date is resolved using the group's timezone.
- Cycle date must not already have a published cycle for the group.

**Errors**
- `not_organizer`
- `group_requires_30_active_members`
- `duplicate_part`
- `duplicate_member`
- `missing_active_member`
- `cycle_already_exists`

## Function: `swap_assignment_parts`

Swaps Quran parts between two assignments before or after publishing when allowed by organizer rules.

**Input**
- `cycle_id`
- `assignment_id_a`
- `assignment_id_b`

**Output**
- Updated assignment summaries for both assignments.

**Validation**
- Caller must be active organizer.
- Cycle must not be closed.
- Swap must preserve one part per assignment and one assignment per member.

## Function: `reassign_assignment`

Moves a pending or missed assignment to another active member before cycle close.

**Input**
- `assignment_id`
- `new_membership_id`

**Output**
- Updated assignment summary.

**Validation**
- Caller must be active organizer.
- Assignment status must be `pending` or `missed`.
- New membership must be active in the same group.
- Reassignment must not give a member more than one assignment in the cycle.

## Function: `mark_assignment_complete`

Marks the current user's assignment complete.

**Input**
- `assignment_id`
- `client_recorded_at`

**Output**
- `assignment_id`
- `status`: `completed` or `late`
- `completed_at`
- Updated dashboard counts.

**Validation**
- Caller must own the assignment through active membership.
- Cycle must be published and not closed.
- Duplicate completion calls must be idempotent.
- Completion after the group day cutoff is recorded as `late`.

**Errors**
- `not_assignment_owner`
- `cycle_closed`
- `assignment_not_found`

## Function: `undo_assignment_completion`

Returns a completed assignment to pending when the confirmation flow allows undo.

**Input**
- `assignment_id`

**Output**
- `assignment_id`
- `status`: `pending`
- Updated dashboard counts.

**Validation**
- Caller must own the assignment.
- Cycle must not be closed.
- Undo must create a completion record with action `undone`.

## Function: `get_group_dashboard`

Returns the current dashboard snapshot for one approved member group and date.

**Input**
- `group_id`
- Optional `cycle_date`; defaults to the group's current local date.

**Output**
- Group summary.
- Current cycle summary.
- Current user's assignment summary.
- Array of 30 assignment rows.
- Counts by status.
- Completion percentage.
- `server_generated_at`.

**Validation**
- Caller must be active or recently inactive approved member of the group.
- Non-members with pending/rejected requests cannot call this function successfully.

## Function: `get_daily_history`

Returns daily history summaries and optional details for a group.

**Input**
- `group_id`
- `from_date`
- `to_date`

**Output**
- Array of daily summaries with completed, pending, missed, late, and percentage values.
- Optional assignment details when requesting one day.

**Validation**
- Caller must be an active organizer of the group.
- Non-organizer approved members and non-members cannot read history summaries or details through this function.
