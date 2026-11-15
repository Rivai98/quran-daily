# Data Model: Configurable Daily Portion

## Enum `public.portion_unit`

`juz | half_juz | hizb | quarter | page` with counts 30, 60, 60, 240, 604.
Counts are also asserted in Dart tests from the metadata file; the SQL helper
`public.portion_count(unit)` returns them (these are structural counts, not
Quran text or boundaries; the Dart test proves they match the file).

## `public.groups` (new columns)

| Column | Type | Rule |
|--------|------|------|
| portion_unit | portion_unit not null default 'juz' | current unit |
| pending_portion_unit | portion_unit null | applies at next cycle start |
| unit_era_start_index | int null | day_index where the current unit era began (0 at start_khatma) |
| unit_era_start_portion | smallint null | p0 for the era, 1..N |

`start_juz` stays for backward compatibility (= unit_era_start_portion when
unit is juz); new code reads the era columns.

## `public.group_days` (new columns)

| Column | Type | Rule |
|--------|------|------|
| portion_unit | portion_unit not null default 'juz' | unit of that day |
| cycle_number | int not null default 0 | c |
| cycle_day | smallint not null default 0 | k (0-based) |
| cycle_length | smallint not null default 1 | C |

## `public.assignments`

- Add `portion_index smallint` (1..604), backfilled = `juz`; the existing
  `juz` column check (1..30) is relaxed/kept only for juz days.
- Rest-day seats have no row (FR-007).

## Cycle summary (view or function output)

`get_history` returns cycles: cycle_number, unit, start date, days, N,
completed, late, missed, unread, full_khatma (all portions of the cycle
completed or late).

## Functions (new/changed)

- `portion_count(unit) -> int`
- `portion_for_seat(seat, p0, t, unit) -> int | null` (null = rest day)
- `create_group(..., p_portion_unit default 'juz')`
- `start_khatma(p_group_id, p_start_portion)` (p_start_juz kept as alias)
- `update_group_settings(..., p_portion_unit)` -> sets pending (or immediate while forming)
- `create_day_assignments` uses portion_for_seat; applies pending unit at cycle boundary
- `get_dashboard` adds portion_unit, cycle {number, day, length, completed, total}, pending_portion_unit
- `get_history` / `get_history_day` group by cycle
- `get_invite_preview`, `search_public_groups`, `get_my_groups` add portion_unit
