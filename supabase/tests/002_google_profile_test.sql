create extension if not exists pgtap with schema extensions;

begin;
select plan(5);

create or replace function tests_google_insert(p_id uuid, p_email text, p_metadata jsonb)
returns void language plpgsql as $$
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token
  ) values (
    p_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    p_email, 'test-only', now(), '{"provider":"google","providers":["google"]}'::jsonb,
    p_metadata, now(), now(), '', ''
  );
end;
$$;

select tests_google_insert('a2000000-0000-0000-0000-000000000001', 'a2-full@test.local', '{"full_name":"Full Name"}');
select is((select display_name from public.profiles where id='a2000000-0000-0000-0000-000000000001'), 'Full Name', 'uses full_name fallback');
select tests_google_insert('a2000000-0000-0000-0000-000000000002', 'a2-name@test.local', '{"name":"Name Fallback"}');
select is((select display_name from public.profiles where id='a2000000-0000-0000-0000-000000000002'), 'Name Fallback', 'uses name fallback');
select tests_google_insert('a2000000-0000-0000-0000-000000000003', 'a2-email-part@test.local', '{}');
select is((select display_name from public.profiles where id='a2000000-0000-0000-0000-000000000003'), 'a2-email-part', 'uses email local part fallback');
select tests_google_insert('a2000000-0000-0000-0000-000000000004', 'a2-display@test.local', '{"display_name":"Display Wins","full_name":"Other"}');
select is((select display_name from public.profiles where id='a2000000-0000-0000-0000-000000000004'), 'Display Wins', 'display_name keeps precedence');
select tests_google_insert('a2000000-0000-0000-0000-000000000005', 'a2-cap@test.local', jsonb_build_object('name', repeat('x', 140)));
select is(length((select display_name from public.profiles where id='a2000000-0000-0000-0000-000000000005')), 100, 'fallback name capped at 100 chars');

select * from finish();
rollback;
