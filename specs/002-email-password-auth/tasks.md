# Tasks: Email and Password Authentication

**This feature has no separate executable task list.** Its implementation is
tracked in [specs/001-track-quran-groups/tasks.md](../001-track-quran-groups/tasks.md)
**Phase 2B (T025-T034)**, because every spec 001 flow needs a signed-in user.
Check progress and tick boxes there only; this file is a mapping, not a work list.

**Binding rules**: `.specify/memory/constitution.md` v2.4.0.
**Backend**: hosted Supabase `quran-daily` (`zwkvijapswwutwozbvgy`), no Docker; auth settings already configured.

## Mapping: spec 001 task → spec 002 artifact / requirement

| 001 Task | What | Covers (spec 002) |
|----------|------|-------------------|
| T025 | pgTAP tests: profiles trigger, owner-only RLS, `app_admins`/audit protection | FR-003, FR-004, FR-005, FR-015, SC-005; [supabase-backend.md](./contracts/supabase-backend.md) invariants |
| T026 | Migration `supabase/migrations/001_email_password_auth.sql` (profiles, trigger, RLS, `private.app_admins`, `private.admin_auth_audit`) | FR-003-FR-005, FR-015; [data-model.md](./data-model.md) |
| T027 | Edge Functions `admin-create-user`, `admin-reset-password`, `_shared/` | US1 scenario 4, US3, FR-011, FR-019, SC-007 |
| T028 | Repository tests (sign up/in/out, restore, profile, non-revealing errors) | FR-001-FR-002, FR-006, FR-008-FR-009, FR-012 |
| T029 | `AuthCubit` bloc tests | FR-009, FR-010, FR-013, FR-014 |
| T030 | `lib/features/auth/data/` + `AuthRepositoryImpl` (also implements core `SessionGateway`) | [repository-contracts.md](./contracts/repository-contracts.md) |
| T031 | `AuthCubit` + state | Authentication state transitions in data-model |
| T032 | Auth Entry widget tests (modes, validation, LTR email, password clearing, forgot-password guidance, no Google) | FR-007, FR-014, FR-017, FR-018; [ui-contract.md](./contracts/ui-contract.md) |
| T033 | Rebuild Auth Entry screen with design-system widgets | FR-007, FR-018; constitution Principle VI |
| T034 | Startup gate + guarded routes | FR-009, FR-010, FR-012, SC-004 |

## Owner steps (not agent tasks)

1. After the first sign-up in the app, seed yourself as administrator once in the
   Supabase dashboard SQL editor:
   `insert into private.app_admins (user_id) values ('<your auth user id>');`
2. Deploy the functions after T027 lands:
   `supabase functions deploy admin-create-user --use-api` and
   `supabase functions deploy admin-reset-password --use-api`.

## Validation

Follow [quickstart.md](./quickstart.md) after Phase 2B is complete.

## Running 002 on its own branch later

If this feature is ever executed separately (e.g. `002-email-password-auth`
branch), copy T025-T034 from spec 001 into a new task list there and keep the
same order; do not execute them in both places.
