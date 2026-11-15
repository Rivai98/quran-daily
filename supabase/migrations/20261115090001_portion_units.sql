-- Configurable structural reading units. No Quran text or boundaries are stored.
create type public.portion_unit as enum ('juz', 'half_juz', 'hizb', 'quarter', 'page');

alter table public.groups
  add column portion_unit public.portion_unit not null default 'juz',
  add column pending_portion_unit public.portion_unit,
  add column unit_era_start_index int,
  add column unit_era_start_portion smallint;

alter table public.group_days
  add column portion_unit public.portion_unit not null default 'juz',
  add column cycle_number int not null default 0,
  add column cycle_day smallint not null default 0,
  add column cycle_length smallint not null default 1;

alter table public.assignments add column portion_index smallint;
update public.assignments set portion_index = juz;
alter table public.assignments alter column portion_index set not null;
alter table public.assignments add constraint assignments_portion_index_range
  check (portion_index between 1 and 604);
drop index public.assignments_unique_juz_per_day;
create unique index assignments_unique_portion_per_day
  on public.assignments(group_day_id, portion_index);

create or replace function public.portion_count(p_unit public.portion_unit)
returns int language sql immutable security definer set search_path = '' as $$
  select case p_unit when 'juz' then 30 when 'half_juz' then 60
    when 'hizb' then 60 when 'quarter' then 240 when 'page' then 604 end;
$$;
revoke all on function public.portion_count(public.portion_unit) from public, anon;
grant execute on function public.portion_count(public.portion_unit) to authenticated;

create or replace function public.portion_for_seat(
  p_seat int, p_start_portion int, p_day_offset int, p_unit public.portion_unit)
returns int language sql immutable security definer set search_path = '' as $$
  with unit_data as (
    select public.portion_count(p_unit) as n,
      ((public.portion_count(p_unit) + 29) / 30) as cycle_len
  ), offsets as (
    select n, cycle_len,
      (p_day_offset % cycle_len) * 30 + (p_seat - 1) as seat_offset,
      (p_day_offset / cycle_len) as cycle_number
    from unit_data
  )
  select case when p_seat not between 1 and 30 or p_start_portion not between 1 and n
      or p_day_offset < 0 or seat_offset >= n then null
    else (((p_start_portion - 1 + cycle_number + seat_offset) % n) + 1)
  end from offsets;
$$;
revoke all on function public.portion_for_seat(int,int,int,public.portion_unit) from public, anon;
grant execute on function public.portion_for_seat(int,int,int,public.portion_unit) to authenticated;

-- Additive overload; the original six-argument RPC remains unchanged.
create or replace function public.create_group(
  p_name text, p_short_description text, p_timezone text,
  p_day_start_time time, p_visibility public.group_visibility,
  p_join_mode public.join_mode, p_portion_unit public.portion_unit default 'juz')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_result jsonb;
begin
  v_result := public.create_group(p_name, p_short_description, p_timezone,
    p_day_start_time, p_visibility, p_join_mode);
  update public.groups set portion_unit = coalesce(p_portion_unit, 'juz')
    where id = (v_result->>'group_id')::uuid;
  return v_result || jsonb_build_object('portion_unit', coalesce(p_portion_unit, 'juz'));
end;
$$;
revoke all on function public.create_group(text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) from public, anon;
grant execute on function public.create_group(text,text,text,time,public.group_visibility,public.join_mode,public.portion_unit) to authenticated;

-- Existing p_start_juz remains the start portion argument for all units.
create or replace function public.start_khatma(p_group_id uuid, p_start_juz int default 1)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_group public.groups; v_members int; v_day_id uuid; v_n int;
begin
  v_uid := public.require_auth_uid();
  select * into v_group from public.groups where id=p_group_id for update;
  if not found then raise exception 'group_not_found' using errcode='P0001'; end if;
  if v_group.owner_id <> v_uid then raise exception 'forbidden' using errcode='P0001'; end if;
  if v_group.status <> 'forming' then raise exception 'group_not_forming' using errcode='P0001'; end if;
  v_n := public.portion_count(v_group.portion_unit);
  if p_start_juz is null or p_start_juz < 1 or p_start_juz > v_n then
    raise exception 'validation_failed' using errcode='P0001';
  end if;
  select count(*) into v_members from public.group_memberships where group_id=p_group_id and status='active';
  if v_members < 1 then raise exception 'validation_failed' using errcode='P0001'; end if;
  update public.groups set status='active', start_juz=case when v_group.portion_unit='juz' then p_start_juz else 1 end,
    start_date=public.group_local_date(p_group_id,now()), unit_era_start_index=0,
    unit_era_start_portion=p_start_juz where id=p_group_id;
  v_day_id := public.ensure_current_group_day(p_group_id);
  return jsonb_build_object('group_id',v_group.id,'group_name',v_group.name,'my_role','owner',
    'status','active','server_generated_at',now(),'active_member_count',v_members,
    'invite_code',v_group.invite_code,'today',true);
end;
$$;
revoke all on function public.start_khatma(uuid,int) from public, anon;
grant execute on function public.start_khatma(uuid,int) to authenticated;

create or replace function public.create_day_assignments(p_day_id uuid,p_group_id uuid,p_day_index int)
returns void language plpgsql security definer set search_path = '' as $$
declare v_group public.groups; v_day public.group_days; v_start int; v_offset int; v_cycle int; v_len int; v_n int;
begin
  select * into v_group from public.groups where id=p_group_id;
  select * into v_day from public.group_days where id=p_day_id;
  v_start := coalesce(v_group.unit_era_start_portion, v_group.start_juz, 1);
  v_offset := greatest(0, p_day_index - coalesce(v_group.unit_era_start_index, 0));
  v_n := public.portion_count(v_group.portion_unit); v_len := (v_n + 29) / 30;
  v_cycle := v_offset / v_len;
  update public.group_days set portion_unit=v_group.portion_unit, cycle_number=v_cycle,
    cycle_day=(v_offset % v_len), cycle_length=v_len where id=p_day_id;
  insert into public.assignments(group_day_id,juz,portion_index,seat_number,kind,reader_membership_id,status)
  select p_day_id, (((p.portion_index-1)%30)+1)::smallint, p.portion_index::smallint,
    s::smallint, case when m.id is null then 'unassigned' else 'seat' end::public.assignment_kind,
    m.id, case when m.id is null then 'available' else 'pending' end::public.assignment_status
  from generate_series(1,30) s
  cross join lateral (select public.portion_for_seat(s,v_start,v_offset,v_group.portion_unit) portion_index) p
  left join public.group_memberships m on m.group_id=p_group_id and m.seat_number=s and m.status='active'
  where p.portion_index is not null
  on conflict(group_day_id,seat_number) do nothing;
end;
$$;

create or replace function public.ensure_current_group_day(p_group_id uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_group public.groups; v_today date; v_last date; v_day_id uuid; v_idx int; v_missing date;
  v_n int; v_len int; v_offset int;
begin
  select * into v_group from public.groups where id=p_group_id for update;
  if not found or v_group.status <> 'active' then return null; end if;
  v_today := public.group_local_date(p_group_id,now());
  select max(group_date) into v_last from public.group_days where group_id=p_group_id;
  if v_last >= v_today then
    select id into v_day_id from public.group_days where group_id=p_group_id and group_date=v_today;
    if v_day_id is not null then return v_day_id; end if;
  end if;
  v_missing := coalesce(v_last,v_today-1);
  while v_missing < v_today loop
    v_missing := v_missing+1; v_idx := v_missing-v_group.start_date;
    if v_group.pending_portion_unit is not null and v_group.unit_era_start_index is not null then
      v_n := public.portion_count(v_group.portion_unit); v_len := (v_n+29)/30;
      v_offset := v_idx-v_group.unit_era_start_index;
      if v_offset > 0 and v_offset % v_len = 0 then
        v_group.portion_unit := v_group.pending_portion_unit;
        v_group.pending_portion_unit := null;
        v_group.unit_era_start_index := v_idx;
        v_group.unit_era_start_portion := 1;
        update public.groups set portion_unit=v_group.portion_unit,pending_portion_unit=null,
          unit_era_start_index=v_idx,unit_era_start_portion=1 where id=p_group_id;
      end if;
    end if;
    insert into public.group_days(group_id,group_date,day_index,opens_at,ends_at,closes_at,state)
    values(p_group_id,v_missing,v_idx,v_missing::timestamptz+v_group.day_start_time,
      (v_missing+1)::timestamptz+v_group.day_start_time,(v_missing+2)::timestamptz+v_group.day_start_time,
      case when v_missing<v_today then 'closed'::public.day_state else 'open'::public.day_state end)
    on conflict(group_id,group_date) do nothing returning id into v_day_id;
    if v_day_id is not null then
      perform public.create_day_assignments(v_day_id,p_group_id,v_idx);
      if v_missing<v_today then perform public.freeze_day_states(v_day_id,'closed'); end if;
    end if;
  end loop;
  select id into v_day_id from public.group_days where group_id=p_group_id and group_date=v_today;
  return v_day_id;
end;
$$;
revoke all on function public.ensure_current_group_day(uuid), public.create_day_assignments(uuid,uuid,int) from public, anon;
grant execute on function public.ensure_current_group_day(uuid), public.create_day_assignments(uuid,uuid,int) to authenticated;

create or replace function public.recompute_day_counts(p_day_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_day public.group_days; v_n int;
begin
  select * into v_day from public.group_days where id=p_day_id;
  update public.group_days d set completed_count=c.completed,late_count=c.late,missed_count=c.missed,
    unread_count=c.unread,pending_count=c.pending,available_count=c.available,
    full_khatma=case when d.cycle_length=1 then c.completed+c.late=public.portion_count(d.portion_unit)
      else false end
  from (select count(*) filter(where status='completed')::smallint completed,
      count(*) filter(where status='late')::smallint late,count(*) filter(where status='missed')::smallint missed,
      count(*) filter(where status='unread')::smallint unread,count(*) filter(where status='pending')::smallint pending,
      count(*) filter(where status='available')::smallint available
    from public.assignments where group_day_id=p_day_id) c where d.id=p_day_id;
  if v_day.cycle_day=v_day.cycle_length-1 then
    v_n := public.portion_count(v_day.portion_unit);
    update public.group_days d set full_khatma=(select count(distinct a.portion_index)=v_n
      from public.group_days days join public.assignments a on a.group_day_id=days.id
      where days.group_id=v_day.group_id and days.cycle_number=v_day.cycle_number
        and days.portion_unit=v_day.portion_unit and a.status in ('completed','late'))
      where d.group_id=v_day.group_id and d.cycle_number=v_day.cycle_number;
  end if;
end;
$$;
revoke all on function public.recompute_day_counts(uuid) from public, anon;
grant execute on function public.recompute_day_counts(uuid) to authenticated;

revoke all on function public.generate_due_group_days() from public, anon;
grant execute on function public.generate_due_group_days() to authenticated;
