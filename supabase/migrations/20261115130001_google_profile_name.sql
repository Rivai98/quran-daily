-- Google provider metadata uses full_name/name rather than display_name.
-- Preserve email/password behavior while provisioning a safe fallback name.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_display_name text;
begin
  v_display_name := left(btrim(coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(btrim(new.raw_user_meta_data ->> 'name'), ''),
    split_part(coalesce(new.email, ''), '@', 1)
  )), 100);

  if v_display_name = '' then
    raise exception 'profile not provisioned'
      using errcode = '23502';
  end if;

  insert into public.profiles (id, display_name)
  values (new.id, v_display_name);

  return new;
end;
$$;
