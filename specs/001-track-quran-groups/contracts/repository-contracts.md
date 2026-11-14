# Contract: Flutter Repositories, Use Cases, and Cubits (amended 2026-11-14)

Cubits depend on repository interfaces (and the two use cases below); repositories choose Supabase, SQLite, or both. All async methods return `Result<T>` from `lib/core/errors/result.dart`.

## Failure Model (`lib/core/errors/failures.dart`)

`FailureKind`: `unauthenticated`, `forbidden`, `validation`, `network`, `offlineQueued`, `notFound`, `conflict` (e.g. `juz_already_taken`, `group_full`), `dayClosed`, `limitReached` (`owner_group_limit`), `unknown`. Each `Failure` carries `kind` and the backend `code` (for copy mapping and logs). No Arabic text in failures or states; Views map `code`/`kind` to `ArabicStrings`.

## AuthRepository (spec 002)

Defined in [spec 002 repository contracts](../../002-email-password-auth/contracts/repository-contracts.md). `AuthCubit` is created and provided by `lib/app/` (auth gate).

## SessionGateway (`lib/core/auth/session_gateway.dart`)

Core interface so feature modules never import `features/auth` (constitution IV): `String? get currentUserId`, `Future<Result<void>> signOut()`. Implemented by `AuthRepositoryImpl` and registered in DI under both types. `quran_groups` repositories use `currentUserId` for cache keys; `SettingsCubit` uses `signOut()`, and `AuthCubit` reacts to the resulting auth-state event.

## GroupsRepository (`features/quran_groups/data/repositories/`)

- `Future<Result<MyGroupsOverview>> getMyGroups()` – `{ groups: List<MyGroupSummary>, pendingRequests: List<PendingJoinRequest> }`; network, falls back to cache with `isStale`.
- `createGroup(CreateGroupInput)` → `CreatedGroup`
- `updateGroupSettings(groupId, GroupSettingsPatch)`
- `startKhatma(groupId, startJuz)` → `DashboardSnapshot`
- `archiveGroup(groupId)`, `transferOwnership(groupId, membershipId)`, `regenerateInvite(groupId)`
- `searchPublicGroups({query, needsMembersOnly, limit, offset})` → `List<PublicGroupProfile>`
- `getInvitePreview(code)` → `PublicGroupProfile`
- `joinGroup({groupId, inviteCode, source})` → `JoinOutcome` (joined/pending)
- `joinAnyGroup(deviceTimezone)` → `JoinOutcome`
- `cancelJoinRequest(id)`, `listJoinRequests(groupId)`, `reviewJoinRequest(id, approve)`
- `getMembers(groupId)` → `SeatMap`
- `moveMemberSeat(groupId, membershipId, targetSeat)`, `setMemberRole(...)`, `removeMember(...)`, `leaveGroup(groupId)`

Network-only methods return `Failure(network)` when offline (no queueing).

## KhatmaRepository

- `Future<Result<DashboardSnapshot>> getDashboard(groupId)` – network; on success caches snapshot; on network failure returns cached snapshot flagged `isStale` with `cachedAt`, or `Failure(network)` if none.
- `Stream<DashboardSnapshot?> watchCachedDashboard(groupId)`
- `markComplete(assignmentId, clientRecordedAt)` / `undoCompletion(assignmentId)` – online call; offline: apply optimistic change to cache, enqueue, return `Failure(offlineQueued)` with the optimistic snapshot.
- `volunteer(assignmentId)`, `overrideAssignment(assignmentId, membershipId)` – network only.
- `getHistory(groupId, {beforeDate, limit})`, `getHistoryDay(groupId, date)` – network, cache last page.
- `Future<SyncReport> syncPending()` – replays queue in order; maps `day_closed` to failed item.

## QuranMetadataRepository (`lib/core/quran/`)

- `Future<void> load()` – parses `assets/quran/quran-data.xml`; throws if missing.
- `JuzInfo juz(int number)` – start/end sura and aya.
- `String suraName(int sura)` – Arabic name from the same file.
Never returns or stores ayah text in this feature.

## SettingsRepository (`lib/core/settings/`)

Lives in core because both `quran_groups` (`SelectedGroupCubit`, Quran label scale) and `settings` use it.

`selectedGroupId` get/set, `quranTextScale` get/set (0.85-1.6).

## LocalCache (`lib/core/storage/`)

`LocalDatabase` (sqflite, versioned migrations) with DAOs for `cached_snapshots`, `cached_groups`, `cached_history`, `sync_queue` (see data-model). Used only by repositories.

## Use Cases (only where logic exists)

- `MarkAssignmentComplete` / `UndoAssignmentCompletion`: optimistic update + online call + enqueue on network failure.
- `SyncPendingCompletions`: triggered by connectivity regained, app resume, dashboard refresh.

## Cubits (`features/quran_groups/cubit/`)

| Cubit | Owns | Calls |
|-------|------|-------|
| `SelectedGroupCubit` (app root) | selected group id, switch group | SettingsRepository |
| `GroupListCubit` | my groups, stale flag, entry points when empty | GroupsRepository |
| `CreateGroupCubit` | form validation state, submit, limit error | GroupsRepository |
| `DiscoveryCubit` | query, results, paging, per-group join state | GroupsRepository |
| `JoinCubit` | invite code preview, join, join-any, pending state | GroupsRepository |
| `DashboardCubit` | snapshot, stale/offline, refresh, volunteer action | KhatmaRepository, SyncPendingCompletions |
| `AssignmentCubit` | complete / undo with confirmation, queued state | Mark/Undo use cases |
| `MembersCubit` | seat map, move seat, roles, remove, leave, transfer | GroupsRepository |
| `JoinRequestsCubit` | pending requests, approve/reject, group full | GroupsRepository |
| `GroupSettingsCubit` | settings form, start khatma, invite regenerate, archive | GroupsRepository |
| `HistoryCubit` | day summaries, paging, day detail | KhatmaRepository |
| `SettingsCubit` (`features/settings`) | text scale, sign-out trigger | SettingsRepository, SessionGateway |

Cubits never depend on other Cubits; cross-cutting state (auth, selected group) is read by Views from root providers.

States: `Equatable`, `status` enum (`initial, loading, success, empty, failure, offline`) + data + `Failure?`. No `BuildContext`, colors, or Arabic copy in states.

## Exclusions

No notification repository, no Realtime subscriptions, no Quran text repository (spec 003), no admin console.
