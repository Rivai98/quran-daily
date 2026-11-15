# quran_daily

An Arabic-only Flutter mobile app (Android + iOS) where groups of up to 30
people complete a full Quran khatma every day: each seat reads one juz per day
and the juz rotates by one every day (30 wraps to 1).

Backend: hosted Supabase. UI language: Arabic (RTL). Binding project rules:
[`.specify/memory/constitution.md`](.specify/memory/constitution.md) and the
visual reference [`docs/design/design-system-mock.html`](docs/design/design-system-mock.html).

## Setup

1. Install Flutter stable (Dart `^3.10.4`) and the Supabase CLI v3.
2. Copy the environment template and fill in your project values:

   ```bash
   cp .env.example .env
   ```

   `.env` is gitignored. It holds exactly two keys:

   ```dotenv
   SUPABASE_URL=https://<project-ref>.supabase.co
   SUPABASE_ANON_KEY=sb_publishable_xxx   # publishable key ONLY, never a secret/service key
   ```

3. Fetch dependencies:

   ```bash
   flutter pub get
   ```

## Running and testing with the environment file

The app reads its Supabase configuration from dart-defines. Always pass the
environment file explicitly:

```bash
# Run the app on an attached device or emulator
flutter run -d <device-id> --dart-define-from-file=.env

# Run local unit and widget tests
flutter test

# Run device integration tests
flutter test integration_test/group_flow_test.dart -d <device-id> --dart-define-from-file=.env
flutter test integration_test/offline_completion_test.dart -d <device-id> --dart-define-from-file=.env

# Run the offline journey host entry (runs locally without launching an app or device)
flutter test test/integration_offline_completion_test.dart
```

Without `--dart-define-from-file=.env`, any code that needs Supabase fails
fast on missing configuration instead of falling back to hard-coded values.
Never print, log, or commit the key.

## Backend (Supabase, no Docker)

This project does NOT use a local Supabase stack or Docker. Migrations and tests
run directly against the linked hosted dev project (`zwkvijapswwutwozbvgy`).

Because `supabase test db` requires Docker (which is not used), pgTAP tests run
via the project script:

```bash
python scripts/run_remote_pgtap.py supabase/tests/<file>.sql
# or run all test files:
python scripts/run_remote_pgtap.py supabase/tests/*.sql
```

Applying migrations to the remote database:
`supabase db push` fails with `DbPushMissingLocalError` when parallel branches
push versions out of order. Therefore, apply migrations individually with
`supabase db query` and record the applied version:

```bash
supabase db query --remote --yes -f supabase/migrations/<file>.sql
supabase migration repair --remote --yes --status applied <version>
```

> **Note**: Every hosted Supabase command requires the `--remote --yes` flags in agent/non-interactive workflows.

To view remote migration status:

```bash
supabase migration list --remote
```

The owner runs `supabase login` and `supabase link --project-ref zwkvijapswwutwozbvgy`
once per machine; agents never ask for or store the database password or access token.

## Owner steps still pending

Before public release, the project owner needs to complete the following manual steps:

1. **Seed first admin**: In the Supabase SQL editor, register your auth user id in `private.app_admins` (see `specs/002-email-password-auth/quickstart.md`):
   ```sql
   insert into private.app_admins (user_id) values ('<your auth user id>');
   ```
2. **Deploy Edge Functions**: Deploy the admin Edge Functions with the `--use-api` flag:
   ```bash
   supabase functions deploy admin-create-user --use-api
   supabase functions deploy admin-reset-password --use-api
   ```
3. **Review Quran source**: Confirm the metadata table and source attribution in [`assets/quran/SOURCE.md`](assets/quran/SOURCE.md).

## Project layout

- `lib/app/` – app shell, bootstrap, router
- `lib/core/` – core foundations:
  - `auth/` (`SessionGateway` abstraction)
  - `config/` (`AppConfig` dart-defines loader)
  - `design_system/` (tokens, theme, and shared widgets)
  - `di/` (`service_locator.dart` dependency injection)
  - `errors/` (`Failure`, `FailureKind`, `Result`)
  - `localization/` (`ArabicStrings`, `ArabicNumerals`)
  - `network/` (`RpcClient`, `ConnectivityService`, Supabase provider)
  - `quran/` (`QuranMetadataRepository`, `JuzInfo`)
  - `settings/` (`SettingsRepository`)
  - `storage/` (`LocalDatabase`, DAOs)
  - `sync/` (`SyncOperation`, offline sync queue)
- `lib/features/` – feature modules (MVVM: `data/` → `cubit/` → `view/`):
  - `auth/` (email/password authentication, spec 002)
  - `quran_groups/` (groups, khatma lifecycle, assignments, volunteering, management, history, spec 001)
  - `settings/` (settings screen, font size scaling, sign-out)
- `assets/quran/` – verified Quran metadata (Tanzil), owner-provided, byte-exact – never modify
- `assets/fonts/` – Cairo (UI) and Amiri (Quran labels), bundled – never modify
- `supabase/migrations/` – database migrations with timestamp naming (`20261114000001`..`20261114000007`, `20261115010001`..`20261115060001`)
- `supabase/functions/` – admin Edge Functions (`admin-create-user`, `admin-reset-password`, `_shared`)
- `supabase/tests/` – 10 pgTAP database test files (`000_auth_test.sql` .. `001_us7_history_test.sql`)
- `integration_test/` – device integration journeys (`group_flow_test.dart`, `offline_completion_test.dart`)
- `test/` – unit and widget tests mirroring `lib/`
- `specs/` – feature specs, plans, contracts, and task lists
