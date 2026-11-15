# Implementation Plan: Configurable Daily Portion (Wird Unit)

**Branch**: `004-portion-units` | **Date**: 2026-11-15 | **Spec**: [spec.md](./spec.md)
**Constitution**: v2.4.0 (binding) | **Builds on**: spec 001 (implemented)

## Summary

Generalize the daily juz rotation to a portion unit chosen by the owner
(juz 30, half juz 60, hizb 60, quarter 240, page 604). A khatma becomes a
cycle of `C = ceil(N/30)` days; within a cycle day k each seat reads the next
block of 30 portions; each new cycle shifts every seat by one. Juz keeps the
exact spec 001 behavior (C = 1, +1 per day).

## Technical Context

Same stack as spec 001: Flutter (Dart ^3.10.4) Android/iOS, MVVM + Cubit,
get_it, hosted Supabase Postgres (RLS + SECURITY DEFINER RPCs, pg_cron),
sqflite cache. Docker-free backend workflow (research R16 of spec 001):
`python scripts/run_remote_pgtap.py` for pgTAP; migrations applied with
`supabase db query --remote --yes -f` + `supabase migration repair`.

## Constitution Check

| Principle | How this feature complies |
|-----------|---------------------------|
| I Offline core | Portion names/ranges come from the bundled metadata file; dashboard cache unchanged |
| II Arabic/RTL | Unit labels, cycle copy in ArabicStrings; numbers via ArabicNumerals |
| III Test-first | pgTAP for the rotation formula per unit; Dart tests for metadata portions, cubits, screens |
| IV MVVM + Cubit | Unit lives in entities/state; widgets only render |
| V Simplicity | One formula, no new tables beyond what cycle tracking needs |
| VI Design system | Unit selector uses existing segmented/choice components |
| VII Quran integrity | Server stores unit + index only; boundaries only from quran-data.xml via QuranMetadataRepository |

Gate: PASS.

## Rotation model (authoritative)

Let N = portion count of the unit, C = ceil(N/30).
For a group, the current **unit era** starts at day index `e` with start
portion `p0` (set on start_khatma or when a pending unit change applies).
For day index d >= e: `t = d - e`, cycle number `c = t div C`, cycle day
`k = t mod C` (0-based), shift `h = (p0 - 1 + c) mod N`.
Seat s (1..30): offset `o = k*30 + (s-1)`; rest day if `o >= N`; else portion
`((h + o) mod N) + 1`.
Juz: N = 30, C = 1 → `((p0-1) + d - e + s - 1) mod 30 + 1` = spec 001 formula.

## Project Structure (changes only)

```text
lib/core/quran/                 PortionUnit, QuranPortion, portions(unit)  [codex-1: 004-portion-metadata]
lib/core/localization/          unit labels, portion names
lib/features/quran_groups/data/ entities: portionUnit on groups/snapshot, portionIndex on Assignment, CycleInfo
lib/features/quran_groups/cubit create_group (unit), dashboard (cycle), group_settings (pending unit), history (cycles)
lib/features/quran_groups/view/ create form selector, dashboard cycle header + portion card, history by cycle,
                                settings unit change, unit chip on cards/preview
supabase/migrations/2026111509NNNN_portion_units*.sql
supabase/tests/004_portion_units_test.sql
```

## Data model

See [data-model.md](./data-model.md).

## Risks

- Seat tiles currently label juz numbers: must render portion names from metadata.
- History full_khatma moves from day to cycle; juz groups must keep identical
  results (SC-003).
- Pending unit change must apply exactly at a cycle boundary inside
  `ensure_current_group_day` / `generate_due_group_days`.
