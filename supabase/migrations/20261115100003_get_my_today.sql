create function public.get_my_today() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid; v_pin uuid; v_main uuid; v_groups jsonb; v_g record; v_day public.group_days;
  v_items jsonb; v_total int; v_done int; v_rest boolean;
begin
  v_uid:=public.require_auth_uid();
  select main_group_id into v_pin from public.profiles where id=v_uid;
  select m.group_id into v_main
  from public.group_memberships m join public.groups g on g.id=m.group_id
  where m.user_id=v_uid and m.status='active' and g.status<>'archived'
  order by (m.group_id=v_pin) desc, m.last_opened_at desc nulls last, m.joined_at, m.group_id limit 1;

  for v_g in select g.id,g.name,g.status,g.portion_unit,m.role,m.seat_number,
      (m.group_id=v_main) as is_main
    from public.group_memberships m join public.groups g on g.id=m.group_id
    where m.user_id=v_uid and m.status='active' and g.status<>'archived'
    order by (m.group_id=v_main) desc,m.last_opened_at desc nulls last,m.joined_at,m.group_id
  loop
    v_items:='[]'::jsonb; v_rest:=false;
    if v_g.status='active' then
      perform public.ensure_current_group_day(v_g.id);
      select * into v_day from public.group_days d where d.group_id=v_g.id
        and d.group_date=public.group_local_date(v_g.id,now());
      if found then
        select coalesce(jsonb_agg(jsonb_build_object(
          'assignment_id',a.id,'kind',a.kind,'seat_number',a.seat_number,
          'portion_index',a.portion_index,'status',a.status,'completed_at',a.completed_at,
          'can_undo',a.status in ('completed','late')) order by a.seat_number,a.id),'[]'::jsonb)
          into v_items
        from public.assignments a join public.group_memberships rm on rm.id=a.reader_membership_id
        where a.group_day_id=v_day.id and rm.user_id=v_uid and a.kind in ('seat','override','volunteer');
        select count(*)::int,count(*) filter(where a.status in ('completed','late'))::int
          into v_total,v_done from public.assignments a where a.group_day_id=v_day.id;
        v_rest:=v_g.portion_unit='page' and jsonb_array_length(v_items)=0;
      end if;
    end if;
    select coalesce(v_groups,'[]'::jsonb) || jsonb_build_array(jsonb_build_object(
      'group_id',v_g.id,'name',v_g.name,'role',v_g.role,'status',v_g.status,
      'portion_unit',v_g.portion_unit,'is_main',v_g.is_main,
      'day',case when v_g.status<>'active' or v_day.id is null then null else jsonb_build_object(
        'group_date',v_day.group_date,'day_index',v_day.day_index,'state',v_day.state,
        'ends_at',v_day.ends_at,'closes_at',v_day.closes_at,'cycle_number',v_day.cycle_number,
        'cycle_day',v_day.cycle_day,'cycle_length',v_day.cycle_length,
        'completed_count',v_done,'total_count',v_total,'rest_day',v_rest) end,
      'items',v_items)) into v_groups;
    v_day:=null; v_total:=0; v_done:=0;
  end loop;
  return jsonb_build_object('server_generated_at',now(),'main_group_id',v_main,
    'membership_count',public.active_membership_count(v_uid),'membership_limit',2,
    'groups',coalesce(v_groups,'[]'::jsonb));
end $$;
revoke all on function public.get_my_today() from public,anon;
grant execute on function public.get_my_today() to authenticated;
