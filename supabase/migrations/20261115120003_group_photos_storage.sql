-- Spec 007: private group photo bucket. Object path: "<group_id>/<file>".
-- Read: active members of that group. Insert/update/delete: the group owner.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('group-photos', 'group-photos', false, 1048576,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Group id from the first path segment; null when it is not a uuid.
create or replace function public.group_photo_group_id(p_name text)
returns uuid language sql immutable set search_path = '' as $$
  select case when split_part(p_name, '/', 1)
    ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then split_part(p_name, '/', 1)::uuid end;
$$;
revoke all on function public.group_photo_group_id(text) from public, anon;
grant execute on function public.group_photo_group_id(text) to authenticated;

create or replace function public.can_read_group_photo(p_name text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.group_memberships m
    where m.group_id = public.group_photo_group_id(p_name)
      and m.user_id = auth.uid() and m.status = 'active');
$$;
revoke all on function public.can_read_group_photo(text) from public, anon;
grant execute on function public.can_read_group_photo(text) to authenticated;

-- Owner only, and only directly inside the group folder ("<group_id>/<file>").
create or replace function public.can_manage_group_photo(p_name text)
returns boolean language sql stable security definer set search_path = '' as $$
  select p_name ~ '^[^/]+/[^/]+$' and exists (select 1 from public.groups g
    where g.id = public.group_photo_group_id(p_name) and g.owner_id = auth.uid());
$$;
revoke all on function public.can_manage_group_photo(text) from public, anon;
grant execute on function public.can_manage_group_photo(text) to authenticated;

drop policy if exists group_photos_select_member on storage.objects;
drop policy if exists group_photos_insert_owner on storage.objects;
drop policy if exists group_photos_update_owner on storage.objects;
drop policy if exists group_photos_delete_owner on storage.objects;

create policy group_photos_select_member on storage.objects
  for select to authenticated
  using (bucket_id = 'group-photos' and public.can_read_group_photo(name));

create policy group_photos_insert_owner on storage.objects
  for insert to authenticated
  with check (bucket_id = 'group-photos' and public.can_manage_group_photo(name));

create policy group_photos_update_owner on storage.objects
  for update to authenticated
  using (bucket_id = 'group-photos' and public.can_manage_group_photo(name))
  with check (bucket_id = 'group-photos' and public.can_manage_group_photo(name));

create policy group_photos_delete_owner on storage.objects
  for delete to authenticated
  using (bucket_id = 'group-photos' and public.can_manage_group_photo(name));
