# Contract: v1 UI Screens and States

The v1 app UI is a working Quran group tracker, not a marketing landing page. Screens should prioritize daily use: public group discovery, organizer approval, quick identification of the assigned Quran part, clear group progress, and simple completion.

## Global UI Requirements

- All user-facing v1 interface copy is Arabic.
- Phone-first layouts for iOS and Android.
- Arabic Quran labels and app copy must support RTL presentation.
- Quran part labels and reading ranges must respect the user's text-size setting.
- Status colors must be paired with Arabic labels or icons so status is not color-only.
- Offline or stale group progress must be clearly visible.
- Future features must not appear as disabled navigation items in v1.
- The app must not show notification permission prompts, reminder controls, or push settings in v1.

## Screen: Auth Entry

**Purpose**: Let the user sign in with Google.

**Primary states**
- Signed out.
- Signing in.
- Sign-in failed.
- Signed in and routing to group selection or dashboard.

**Required UI**
- App name.
- Google sign-in action.
- Arabic error message area.
- Loading state.

## Screen: Group Selection

**Purpose**: Let the signed-in user choose an approved Quran reading group, create a group, or open public discovery.

**Primary states**
- Loading approved groups.
- No approved groups yet.
- Approved groups available.
- Offline with cached selected group only.
- Create group failure.

**Required UI**
- List of approved groups.
- Create group action.
- Public group discovery action.
- Last selected group shortcut when available.

## Screen: Public Group Discovery

**Purpose**: Let users find public Quran groups and request to join.

**Primary states**
- Loading public groups.
- Public groups available.
- No matching public groups.
- Join request submitting.
- Join request pending.
- Join request rejected.
- Offline with cached public group profiles.
- Error.

**Required UI**
- Search/list of public group profiles.
- Public profile fields only: group name, short description, active member count, and group timezone.
- Request-to-join action.
- Pending Arabic status exactly: `بانتظار القبول من مالك المجموعة`.
- No member list, assignment list, progress percentage, history, or organizer-only data before approval.

## Screen: Organizer Join Requests

**Purpose**: Let organizers approve or reject public join requests.

**Primary states**
- Loading requests.
- No pending requests.
- Pending requests available.
- Approving.
- Rejecting.
- Group full.
- Review failed.

**Required UI**
- Pending requester identity.
- Approve and reject actions.
- Active member count out of 30.
- Clear Arabic validation when approval is blocked because the group has 30 active members.

## Screen: Group Dashboard

**Purpose**: Primary daily screen for approved members.

**Primary states**
- Loading cached dashboard.
- Cached dashboard with refresh in progress.
- Fresh dashboard.
- Offline/stale dashboard.
- No published cycle.
- Error.

**Required UI**
- Group name and current date resolved by group timezone.
- Current user's assigned Quran part label/range.
- Completion count out of 30.
- Completion percentage.
- 30-assignment status overview.
- Assignment list with member identity, Quran part label, and status.
- Primary action to open personal assignment.
- Organizer entry point only for organizers.
- Join-request review entry point only for organizers.
- History entry point.
- Offline/stale indicator when shared progress may be outdated.

## Screen: Personal Assignment Detail

**Purpose**: Let a member understand and complete today's assigned part.

**Primary states**
- Pending.
- Completing.
- Completed.
- Late.
- Offline queued.
- Undo available.
- Undo failed.

**Required UI**
- Quran part label and reading range only; no full Quran reader.
- Current status.
- Completion action.
- Confirmation or undo flow.
- Sync status if completion is queued offline.
- Text-size-aware Quran label/range presentation.

## Screen: Organizer Assignment Review

**Purpose**: Let organizers prepare, review, adjust, and publish daily assignments.

**Primary states**
- Draft not ready.
- Draft ready with 30 assignments.
- Duplicate or missing assignment warning.
- Publishing.
- Published.
- Publish failed.

**Required UI**
- 30 active member rows.
- Assigned Quran part for each row.
- Swap action for two assignments.
- Reassign action for pending or missed assignment where allowed.
- Publish action gated by validation.
- Clear Arabic explanation when the group does not have exactly 30 active members.

## Screen: Member Management

**Purpose**: Let organizers see active members and manage readiness for a 30-member daily cycle.

**Primary states**
- Exactly 30 active members.
- Fewer than 30 active members.
- Group full.
- Member inactive or removed.
- Pending join requests exist.

**Required UI**
- Active member count.
- Active member list.
- Organizer/member role indicator.
- Slot readiness indicator.
- Entry to organizer join request review.
- Explanation that v1 requires exactly 30 active members before publishing.

## Screen: Daily History

**Purpose**: Let organizers review previous cycles and identify missed or late parts.

**Primary states**
- Loading.
- History available.
- Empty history.
- Offline cached history.
- Error.

**Required UI**
- Daily summaries with completed, missed, late, and percentage values.
- Detail view for a selected day.
- Missed and late assignments visible by member and Quran part.

## Screen: Settings

**Purpose**: Let users control local display preferences and inspect offline state.

**Primary states**
- Current settings loaded.
- Saving setting.
- Save failed.

**Required UI**
- Quran part label/range text-size control.
- Arabic/RTL display status where applicable.
- Selected group cache timestamp.
- Sign-out action.
- No notification settings in v1.

## Navigation Contract

```text
Auth Entry
  -> Group Selection
      -> Public Group Discovery
      -> Group Dashboard
          -> Personal Assignment Detail
          -> Organizer Assignment Review
          -> Organizer Join Requests
          -> Member Management
          -> Daily History
          -> Settings
```

The dashboard is the default first screen after sign-in when a selected approved group exists.
