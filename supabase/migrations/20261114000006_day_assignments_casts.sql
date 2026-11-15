-- 003b fix-forward: create_day_assignments needs explicit enum/smallint casts
create or replace function public.create_day_assignments(
  p_day_id uuid, p_group_id uuid, p_day_index int)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_start_juz smallint;
begin
  select start_juz into v_start_juz from public.groups where id = p_group_id;
  if v_start_juz is null then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;

  insert into public.assignments (
    group_day_id, juz, seat_number, kind, reader_membership_id, status)
  select
    p_day_id,
    public.juz_for_seat(s, v_start_juz, p_day_index)::smallint,
    s::smallint,
    (case when m.id is null then 'unassigned' else 'seat' end
       )::public.assignment_kind,
    m.id,
    (case when m.id is null then 'available' else 'pending' end
       )::public.assignment_status
  from generate_series(1, 30) s
  left join public.group_memberships m
    on m.group_id = p_group_id and m.seat_number = s and m.status = 'active'
  on conflict (group_day_id, seat_number) do nothing;
end;
$$;
