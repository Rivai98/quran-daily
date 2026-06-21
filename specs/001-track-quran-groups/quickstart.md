# Quickstart: Validate Quran Group Reading Tracker UI

This guide describes how to validate the planned feature once implementation tasks are generated and completed. It is not an implementation script.

## Prerequisites

- Flutter SDK compatible with Dart `^3.10.4`.
- iOS simulator and Android emulator available for final validation.
- Supabase project configured for Auth, PostgreSQL tables, row-level security, and database/backend functions from [contracts/supabase-rpc.md](./contracts/supabase-rpc.md).
- Google Sign-In configured for Supabase Auth on iOS and Android.
- App runtime configuration for Supabase URL and Supabase anon key.
- No Firebase Cloud Messaging setup is required for v1.

## Expected Commands

Run after dependencies and code are added by implementation tasks:

```powershell
flutter pub get
flutter analyze
flutter test
flutter test integration_test
```

Run target-specific smoke checks before release:

```powershell
flutter test integration_test -d emulator
flutter test integration_test -d ios
```

## Validation Scenario 1: Arabic Sign In and Public Discovery

1. Launch the app signed out.
2. Sign in with Google.
3. Open public group discovery.
4. Search or browse available public groups.

**Expected result**: All user-facing copy is Arabic. Public group profiles show only group name, short description, active member count, and timezone. Member lists, daily progress, assignments, and history are not visible before approval.

## Validation Scenario 2: Request to Join a Public Group

1. Sign in as a user who is not a member of a public group.
2. Open the public group profile.
3. Submit a join request.

**Expected result**: The app shows the exact Arabic pending status `بانتظار القبول من مالك المجموعة` and does not open the member dashboard until an organizer approves the request.

## Validation Scenario 3: Organizer Approves Join Request

1. Sign in as an organizer of the requested group.
2. Open member management or organizer join requests.
3. Approve the pending request while the group has fewer than 30 active members.

**Expected result**: The request becomes approved, an active membership is created, and the active member count updates.

## Validation Scenario 4: Block Approval When Group Is Full

1. Sign in as an organizer of a group with 30 active members.
2. Open a pending join request.
3. Attempt to approve it.

**Expected result**: Approval is blocked with a clear Arabic explanation that the group already has 30 active members.

## Validation Scenario 5: Open Approved Group Dashboard

1. Sign in as an approved group member.
2. Select an existing Quran group with a published daily cycle.
3. Verify the dashboard.

**Expected result**: The dashboard shows group name, current date based on group timezone, user's assigned Quran part label/range, 30 assignment statuses, completion count, and completion percentage.

## Validation Scenario 6: Organizer Publishes Daily Cycle

1. Sign in as an organizer of a group with exactly 30 active members.
2. Open organizer assignment review.
3. Generate or review the 30 member-to-part assignments.
4. Swap two assignments.
5. Publish the daily cycle.

**Expected result**: The app publishes exactly 30 assignments with no duplicate member and no duplicate Quran part.

## Validation Scenario 7: Block Invalid Publishing

1. Sign in as an organizer of a group with fewer than 30 active members.
2. Attempt to publish today's daily cycle.

**Expected result**: Publishing is blocked with a clear Arabic explanation that v1 requires exactly 30 active members.

## Validation Scenario 8: Member Marks Completion

1. Sign in as a member with a pending assignment.
2. Open personal assignment detail.
3. Mark the assigned part complete.
4. Return to dashboard.

**Expected result**: The personal status changes to completed, dashboard count increases by one, and duplicate completion is prevented.

## Validation Scenario 9: Offline Cached Assignment and Queued Completion

1. Open a group dashboard online so today's assignment is cached.
2. Disable network.
3. Relaunch the app.
4. Open the selected approved group dashboard.
5. Mark the personal assignment complete.
6. Restore network and trigger sync.

**Expected result**: The app shows the cached assignment offline, labels shared progress as possibly stale, queues personal completion, and syncs it when connectivity returns.

## Validation Scenario 10: History Review

1. Sign in as organizer.
2. Open a group with at least seven previous daily cycles.
3. Open history.
4. Select a day with missed or late assignments.

**Expected result**: The history screen shows completed count, missed count, late count, completion percentage, and member/part details for missed or late assignments.

## Validation Scenario 11: Arabic Text Size and No Reader

1. Open dashboard and personal assignment detail.
2. Increase Quran label/range text size in settings.
3. Return to Quran-related labels and reading ranges.
4. Look for full Quran reader, bookmarks, reading-position controls, or Quran text navigation.

**Expected result**: Arabic labels remain readable, RTL presentation remains correct, text does not overlap important actions, and no in-app Quran reader controls exist in v1.

## Validation Scenario 12: No Notification Surface

1. Launch the app after sign-in.
2. Navigate through dashboard, settings, member management, and assignment detail.

**Expected result**: The app does not request notification permission, does not register push tokens, and does not show reminder or push-notification settings in v1.

## Test Coverage Expectations

- Repository/use-case unit tests cover success and failure paths for public discovery, join request submission, organizer approval/rejection, dashboard loading, publishing, assignment uniqueness, completion, undo, offline queueing, and sync conflict handling.
- Cubit tests cover loading, cached/offline states, stale indicators, public discovery states, join request pending/approved/rejected states, organizer validation, completion queued/synced states, and error states.
- Widget tests cover Arabic auth entry, group selection, public discovery, join-request pending message, organizer join request review, dashboard, assignment detail, organizer review, member management, history, settings, text-size behavior, no-reader boundary, and no-notification boundary.
- Integration tests cover the main discovery/request/approval flow, member dashboard flow, organizer publishing flow, offline queued completion flow, and history review flow.
