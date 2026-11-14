# Implementation Plan: Email and Password Authentication

**Branch**: implemented on `001-track-quran-groups` (or a dedicated `002-email-password-auth` branch when executed separately) | **Date**: 2026-08-13, updated 2026-11-14 | **Spec**: [spec.md](./spec.md)

**Tasks**: tracked in [specs/001-track-quran-groups/tasks.md](../001-track-quran-groups/tasks.md) Phase 2B (T025-T034); see [tasks.md](./tasks.md) for the mapping. **Constitution**: v2.4.0 (Cairo UI font, design system, Quran integrity). **Backend**: hosted project `zwkvijapswwutwozbvgy`, no Docker (spec 001 research R16).

**Input**: Feature specification from `specs/002-email-password-auth/spec.md`

## Summary

Replace the Google-only authentication placeholder with a simple Arabic email/password flow backed by Supabase Auth. Users can create their own account and sign in from one mobile screen. Supabase creates a private one-to-one application profile for every auth identity. A central session gate restores valid sessions and protects all private routes. Authorized administrators create accounts and replace forgotten passwords through trusted server-side functions; the Flutter app never contains privileged credentials. No verification email, email code, magic link, Google login, device token, or notification behavior is included.

## Technical Context

**Language/Version**: Dart SDK `^3.10.4`; SQL/PLpgSQL for Supabase migrations; TypeScript/Deno runtime for small Supabase Edge Functions.

**Primary Dependencies**: Flutter Material, `flutter_bloc` Cubit, `equatable`, `supabase_flutter`, and `get_it`. Remove `google_sign_in`; add no authentication or notification package.

**Storage**: Supabase Auth owns credentials and sessions. Supabase PostgreSQL stores one `profiles` row per auth user, global application-administrator authorization, and privileged-operation audit records. Existing local storage continues to own cached Quran data and settings; it does not store passwords or custom auth tokens.

**Testing**: `flutter_test`, `bloc_test`, and `mocktail` for unit/widget tests; `integration_test` for device journeys; SQL/migration and Edge Function integration tests against a disposable local or test Supabase project.

**Target Platform**: iOS 15+ and Android API 26+; privileged administrator operations execute server-side rather than inside the mobile client.

**Project Type**: Flutter mobile app with Supabase managed authentication, PostgreSQL, and two authenticated Edge Functions.

**Performance Goals**: Resolve initial authentication state without displaying private content; show successful login/signup destination within 3 seconds on normal connectivity; keep form interaction responsive at 60 fps; handle one in-flight auth submission per screen.

**Constraints**: Arabic-first RTL UI; email field rendered LTR; WCAG 2.1 AA and 48x48 touch targets; test-first MVVM with Cubit; email/password only; minimum eight-character password; no email verification/recovery; no service-role secret in Flutter; no notification work; authentication requires connectivity; cached Quran assignment behavior must not regress.

**Scale/Scope**: One mobile authentication entry surface with login/signup modes, one app-level AuthCubit/session gate, one profile table, one administrator authorization table, two privileged functions, and focused tests. Design supports at least 10,000 accounts without adding custom auth infrastructure.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

### Pre-Research Gate

- **I. Offline-Resilient Core**: PASS. Authentication is an allowed network-backed shared operation. The design does not alter cached assignment access or queue credentials offline.
- **II. Mobile-First UX & Accessibility**: PASS. Arabic RTL phone UI, LTR email input, scalable text, semantic errors, 48x48 targets, and WCAG AA are explicit requirements.
- **III. Test-First**: PASS. Repository, Cubit, widget, routing, migration, function, and device tests precede implementation.
- **IV. MVVM Architecture with Cubit**: PASS. Auth data/repository code remains in `data/`, session/form state in `cubit/`, and widgets in `view/`.
- **V. Simplicity & YAGNI**: PASS. One two-mode auth screen, one Cubit/repository boundary, Supabase-managed sessions, and two narrowly privileged functions are the minimum safe design. OAuth, OTP, notifications, and an in-app admin console are excluded.

### Post-Design Gate

- **I. Offline-Resilient Core**: PASS. Contracts distinguish network-only authentication from the existing offline assignment loop and prohibit manual token caching.
- **II. Mobile-First UX & Accessibility**: PASS. `contracts/ui-contract.md` defines keyboard-safe, Arabic-first, accessible form and routing behavior.
- **III. Test-First**: PASS. `quickstart.md` provides red-green validation across all layers and both mobile platforms.
- **IV. MVVM Architecture with Cubit**: PASS. `contracts/repository-contracts.md` fixes the repository/Cubit/View boundaries and avoids business logic in widgets.
- **V. Simplicity & YAGNI**: PASS. `data-model.md` contains only authentication profiles, administrator authorization, and minimal audit data; notification entities are absent.

## Project Structure

### Documentation (this feature)

```text
specs/002-email-password-auth/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- repository-contracts.md
|   |-- supabase-backend.md
|   `-- ui-contract.md
|-- checklists/
|   `-- requirements.md
`-- tasks.md                 # Mapping to spec 001 Phase 2B (T025-T034)
```

### Source Code (repository root)

```text
lib/
|-- app/
|   |-- app.dart             # Auth bootstrap gate
|   |-- bootstrap.dart       # Supabase + dependency initialization
|   `-- router.dart          # Guarded private navigation
|-- core/
|   |-- config/
|   |-- di/
|   |-- errors/
|   |-- localization/
|   `-- network/
`-- features/
    `-- auth/
        |-- data/
        |   |-- data_sources/
        |   |-- entities/
        |   `-- repositories/
        |-- cubit/
        `-- view/
            `-- widgets/
supabase/
|-- migrations/
|   `-- 001_email_password_auth.sql   # first migration: spec 001's 002_core_schema references profiles
`-- functions/
    |-- _shared/
    |-- admin-create-user/
    `-- admin-reset-password/
test/
|-- features/auth/
|   |-- data/
|   |-- cubit/
|   `-- view/
`-- app/
integration_test/
`-- email_password_auth_flow_test.dart
```

**Structure Decision**: Extend the existing feature-first Flutter application. Authentication owns only identity/session behavior. Supabase migrations and functions are versioned in the repository. Global administrator operations remain server-side; no new mobile admin module is introduced.

## Complexity Tracking

No constitution violations require justification.
