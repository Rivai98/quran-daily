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
flutter run --dart-define-from-file=.env
flutter test --dart-define-from-file=.env
flutter test integration_test -d <device-id> --dart-define-from-file=.env
```

Without `--dart-define-from-file=.env`, any code that needs Supabase fails
fast on missing configuration instead of falling back to hard-coded values.
Never print, log, or commit the key.

## Backend (Supabase, no Docker)

This project does NOT use a local Supabase stack. Migrations and tests run
against the linked hosted dev project (`zwkvijapswwutwozbvgy`):

```bash
supabase db push --remote          # apply supabase/migrations to the hosted project
supabase db push --remote --dry-run
supabase test db --remote          # pgTAP tests in supabase/tests
```

The owner runs `supabase login` and `supabase link --project-ref zwkvijapswwutwozbvgy`
once per machine; agents never ask for or store the database password or access token.

## Project layout

- `lib/app/` – app shell, bootstrap, router
- `lib/core/` – config, DI, errors, localization, network, storage, sync, design system
- `lib/features/` – feature modules (MVVM: `data/` → `cubit/` → `view/`)
- `assets/quran/` – verified Quran metadata (Tanzil), owner-provided, byte-exact – never modify
- `assets/fonts/` – Cairo (UI) and Amiri (Quran labels), bundled – never modify
- `supabase/` – migrations, Edge Functions, pgTAP tests
- `specs/` – feature specs, plans, contracts, and the task list driving implementation

See `specs/001-track-quran-groups/tasks.md` for the current work list.
