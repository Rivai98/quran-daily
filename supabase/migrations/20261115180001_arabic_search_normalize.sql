-- Owner review: group search must match common Arabic spelling variants
-- (ة/ه, أ/إ/آ/ا, ى/ي, tatweel and diacritics), e.g. "حلقه" finds "حلقة".

create or replace function public.arabic_search_normalize(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
  select lower(
    translate(
      regexp_replace(coalesce(p_text, ''), '[ً-ْٰـ]', '', 'g'),
      'أإآٱةى',
      'ااااهي'
    )
  );
$$;

revoke all on function public.arabic_search_normalize(text) from public, anon;
grant execute on function public.arabic_search_normalize(text) to authenticated;

-- Innermost search implementation (renamed in 20261115090002), now normalized.
create or replace function public.search_public_groups_portion_base(
  p_query text default null,
  p_needs_members_only boolean default true,
  p_limit integer default 20,
  p_offset integer default 0
)
returns setof jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_query text;
begin
  v_uid := public.require_auth_uid();
  if p_limit < 1 or p_limit > 100 or p_offset < 0 then
    raise exception 'validation_failed' using errcode = 'P0001';
  end if;
  v_query := nullif(public.arabic_search_normalize(btrim(coalesce(p_query, ''))), '');

  return query
  select jsonb_build_object(
    'group_id', g.id,
    'name', g.name,
    'short_description', g.short_description,
    'status', g.status,
    'active_member_count', counts.member_count,
    'timezone', g.timezone,
    'join_mode', g.join_mode,
    'my_request_status', requests.request_status,
    'my_join_request_id', requests.request_id
  )
  from public.groups g
  cross join lateral (
    select count(*)::integer as member_count
    from public.group_memberships m
    where m.group_id = g.id and m.status = 'active'
  ) counts
  left join lateral (
    select j.status::text as request_status, j.id as request_id
    from public.join_requests j
    where j.group_id = g.id and j.user_id = v_uid
      and j.status in ('pending', 'rejected')
    order by (j.status = 'pending') desc, j.requested_at desc
    limit 1
  ) requests on true
  where g.visibility = 'public'
    and g.status <> 'archived'
    and (not p_needs_members_only or counts.member_count < 30)
    and (v_query is null
      or strpos(public.arabic_search_normalize(g.name), v_query) > 0
      or strpos(public.arabic_search_normalize(coalesce(g.short_description, '')), v_query) > 0)
  order by counts.member_count desc, g.created_at, g.id
  limit p_limit offset p_offset;
end;
$$;

revoke all on function public.search_public_groups_portion_base(text, boolean, integer, integer) from public, anon;
