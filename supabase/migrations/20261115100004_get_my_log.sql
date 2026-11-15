create function public.get_my_log(p_before date default null,p_days int default 30) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare v_uid uuid; v_cutoff date; v_streak int:=0; v_best int:=0; v_run int:=0;
  v_complete boolean; v_date date; v_days jsonb; v_next date; v_year int; v_month int;
  v_full int; v_with_items int;
begin
  v_uid:=public.require_auth_uid();
  if p_days is null or p_days<1 or p_days>100 then raise exception 'validation_failed' using errcode='P0001'; end if;
  v_cutoff:=coalesce(p_before,current_date+1);
  for v_date,v_complete in
    select d.group_date,bool_and(a.status in ('completed','late'))
    from public.assignments a join public.group_days d on d.id=a.group_day_id
      join public.group_memberships m on m.id=a.reader_membership_id
    where m.user_id=v_uid and d.group_date<=current_date
    group by d.group_date order by d.group_date desc
  loop
    if v_complete then v_streak:=v_streak+1; else exit; end if;
  end loop;
  for v_date,v_complete in
    select d.group_date,bool_and(a.status in ('completed','late'))
    from public.assignments a join public.group_days d on d.id=a.group_day_id
      join public.group_memberships m on m.id=a.reader_membership_id
    where m.user_id=v_uid and d.group_date<=current_date
    group by d.group_date order by d.group_date
  loop
    if v_complete then v_run:=v_run+1; v_best:=greatest(v_best,v_run); else v_run:=0; end if;
  end loop;

  v_year:=extract(year from current_date)::int; v_month:=extract(month from current_date)::int;
  -- Aggregate the month's per-day completion flags and item-bearing days.
  select coalesce(sum(x.full_day),0)::int,coalesce(sum(x.has_items),0)::int into v_full,v_with_items
  from (select (bool_and(a.status in ('completed','late')))::int full_day,1 has_items
    from public.assignments a join public.group_days d on d.id=a.group_day_id
      join public.group_memberships m on m.id=a.reader_membership_id
    where m.user_id=v_uid and extract(year from d.group_date)=v_year and extract(month from d.group_date)=v_month
    group by d.group_date) x;

  with day_rows as (
    select d.group_date as day_date,jsonb_agg(jsonb_build_object(
      'group_id',g.id,'group_name',g.name,'portion_unit',d.portion_unit,
      'portion_index',a.portion_index,'kind',a.kind,'status',a.status,
      'completed_at',a.completed_at,'group_day_id',d.id) order by g.name,a.seat_number,a.id) items,
      bool_and(a.status in ('completed','late')) complete
    from public.assignments a join public.group_days d on d.id=a.group_day_id
      join public.group_memberships m on m.id=a.reader_membership_id
      join public.groups g on g.id=d.group_id
    where m.user_id=v_uid and d.group_date<v_cutoff
    group by d.group_date
  ), page as (
    select * from day_rows order by day_date desc limit p_days
  )
  select coalesce(jsonb_agg(jsonb_build_object('date',day_date,'complete',complete,'items',items)
      order by day_date desc),'[]'::jsonb),
      (select min(day_date) from page p where exists(select 1 from day_rows older where older.day_date<p.day_date))
    into v_days,v_next from page;

  return jsonb_build_object('streak',v_streak,'best_streak',v_best,
    'month',jsonb_build_object('year',v_year,'month',v_month,'full_days',coalesce(v_full,0),'days_with_items',coalesce(v_with_items,0)),
    'days',coalesce(v_days,'[]'::jsonb),'next_before',v_next);
end $$;
revoke all on function public.get_my_log(date,int) from public,anon;
grant execute on function public.get_my_log(date,int) to authenticated;
