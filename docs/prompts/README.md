# Prompts - status and run order

Every agent must read `.specify/memory/constitution.md` (v2.4.0) first.

| File | Status | Purpose |
|------|--------|---------|
| `zcode-implement-001.md` | **Ready - use next** | ZCode prompt to implement spec 001 (includes design system and spec 002 auth) |
| `01-amend-001-group-lifecycle.md` | Done (2026-11-14) | Input used to amend spec 001; specify, clarify, plan, tasks, analyze completed |
| `02-new-003-mushaf.md` | Pending | `/speckit-specify` input for spec 003 (Mushaf) |
| `03-new-004-design-system.md` | Superseded | Design system foundation is now Phase 2A of spec 001 tasks; do not run |

## Order

1. Implement spec 001 with `zcode-implement-001.md` (Phases 1-5 = MVP, then 6-10).
   - Phase 2A builds the design system (Principle VI).
   - Phase 2B implements spec 002 (email/password auth); spec 002 has no separate tasks.md.
2. Specify spec 003 (Mushaf) with `02-new-003-mushaf.md`, then clarify, plan, tasks, analyze.
3. Implement spec 003.

## Owner-provided files (agents must never create them)

- `assets/fonts/`: Cairo and Amiri TTF files (Google Fonts, OFL).
- `assets/quran/`: Tanzil `quran-data.xml`, `SOURCE.md`, `checksums.sha256`.

## One feature per branch

Each spec has its own branch (`001-...`, `003-...`) so it can be reviewed and merged separately.
