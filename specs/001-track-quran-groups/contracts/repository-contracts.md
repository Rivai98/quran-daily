# Contract: Flutter Repositories and Use Cases

These contracts define the boundary between Cubits and data sources. Cubits call use cases; use cases call repository interfaces; repositories choose Supabase, local SQLite cache, or both.

## Result and Failure Model

All asynchronous operations return either a value or a typed failure. Failures must be display-safe at the ViewModel layer and must preserve enough detail for logging/debugging.

**Failure categories**
- `AuthFailure`
- `PermissionFailure`
- `ValidationFailure`
- `NetworkFailure`
- `OfflineQueuedFailure`
- `SyncConflictFailure`
- `UnknownFailure`

## AuthRepository

**Responsibilities**
- Start Google Sign-In through Supabase Auth.
- Expose current authenticated user.
- Sign out and clear local selected-group state if needed.

**Required methods**
- `currentUser()`
- `signInWithGoogle()`
- `signOut()`
- `authStateChanges()`

## GroupRepository

**Responsibilities**
- Load approved group list for the signed-in user.
- Create public groups.
- Search public group profiles.
- Submit and review join requests.
- Load and cache dashboard snapshots.
- Publish and update daily cycles through backend contracts.
- Queue and sync personal completion operations.

**Required methods**
- `watchUserGroups()`
- `createGroup(name, shortDescription, localDayTimezone, isPublic)`
- `searchPublicGroups(query, limit, offset)`
- `submitJoinRequest(groupId)`
- `loadJoinRequestsForOrganizer(groupId)`
- `reviewJoinRequest(joinRequestId, decision)`
- `getDashboard(groupId, cycleDate)`
- `watchCachedDashboard(groupId)`
- `publishDailyCycle(groupId, cycleDate, assignmentDraft)`
- `swapAssignmentParts(cycleId, assignmentAId, assignmentBId)`
- `reassignAssignment(assignmentId, newMembershipId)`
- `markAssignmentComplete(assignmentId, recordedAt)`
- `undoAssignmentCompletion(assignmentId)`
- `syncPendingOperations()`
- `getHistory(groupId, fromDate, toDate)` for organizers only

## QuranPartRepository

**Responsibilities**
- Provide the 30 Quran part labels and reading ranges.
- Support Arabic labels and text-size rendering metadata.
- Make Quran part metadata available offline.
- Do not provide full Quran text in v1.

**Required methods**
- `getAllParts()`
- `getPart(partNumber)`

## LocalCacheRepository

**Responsibilities**
- Store dashboard snapshots, history summaries, Quran part metadata, public discovery cache, user settings, and pending sync operations.
- Provide stale timestamps for offline UI banners.

**Required methods**
- `saveDashboardSnapshot(snapshot)`
- `loadDashboardSnapshot(groupId)`
- `savePublicGroupProfiles(profiles)`
- `loadPublicGroupProfiles(query)`
- `saveHistorySummaries(groupId, summaries)`
- `loadHistorySummaries(groupId)`
- `saveUserSettings(settings)`
- `loadUserSettings()`
- `enqueueSyncOperation(operation)`
- `loadPendingSyncOperations()`
- `markSyncOperationSynced(operationId)`
- `markSyncOperationFailed(operationId, failure)`

## Use Cases

Use cases are small command/query objects that wrap one business operation.

**Required use cases**
- `SignInWithGoogle`
- `LoadUserGroups`
- `CreateGroup`
- `SearchPublicGroups`
- `SubmitJoinRequest`
- `LoadOrganizerJoinRequests`
- `ReviewJoinRequest`
- `LoadGroupDashboard`
- `WatchCachedDashboard`
- `PublishDailyCycle`
- `SwapAssignmentParts`
- `ReassignAssignment`
- `MarkAssignmentComplete`
- `UndoAssignmentCompletion`
- `SyncPendingCompletionOperations`
- `LoadDailyHistory`
- `UpdateQuranTextSize`

## Cubit Boundaries

**AuthCubit**
- Owns auth entry state only.
- Does not contain group or assignment logic.

**GroupSelectionCubit**
- Loads approved groups and selected group state.
- Owns create-group form state, timezone selection, and create failure state.
- Does not publish cycles or mark completion.

**GroupDiscoveryCubit**
- Searches public group profiles.
- Submits join requests.
- Shows pending/rejected/approved request state.
- Does not show private member lists or progress for non-members.

**JoinRequestsCubit**
- Loads pending join requests for organizers.
- Approves or rejects requests.
- Shows group-full validation when approval would exceed 30 active members.

**GroupDashboardCubit**
- Loads dashboard snapshot for approved members.
- Combines cached and refreshed dashboard state.
- Shows offline/stale/syncing indicators.

**AssignmentCubit**
- Owns personal assignment completion and undo flow.
- Calls completion use cases only.

**OrganizerCubit**
- Owns assignment draft, publish, swap, and reassign state.
- Enforces UI-level validation before calling backend functions.

**HistoryCubit**
- Loads organizer-only daily history summaries and details.

**SettingsCubit**
- Owns local display settings such as Quran label/range text size.

## Explicit v1 Exclusions

- No `PushNotificationRepository`.
- No FCM token registration use case.
- No in-app Quran reader repository.
- No audio, chat, contact import, or public directory ranking repository.
