# Spec Kit prompts - run order

Ready-to-paste inputs for Spec Kit / Codex. Every agent must read
`.specify/memory/constitution.md` (v2.2.0) first.

| # | File | Spec | What it does |
|---|------|------|--------------|
| 1 | `01-amend-001-group-lifecycle.md` | 001 (update) | Anyone creates groups (max 3), 30 seats, automatic daily rotation, vacant seats with volunteering, invite links, owner/supervisor roles |
| 2 | `03-new-004-design-system.md` | 004 (new) | Builds `lib/core/design_system/` and migrates current screens |
| 3 | `02-new-003-mushaf.md` | 003 (new) | In-app Mushaf opening on today's juz, offline, verified source |

## Recommended order

1. **Specify all three** (docs only, cheap): 001 amend -> 004 -> 003.
   Run `/speckit-clarify`, `/speckit-plan`, `/speckit-tasks`, `/speckit-analyze`
   for each.
2. **Implement** in this order:
   1. 004 design system (every later screen depends on it)
   2. 002 email/password auth (plan already exists; run `/speckit-tasks` first)
   3. 001 groups, rotation, dashboard
   4. 003 Mushaf

## Before implementing 003

Download the Quran source files yourself from the official source chosen in
the 003 plan, check the license, and place them under `assets/quran/` with
`SOURCE.md`. Agents must never create these files themselves.

## One feature per branch

Create a branch per spec (`001-...`, `003-...`, `004-...`) so each one can be
reviewed and merged separately.
