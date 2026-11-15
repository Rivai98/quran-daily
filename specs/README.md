# Specs roadmap

Owner update 2026-11-15: all remaining specs are built in parallel, each on its own branch, merged to `main` after testing. Each spec goes through:
specify → clarify (owner answers) → plan → tasks → implement → validate → merge to `main`.
The next spec starts only after the current one is merged to `main`.

| # | Spec | Branch | Status |
|---|------|--------|--------|
| 001 | [Track Quran groups (core app)](001-track-quran-groups/spec.md) | `001-track-quran-groups` | ✅ Implemented, in `main` |
| 002 | [Email/password auth](002-email-password-auth/spec.md) | (code inside 001) | ✅ Implemented, in `main` |
| 004 | [Daily portion units](004-portion-units/spec.md) | `004-portion-units` | ✅ Implemented, in `main` |
| 002+ | [Google sign-in (amendment to 002)](002-email-password-auth/spec.md) | `002-google-signin` | ✅ Implemented, in `main` |
| 003 | [In-app Mushaf](003-in-app-mushaf/spec.md) | `003-in-app-mushaf` | 🔨 Current: clarified + planned; waiting for source files |
| 005 | [Home, tabs, daily log](005-home-today/spec.md) | `005-home-today` | 🔨 In progress (4 tabs + profile) |
| 006 | [Daily reminders](006-daily-reminders/spec.md) | `006-daily-reminders` | 🔨 Clarified + planned |
| 007 | [Who read, profiles, group info](007-reader-visibility-profiles/spec.md) | `007-reader-visibility-profiles` | 🔨 Clarified + planned |
| 008 | [Admin console](008-admin-console/spec.md) | `008-admin-console` | 🔨 Clarified + planned |

Notes:
- 003 is numbered before 004 because it was reserved early; 004 was built first at the owner's request.
- Draft specs live here so the whole roadmap is visible in `main`; only the spec in progress gets implemented.
