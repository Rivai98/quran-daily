-- 004_rotation_jobs (spec 001 US2/T055): every-minute rotation scheduler.
-- pg_cron is created here (not in config.toml, research R16/R3).

create extension if not exists pg_cron;

-- Materialize due group days for every active group (also backfills).
select cron.schedule(
  'quran-daily-generate-days',
  '* * * * *',
  $$select public.generate_due_group_days()$$
);

-- advance_day_states (grace/close transitions + counts) is scheduled from
-- migration 006 (T075) once completion functions exist.
