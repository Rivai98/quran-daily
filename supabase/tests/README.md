# Supabase Database Tests (pgTAP)

This directory contains database test suites written in pgTAP to validate PostgreSQL schemas, RLS policies, functions, constraints, and triggers against the hosted Supabase DEV project (`zwkvijapswwutwozbvgy`).

## Running Tests Without Docker

The official Supabase CLI `supabase test db` command requires a local Docker daemon even when passed `--remote`. Because this project avoids local Docker dependencies (see `research.md` R16), tests run remotely via the Python test runner:

```bash
# Run all 10 pgTAP test suites
python scripts/run_remote_pgtap.py supabase/tests/*.sql

# Run an individual test suite
python scripts/run_remote_pgtap.py supabase/tests/001_schema_test.sql
```

### How `run_remote_pgtap.py` Works

1. Begins a transaction on the remote database.
2. Creates the `pgtap` extension in-transaction and grants permissions to `authenticated` and `anon` roles.
3. Buffers all assertion outputs (`ok`, `is`, `throws_ok`, etc.) in a temporary table.
4. Returns and evaluates TAP assertion lines, rolling back the transaction so test runs leave no residue.
5. All hosted queries use `--remote --yes`.

## Test Suites

The test suite consists of 10 test files mapping to architecture foundations and user stories:

| File | Story / Purpose | What It Covers |
|---|---|---|
| `000_auth_test.sql` | Spec 002 Auth | Profile triggers, trim rules, RLS, `private.app_admins`, and `private.admin_auth_audit`. |
| `001_rls_test.sql` | Privacy & RLS | Member read policies; non-member read blocks; write prohibitions. |
| `001_schema_test.sql` | Schema & Rotation | `juz_for_seat` deterministic rotation, seat boundaries (1–30), table constraints. |
| `001_us1_dashboard_test.sql` | US1 Dashboard | Dashboard RPC, wird calculation, status mapping, khatma percentage. |
| `001_us2_lifecycle_test.sql` | US2 Lifecycle | Group creation, starting khatma, `generate_due_group_days()`, rollover idempotency. |
| `001_us3_completion_test.sql` | US3 Completion | Marking complete, undo, grace period transitions, late completions, day closure. |
| `001_us4_join_test.sql` | US4 Join Flows | Join by invite code, auto-accept vs approval, `join_any_group`, full group blocks. |
| `001_us5_volunteer_test.sql` | US5 Volunteering | Available juz claiming, concurrent volunteer race condition safety (SC-006). |
| `001_us6_manage_test.sql` | US6 Management | Request review, seat swap, member removal, leave, transfer ownership, today-only override. |
| `001_us7_history_test.sql` | US7 History | Paged history, regular member privacy vs owner/supervisor detail, full khatma flags. |
| `007_reader_visibility_test.sql` | Spec 007 Readers | `reader` attribution on dashboard/history, member vs owner/supervisor visibility of misses, no email. |
| `007_profiles_group_info_test.sql` | Spec 007 Profiles | `get_group_info`, `get_member_profile` (co-members only), `update_my_profile`, owner-only group details/photo. |
| `007_group_photos_storage_test.sql` | Spec 007 Storage | `group-photos` bucket limits and storage.objects policies (members read, owner writes). |

### Helpers

- `helpers/seed_members.sql`: Helper fixture for test-only seeding of active memberships.

## Remote Migrations Workflow

When applying new migrations to the hosted DEV environment:
Do not use `supabase db push` (parallel git branches push versions out of order, leading to `DbPushMissingLocalError`). Apply explicitly:

```bash
supabase db query --remote --yes -f supabase/migrations/<file>.sql
supabase migration repair --remote --yes --status applied <version>
```
