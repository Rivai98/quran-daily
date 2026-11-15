-- Spec 006: owner-set group reminder schedule (local on-device reminders).
-- Members read the schedule; only the group owner writes it, and only through
-- set_group_reminder_schedule (no direct client writes, as for other tables).

create table public.group_reminder_schedules (
  group_id uuid primary key references public.groups (id) on delete cascade,
  fajr_on boolean not null default true,
  fajr_offset_min smallint not null default 20
    check (fajr_offset_min between 0 and 180),
  asr_on boolean not null default true,
  asr_offset_min smallint not null default 20
    check (asr_offset_min between 0 and 180),
  night_on boolean not null default true,
  night_time time not null default '22:30',
  message text check (char_length(message) between 1 and 80),
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.group_reminder_schedules enable row level security;

create policy group_reminder_schedules_select_member
  on public.group_reminder_schedules for select to authenticated
  using (public.is_active_member(group_id));

revoke all on public.group_reminder_schedules from public, anon, authenticated;
grant select on public.group_reminder_schedules to authenticated;

-- Internal JSON shape shared by the RPC and the read models.
-- Returns SQL null when the owner has not set a schedule.
create or replace function public.group_reminder_schedule_json(p_group_id uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'group_id', s.group_id,
    'fajr_on', s.fajr_on,
    'fajr_offset_min', s.fajr_offset_min,
    'asr_on', s.asr_on,
    'asr_offset_min', s.asr_offset_min,
    'night_on', s.night_on,
    'night_time', to_char(s.night_time, 'HH24:MI'),
    'message', s.message,
    'updated_at', s.updated_at)
  from public.group_reminder_schedules s
  where s.group_id = p_group_id;
$$;
revoke all on function public.group_reminder_schedule_json(uuid) from public, anon, authenticated;

create or replace function public.set_group_reminder_schedule(
  p_group_id uuid,
  p_fajr_on boolean,
  p_fajr_offset_min integer,
  p_asr_on boolean,
  p_asr_offset_min integer,
  p_night_on boolean,
  p_night_time text,
  p_message text default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_message text;
begin
  v_uid := public.require_auth_uid();
  if not exists (select 1 from public.groups where id = p_group_id) then
    raise exception 'group_not_found' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.group_memberships m
    where m.group_id = p_group_id and m.user_id = v_uid
      and m.status = 'active' and m.role = 'owner') then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  v_message := nullif(btrim(coalesce(p_message, '')), '');
  if p_fajr_on is null or p_asr_on is null or p_night_on is null
    or p_fajr_offset_min is null or p_fajr_offset_min not between 0 and 180
    or p_asr_offset_min is null or p_asr_offset_min not between 0 and 180
    or p_night_time is null
    or p_night_time !~ '^([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$'
    or char_length(coalesce(v_message, '')) > 80 then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  insert into public.group_reminder_schedules as s (
    group_id, fajr_on, fajr_offset_min, asr_on, asr_offset_min,
    night_on, night_time, message, updated_by, updated_at)
  values (p_group_id, p_fajr_on, p_fajr_offset_min, p_asr_on, p_asr_offset_min,
    p_night_on, p_night_time::time, v_message, v_uid, now())
  on conflict (group_id) do update set
    fajr_on = excluded.fajr_on,
    fajr_offset_min = excluded.fajr_offset_min,
    asr_on = excluded.asr_on,
    asr_offset_min = excluded.asr_offset_min,
    night_on = excluded.night_on,
    night_time = excluded.night_time,
    message = excluded.message,
    updated_by = excluded.updated_by,
    updated_at = excluded.updated_at;

  return public.group_reminder_schedule_json(p_group_id);
end $$;
revoke all on function public.set_group_reminder_schedule(uuid, boolean, integer, boolean, integer, boolean, text, text) from public, anon;
grant execute on function public.set_group_reminder_schedule(uuid, boolean, integer, boolean, integer, boolean, text, text) to authenticated;
