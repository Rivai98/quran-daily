-- Profile tab function (FR-011): personal stats, streaks, khatmas and badges.
-- All metrics computed server-side from assignments and group_days.
create or replace function public.get_my_profile()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_display_name text;
  v_member_since date;
  v_streak int := 0;
  v_best int := 0;
  v_run int := 0;
  v_portions_read int := 0;
  v_portions_late int := 0;
  v_date date;
  v_complete boolean;
  v_earned_streak_7 date;
  v_earned_streak_30 date;
  v_earned_streak_100 date;
  v_earned_first_khatma date;
  v_earned_portions_100 date;
  v_khatmas jsonb;
  v_badges jsonb;
begin
  v_uid := public.require_auth_uid();

  -- Profile info
  select coalesce(p.display_name, ''), p.created_at::date
  into v_display_name, v_member_since
  from public.profiles p
  where p.id = v_uid;

  if not found then
    v_display_name := '';
    v_member_since := current_date;
  end if;

  -- Totals: portions_read (completed + late) and portions_late
  select
    coalesce(count(*) filter (where a.status in ('completed', 'late')), 0)::int,
    coalesce(count(*) filter (where a.status = 'late'), 0)::int
  into v_portions_read, v_portions_late
  from public.assignments a
  join public.group_memberships m on m.id = a.reader_membership_id
  where m.user_id = v_uid;

  -- 1. Current streak (counting backwards from today / latest day with items)
  -- FR-010: late keeps the streak, missed breaks it, days without assignments are skipped
  for v_date, v_complete in
    select d.group_date, bool_and(a.status in ('completed', 'late'))
    from public.assignments a
    join public.group_days d on d.id = a.group_day_id
    join public.group_memberships m on m.id = a.reader_membership_id
    where m.user_id = v_uid and d.group_date <= current_date
    group by d.group_date
    order by d.group_date desc
  loop
    if v_complete then
      v_streak := v_streak + 1;
    else
      exit;
    end if;
  end loop;

  -- 2. Best streak and streak badge dates (iterating forwards)
  for v_date, v_complete in
    select d.group_date, bool_and(a.status in ('completed', 'late'))
    from public.assignments a
    join public.group_days d on d.id = a.group_day_id
    join public.group_memberships m on m.id = a.reader_membership_id
    where m.user_id = v_uid and d.group_date <= current_date
    group by d.group_date
    order by d.group_date asc
  loop
    if v_complete then
      v_run := v_run + 1;
      if v_run = 7 and v_earned_streak_7 is null then
        v_earned_streak_7 := v_date;
      end if;
      if v_run = 30 and v_earned_streak_30 is null then
        v_earned_streak_30 := v_date;
      end if;
      if v_run = 100 and v_earned_streak_100 is null then
        v_earned_streak_100 := v_date;
      end if;
      v_best := greatest(v_best, v_run);
    else
      v_run := 0;
    end if;
  end loop;

  -- 3. Khatmas per group
  -- Groups where user has or had memberships, counting distinct completed cycles where full_khatma is true and user participated
  with khatma_counts as (
    select
      g.id as group_id,
      g.name as group_name,
      count(distinct d.cycle_number)::int as completed,
      min(d.group_date) as first_khatma_date
    from public.groups g
    join public.group_memberships m on m.group_id = g.id and m.user_id = v_uid
    join public.group_days d on d.group_id = g.id and d.full_khatma = true
    where exists (
      select 1 from public.assignments a
      join public.group_memberships am on am.id = a.reader_membership_id
      where a.group_day_id = d.id and am.user_id = v_uid and a.status in ('completed', 'late')
    )
    group by g.id, g.name
  )
  select
    coalesce(jsonb_agg(
      jsonb_build_object(
        'group_id', kc.group_id,
        'group_name', kc.group_name,
        'completed', kc.completed
      ) order by kc.completed desc, kc.group_name
    ), '[]'::jsonb),
    min(kc.first_khatma_date)
  into v_khatmas, v_earned_first_khatma
  from khatma_counts kc;

  -- 4. Portions 100 badge date
  if v_portions_read >= 100 then
    select d.group_date into v_earned_portions_100
    from public.assignments a
    join public.group_days d on d.id = a.group_day_id
    join public.group_memberships m on m.id = a.reader_membership_id
    where m.user_id = v_uid and a.status in ('completed', 'late')
    order by d.group_date asc, a.completed_at asc nulls last, a.id asc
    offset 99 limit 1;
    if v_earned_portions_100 is null then
      v_earned_portions_100 := current_date;
    end if;
  end if;

  -- 5. Construct badges array
  with raw_badges as (
    select 'first_khatma' as code, v_earned_first_khatma as earned_at
    where v_earned_first_khatma is not null
    union all
    select 'streak_7' as code, v_earned_streak_7 as earned_at
    where v_earned_streak_7 is not null
    union all
    select 'streak_30' as code, v_earned_streak_30 as earned_at
    where v_earned_streak_30 is not null
    union all
    select 'streak_100' as code, v_earned_streak_100 as earned_at
    where v_earned_streak_100 is not null
    union all
    select 'portions_100' as code, v_earned_portions_100 as earned_at
    where v_earned_portions_100 is not null
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object('code', rb.code, 'earned_at', rb.earned_at)
      order by rb.earned_at asc, rb.code asc
    ),
    '[]'::jsonb
  )
  into v_badges
  from raw_badges rb;

  return jsonb_build_object(
    'display_name', v_display_name,
    'member_since', v_member_since,
    'streak', v_streak,
    'best_streak', v_best,
    'portions_read', v_portions_read,
    'portions_late', v_portions_late,
    'khatmas', coalesce(v_khatmas, '[]'::jsonb),
    'badges', coalesce(v_badges, '[]'::jsonb)
  );
end;
$$;

revoke all on function public.get_my_profile() from public, anon;
grant execute on function public.get_my_profile() to authenticated;
