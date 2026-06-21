# Research: Quran Group Reading Tracker UI

## Decision: Use feature-first MVVM with Cubit as ViewModel

**Rationale**: The project constitution requires `data/`, `cubit/`, and `view/` per feature. Cubit gives a small, testable ViewModel layer for discovery, join requests, dashboard, assignment, organizer, and history state. It also keeps widgets free of business rules.

**Alternatives considered**:
- Plain `setState`: rejected because business state would move into widgets and violate the constitution.
- Full Bloc event/state pairs: rejected for v1 because Cubit is simpler and the approved stack explicitly chooses Cubit.
- Riverpod or Provider: rejected because the approved stack and constitution require Cubit.

## Decision: Keep v1 UI focused on Quran group tracking, not Quran reading

**Rationale**: Clarification resolved that v1 shows Quran part labels and reading ranges only. The first valuable slice is coordinating 30 people and tracking completion, not rendering full Quran text, bookmarks, or reading position.

**Alternatives considered**:
- Basic assigned-part reader: rejected because it adds text rendering, reading-position state, and Quran content validation outside this feature's core tracking goal.
- Full Quran reader/navigation: rejected because it would turn v1 into a separate reader product.

## Decision: Make the app Arabic-first in v1

**Rationale**: The user clarified the app is fully Arabic. User-facing copy, join-request pending status, Quran labels, status labels, and validation messages must be Arabic-first, with RTL-aware layouts.

**Alternatives considered**:
- Bilingual Arabic/English v1: rejected because it increases copy, layout, and QA scope without being requested for the first release.
- English internal placeholders in UI: rejected because the spec requires all v1 user-facing interface copy in Arabic.

## Decision: Use Supabase Auth with Google Sign-In

**Rationale**: The approved stack requires Supabase Auth with Google Sign-In. Supabase session identity maps directly to public discovery requests, memberships, organizer permissions, assignment completion records, and row-level security.

**Alternatives considered**:
- Anonymous auth: rejected because join requests, organizer approvals, memberships, and auditability require stable identity.
- Custom auth server: rejected because Supabase Auth is already approved and avoids extra backend ownership.
- Email/password first: deferred because the approved sign-in method is Google.

## Decision: Use public group discovery with organizer-approved join requests

**Rationale**: The clarified join flow requires users to find public groups and request membership. Non-members see only a minimal public profile: group name, short description, member count, and timezone. Member lists and reading progress remain private until approval.

**Alternatives considered**:
- Private invite code/link: rejected by clarification.
- Contact import invitations: rejected because contact import is out of scope.
- Public group search with direct join: rejected because organizers need control over the exactly-30-active-member model.

## Decision: Use one group-level timezone chosen by organizer

**Rationale**: A shared 30-person daily reading cycle needs one shared day boundary so pending, missed, completed, and late statuses are consistent for every member.

**Alternatives considered**:
- Each member's device timezone: rejected because the same assignment could become missed/late at different times for different users.
- Fixed Makkah timezone: rejected because groups may operate around a local community schedule.
- Organizer's current device timezone: rejected because travel/device changes should not silently move the group cutoff.

## Decision: Use Supabase PostgreSQL as server source of truth

**Rationale**: Public discovery, join request approval, group membership, exactly-30-member validation, assignment uniqueness, completion state, and history need transactional guarantees. PostgreSQL constraints and database functions can enforce one assignment per active member and one Quran part per daily cycle.

**Alternatives considered**:
- Client-only local database: rejected because it cannot coordinate shared group truth.
- Firebase Firestore as primary database: rejected because the approved stack selects Supabase PostgreSQL.

## Decision: Put critical mutations behind Supabase database functions or backend functions

**Rationale**: Requesting to join, approving/rejecting requests, publishing cycles, swapping assignments, reassigning parts, marking completion, undoing completion, and late/missed transitions must be validated atomically. Central functions prevent clients from bypassing organizer rules, group capacity rules, privacy boundaries, or duplicate assignment constraints.

**Alternatives considered**:
- Direct table writes from the Flutter app: rejected because client-side validation alone cannot guarantee uniqueness, approval, privacy, and role rules.
- Edge functions for every read/write: rejected because database functions are simpler for transactional database-bound operations.

## Decision: Use local SQLite cache plus a small sync queue

**Rationale**: The constitution and spec require users to see today's assignment offline after opening the group and to queue personal completion state. SQLite stores the dashboard snapshot, today's assignment, Quran part metadata, recent history, public discovery cache, and pending personal completion operations.

**Alternatives considered**:
- `shared_preferences` for all local state: rejected because relational assignment/history data needs structured queries.
- No offline queue: rejected because personal completion must remain usable offline.
- Full offline conflict system: rejected for v1; only personal completion queueing is required.

## Decision: Use Repository Pattern and use cases between Cubits and data sources

**Rationale**: Cubits should not know whether data came from Supabase, local SQLite, or cache. Repositories provide the data contract, while use cases encode operations like search public groups, submit join request, approve request, publish cycle, mark complete, reassign part, and load dashboard.

**Alternatives considered**:
- Cubits call Supabase clients directly: rejected because it couples UI state to backend details and makes offline behavior harder to test.
- Repository without use cases: rejected because the approved stack calls for use cases and the feature has business operations worth naming.

## Decision: Use `get_it` for dependency injection

**Rationale**: `get_it` is lightweight for a Flutter app and avoids introducing code generation before there is a strong need. It can register Supabase clients, local databases, repositories, use cases, and Cubits in predictable app bootstrap code.

**Alternatives considered**:
- Manual constructor wiring everywhere: rejected because route and Cubit creation become noisy as features grow.
- `injectable` code generation: deferred until dependency graph complexity justifies generated setup.

## Decision: Defer Firebase Cloud Messaging and push notifications

**Rationale**: Clarification resolved that v1 has no notification work. The app must not request notification permissions, register device tokens, send reminders, or expose notification settings in this feature.

**Alternatives considered**:
- Register FCM tokens only: rejected because it adds unused platform setup and privacy prompts without v1 behavior.
- Send assignment reminders: rejected because notifications are explicitly later scope.
- Keep Firebase dependency in v1: rejected because no v1 requirement uses it.

## Decision: Use Material mobile UI with Arabic/RTL and adjustable Quran label text size

**Rationale**: Flutter Material gives a robust mobile UI baseline. The devotional context needs calm, readable Arabic screens with clear status semantics, RTL layout support, and user-controlled text size for Quran part labels/ranges.

**Alternatives considered**:
- Heavy custom visual system first: rejected because core usability and readability matter more than custom decoration in v1.
- LTR-only UI: rejected by the spec and constitution.
