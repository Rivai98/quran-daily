# Research: Quran Group Reading Tracker (amended 2026-11-14)

Each entry: Decision, Rationale, Alternatives considered. Decisions from the 2026-06-21 research that remain valid (MVVM + Cubit, Supabase Postgres as source of truth, SQLite cache, `get_it`, no FCM) are restated briefly.

## R1. Rotation is a pure function of seat, start juz, and day index

**Decision**: `juz(seat, day) = ((start_juz - 1) + (seat - 1) + day_index) mod 30 + 1`, where `day_index` = number of group days since the start day (start day = 0). Implemented once in SQL (`juz_for_seat`) and mirrored in Dart only for tests and offline display of the already-cached day.

**Rationale**: Deterministic, testable, matches the WhatsApp practice (seat k on day d+1 reads one juz further), and never drifts even if days are skipped by the scheduler, because the index comes from dates, not from yesterday's row.

**Alternatives**: Copy yesterday's assignments +1 (drifts after a failed job); random daily distribution (not how the group works).

## R2. Group-local date and rollover

**Decision**: Each group stores an IANA `timezone` and a `day_start_time` (local time, default 00:00). The group-local date of instant `t` is `date((t AT TIME ZONE tz) - day_start_time)`. Day `d` is open from its rollover until the next rollover, then in **grace** for one more group day (late completions), then **closed**.

**Rationale**: Matches spec FR-010/FR-016; a "day after Fajr" group sets e.g. 05:00. Timezone/start-time changes apply from the next date because past days store their own date and are never recomputed.

**Alternatives**: Member device timezone (inconsistent statuses); fixed Makkah time (communities differ).

**Timezone/start-time change (U1)**: the current day keeps its stored `ends_at`. The next day opens exactly at that `ends_at` and ends at the first rollover under the new settings that is at least 12 hours later, so no gap or overlap ever occurs; all later days follow the new settings.

## R3. Materialize days with pg_cron plus a lazy fallback

**Decision**: `pg_cron` runs `generate_due_group_days()` and `advance_day_states()` every minute. `get_dashboard` also calls `ensure_current_group_day(group_id)` (idempotent, unique on `(group_id, group_date)`) so a member opening the app never waits for the job.

**Rationale**: Guarantees SC-012 (≤ 1 min) and keeps history complete for groups nobody opens; idempotency makes double execution safe.

**Alternatives**: Edge Function cron (extra moving part); purely lazy creation (gaps for unopened days, missed/unread never recorded).

## R4. Assignment rows carry kind and reader

**Decision**: Each group day has exactly 30 `assignments` (one per juz, unique `(group_day_id, juz)` and `(group_day_id, seat_number)`). Columns: `kind` (`seat`, `override`, `volunteer`, `unassigned`), `reader_membership_id` (nullable), `status`. Empty seat → `kind = unassigned`, `status = available`.

**Rationale**: One row per juz keeps "all 30 juz exactly once" a database constraint, and volunteering/overrides become single-row updates.

**Alternatives**: Separate volunteer table (two sources of truth for who reads a juz).

## R5. Volunteering race safety

**Decision**: `volunteer_for_juz` does `UPDATE assignments SET kind='volunteer', reader_membership_id=me, status='pending' WHERE id=$1 AND kind='unassigned' AND status='available' AND day is open RETURNING *`; zero rows → `juz_already_taken`.

**Rationale**: Single conditional update is atomic in Postgres; exactly one concurrent caller wins (SC-006).

**Alternatives**: Advisory locks / SELECT FOR UPDATE (more code, same result).

## R6. Status transitions owned by the server

**Decision**: Open day: `pending ↔ completed` (complete/undo), `available → pending` (volunteer/override). On entering grace: `pending → missed`, `available → unread`. In grace: `missed → late` (complete), `late → missed` (undo). On close: no further changes. `full_khatma` = all 30 in (`completed`, `late`), recomputed on every change.

**Rationale**: Encodes FR-015..FR-018 and FR-017a in one place; clients render statuses, never derive them.

## R7. Join flows and seat allocation

**Decision**: `join_group(group_id | invite_code)` decides: removed user → pending request; approval group → pending request; auto-accept with free seat → active membership in the **lowest free seat number**; no seat → `group_full`. Approving a request uses the same seat allocation. `join_any_group()` picks per spec clarification (public, auto-accept, has seat; device timezone match first, then fewest empty seats, then oldest group) and calls the same path. Joining an active group sets today's `unassigned` row of that seat to `kind=seat, reader=new member, status=pending` **only if** nobody volunteered for it; otherwise the volunteer keeps it for today.

**Rationale**: One allocation code path; deterministic seat choice; volunteers are never displaced mid-day.

**Alternatives**: Let the user pick a seat (extra UI, no user value).

**Backfill (U2)**: if the scheduler was down, `generate_due_group_days()` and `ensure_current_group_day()` create every missing date since the last existing day, apply grace/closed states for past dates immediately, and compute rotation from the date index, so history never has gaps.

## R8. Leaving, removal, and seat moves

**Decision**: Leave/remove sets membership status `left`/`removed`, frees the seat; every non-completed row of today read by that member (own seat, volunteer, or override) becomes `unassigned/available`; completed rows stay. Seat moves update `seat_number`; because today's rows are already materialized, moves naturally take effect next day (FR-007). Owner cannot leave without `transfer_ownership` or `archive_group`.

## R9. Invite codes and links

**Decision**: 8-character code from an unambiguous alphabet (no 0/O/1/I), unique among non-archived groups, regenerable by the Owner. Shared as Arabic text containing the code and `qurandaily://join/<CODE>`; the app handles the scheme via `app_links` and also offers manual code entry. HTTPS universal/app links are deferred (need a domain).

**Alternatives**: Universal links now (domain + platform association files; not available yet).

## R10. Authorization model

**Decision**: RLS on every table: members read their group's rows; non-members read nothing except via `search_public_groups` / `get_invite_preview` (return public profile only). All writes go through `SECURITY DEFINER SET search_path = ''` functions that check `auth.uid()` and role. Roles: `owner` (exactly one per group), `supervisor`, `member`. Group roles are independent of spec 002 `app_admins`.

## R11. Offline personal loop

**Decision**: Cache `DashboardSnapshot` JSON per group in SQLite after every successful load. Complete/undo update the cached snapshot optimistically and enqueue a `sync_queue` row (`mark_complete` / `undo_completion`, assignment id, client timestamp). Sync runs on connectivity regained, app resume, and dashboard refresh; for `offline_sync` the server applies `client_recorded_at`, clamped to `[opens_at, server receipt time]`, to decide on-time vs late (rejecting if the day is closed → shown as failed with Arabic explanation). Online calls always use server time. Trusting the device clock for offline completions is an accepted trade-off: the worst case is a member's own late completion shown as on-time, which affects only their own record. Volunteering, joining, and management require network.

## R12. Verified juz metadata (Principle VII)

**Decision**: Use Tanzil's `quran-data.xml` (juz start sura/aya and Arabic surah names). The project owner downloads it from the official Tanzil metadata page, records origin/version/license in `assets/quran/SOURCE.md`, and commits `assets/quran/checksums.sha256`. `QuranMetadataRepository` parses juz starts and sura ayah counts; a juz ends one ayah before the next juz starts (crossing to the previous sura's last ayah, using that sura's ayah count from the file), and juz 30 ends at the last ayah of the last sura as given by the file. No boundary, sura name, or ayah count is typed in code or tests. Exact source, edition, riwayah, version, and license are fixed in plan.md "Quran Content Source". Range label: "من سورة {name} آية {n} إلى سورة {name} آية {m}" with Arabic-Indic digits. Juz ordinal names (الجزء الأول ... الجزء الثلاثون) are UI copy in `arabic_strings.dart`. No ayah text is shown in this feature.

**Rationale**: Keeps every Quran-derived value sourced and checksummed; avoids reproducing ayah text before the Mushaf feature exists.

**Alternatives**: Hand-typed range table (forbidden); Quran API at runtime (breaks offline).

## R13. Design system delivery

**Decision**: Build `lib/core/design_system/` (tokens + widgets) and bundle fonts before any screen; delete `lib/core/theme/` after migration. A test scans `lib/features/**` for `Color(0x`, `fontSize:` and `BorderRadius.circular(` literals.

## R14. State management details

**Decision**: Cubits per screen-level unit; states are `Equatable` with a `status` enum (`initial, loading, success, empty, failure, offline`) plus data; failures carry a `FailureKind`, mapped to Arabic copy in the View. Global `AuthCubit` (spec 002) and `SelectedGroupCubit` provided at app root by `lib/app/`. Feature modules never import each other (Principle IV): `quran_groups` and `settings` use the core `SessionGateway` interface (`currentUserId`, `signOut()`), implemented by `AuthRepositoryImpl` in `features/auth` and registered in DI; `AuthCubit` reacts to the resulting auth-state event. `SettingsRepository` lives in `lib/core/settings/`.

## R15. No Realtime in v1

**Decision**: Dashboard refreshes on open, app resume, pull-to-refresh, and after own mutations. Supabase Realtime deferred.

**Rationale**: YAGNI; daily reading does not need second-level freshness, and Realtime complicates offline/stale semantics.

## R16. Docker-free backend workflow (amended 2026-11-15)

**Decision**: No Docker and no local Supabase stack. The hosted project `quran-daily` (ref `zwkvijapswwutwozbvgy`) is the development database until real users exist.
- **pgTAP test runner**: `supabase test db` requires a local Docker daemon even when passed `--remote`. Therefore, pgTAP test files run against the remote database via `python scripts/run_remote_pgtap.py supabase/tests/<file>.sql`.
- **Migrations application**: `supabase db push` fails with `DbPushMissingLocalError` when parallel implementers push version timestamps out of order. Migrations are applied individually via `supabase db query --remote --yes -f <file>`, followed by `supabase migration repair --remote --yes --status applied <version>`.
- **Hosted flags**: Every non-interactive hosted command requires the `--remote --yes` flags.
- **Edge Functions**: Deployed server-side via `supabase functions deploy <name> --use-api`.

**Rationale**: The owner develops a mobile-only app on Windows without Docker. The Python test wrapper and individual query/repair workflow allow full remote development, test execution, and schema migrations without local container infrastructure.

**Consequence**: Before public release, create a separate dev project (free plan allows two active projects) and keep `quran-daily` for production; from then on `db reset --remote` is forbidden on production.

**Alternatives**: Local stack via Docker (`supabase start`) — rejected by owner. CLI `db push` — fails on parallel branch out-of-order timestamps. CLI `test db --remote` — fails without local Docker.
