-- Spec 008 (T001): EVERY admin_* RPC refuses non-admins with `not_admin`
-- and works for an app admin (private.app_admins). Fixtures use the b8
-- UUID prefix; everything runs in a rolled-back transaction.
create extension if not exists pgtap with schema extensions;
\i helpers/seed_members.sql
begin;
select plan(31);

select tests_seed_user('b8000000-0000-0000-0000-000000000001','b8fix-admin@example.test','B8FIX Admin');
select tests_seed_user('b8000000-0000-0000-0000-000000000002','b8fix-user@example.test','B8FIX User');
select tests_seed_group('b8000000-0000-0000-0000-000000000010','B8FIX Guard Group','b8000000-0000-0000-0000-000000000002','Africa/Cairo','Q8GA2345');
select tests_seed_member('b8000000-0000-0000-0000-000000000010','b8000000-0000-0000-0000-000000000002',1::smallint,'owner'::public.group_role);
insert into private.app_admins (user_id) values ('b8000000-0000-0000-0000-000000000001');

-- Catalog: the admin RPC surface, all SECURITY DEFINER with an empty
-- search_path, executable by authenticated and never by anon.
select is((select count(*)::int from pg_proc p where p.pronamespace='public'::regnamespace
  and p.proname like 'admin\_%' and p.proname in (
  'admin_is_admin','admin_overview','admin_list_groups','admin_group_detail',
  'admin_list_users','admin_user_detail','admin_list_audit','admin_archive_group',
  'admin_restore_group','admin_delete_group','admin_remove_member',
  'admin_transfer_ownership','admin_regenerate_invite','admin_suspend_cleanup',
  'admin_clear_suspension','admin_set_admin','admin_prepare_user_delete')),17,
  'all seventeen admin RPCs exist');
select is((select count(*)::int from pg_proc p where p.pronamespace='public'::regnamespace
  and p.proname like 'admin\_%'),17,'no untested admin_* RPC exists');
select is((select count(*)::int from pg_proc p where p.pronamespace='public'::regnamespace
  and p.proname like 'admin\_%' and (not p.prosecdef
    or not coalesce(p.proconfig @> array['search_path=""'],false))),0,
  'every admin RPC is SECURITY DEFINER with search_path empty');
select is((select count(*)::int from pg_proc p where p.pronamespace='public'::regnamespace
  and p.proname like 'admin\_%' and has_function_privilege('anon',p.oid,'EXECUTE')),0,
  'anon cannot execute any admin RPC');
select is((select count(*)::int from pg_proc p where p.pronamespace='public'::regnamespace
  and p.proname like 'admin\_%' and not has_function_privilege('authenticated',p.oid,'EXECUTE')),0,
  'authenticated can call every admin RPC (the server guard decides)');
select ok(not has_function_privilege('authenticated','public.require_app_admin()','EXECUTE'),
  'require_app_admin is an internal helper');
select ok(not has_function_privilege('authenticated',
  'public.write_admin_audit(text,uuid,uuid,uuid,text,text,jsonb,uuid)','EXECUTE'),
  'clients cannot write audit rows');
select ok(has_function_privilege('service_role',
  'public.write_admin_audit(text,uuid,uuid,uuid,text,text,jsonb,uuid)','EXECUTE'),
  'Edge Functions (service role) can write audit rows');
select ok(not has_function_privilege('authenticated',
  'public.write_admin_auth_audit(text,uuid,uuid,text,uuid)','EXECUTE'),
  'clients cannot write legacy audit rows');
select ok(not has_schema_privilege('authenticated','private','USAGE')
  and not has_schema_privilege('anon','private','USAGE'),'private schema stays unexposed');
select ok(not has_table_privilege('authenticated','private.admin_audit','SELECT'),
  'audit table is not readable by clients');

-- Dynamic sweep: call EVERY admin_* RPC (except admin_is_admin) with NULL
-- arguments as a normal user; the guard must fire before any validation.
create or replace function pg_temp.b8_unguarded() returns text
language plpgsql as $$
declare r record; v_bad text := ''; v_state text; v_msg text;
begin
  for r in select p.proname, p.pronargs from pg_proc p
    where p.pronamespace='public'::regnamespace and p.proname like 'admin\_%'
      and p.proname <> 'admin_is_admin' loop
    begin
      execute format('select public.%I(%s)', r.proname,
        coalesce((select string_agg('null', ',') from generate_series(1, r.pronargs)), ''));
      v_bad := v_bad || r.proname || ':no_error ';
    exception when others then
      get stacked diagnostics v_state = returned_sqlstate, v_msg = message_text;
      if v_state <> 'P0001' or v_msg <> 'not_admin' then
        v_bad := v_bad || r.proname || ':' || v_msg || ' ';
      end if;
    end;
  end loop;
  return v_bad;
end $$;

select set_config('request.jwt.claim.sub','b8000000-0000-0000-0000-000000000002',true);
select is(pg_temp.b8_unguarded(),'','every admin RPC raises not_admin for a normal user');
select is(public.admin_is_admin(),false,'admin_is_admin is false for a normal user');
select is(public.is_app_admin(),false,'is_app_admin (Edge Functions) is false for a normal user');
select throws_ok($$select public.admin_overview()$$,'P0001','not_admin','normal user: overview refused');
select throws_ok($$select public.admin_list_groups(null,null,10,0)$$,'P0001','not_admin','normal user: list groups refused');
select throws_ok($$select public.admin_delete_group('b8000000-0000-0000-0000-000000000010','B8FIX Guard Group')$$,'P0001','not_admin','normal user: delete group refused');
select is((select count(*)::int from public.groups where id='b8000000-0000-0000-0000-000000000010'),1,'refused delete leaves the group');
select throws_ok($$select public.admin_set_admin('b8000000-0000-0000-0000-000000000002',true)$$,'P0001','not_admin','normal user cannot grant themselves admin');

select set_config('request.jwt.claim.sub','',true);
select throws_ok($$select public.admin_overview()$$,'P0001','unauthenticated','anonymous caller is refused');

-- Admin: the same calls work.
select set_config('request.jwt.claim.sub','b8000000-0000-0000-0000-000000000001',true);
select is(public.admin_is_admin(),true,'admin_is_admin is true for an admin');
select is(public.is_app_admin(),true,'is_app_admin is true for an admin');
select ok(public.admin_overview() ? 'users','admin reads the overview');
select ok((public.admin_list_groups('B8FIX',null,10,0)->>'total')::int = 1,'admin lists groups');
select ok((public.admin_group_detail('b8000000-0000-0000-0000-000000000010')->'group'->>'id') = 'b8000000-0000-0000-0000-000000000010','admin reads group detail');
select ok((public.admin_list_users('b8fix',null,10,0)->>'total')::int = 2,'admin lists users');
select ok((public.admin_user_detail('b8000000-0000-0000-0000-000000000002')->'user'->>'email') = 'b8fix-user@example.test','admin sees emails');
select ok(public.admin_list_audit(null,10,0) ? 'items','admin reads the audit log');
select ok((public.admin_regenerate_invite('b8000000-0000-0000-0000-000000000010')->>'invite_code') <> 'Q8GA2345','admin regenerates an invite');

-- Suspended-at is server-owned: a user cannot clear or set it on themselves.
select set_config('request.jwt.claim.sub','b8000000-0000-0000-0000-000000000002',true);
set local role authenticated;
select throws_ok($$update public.profiles set suspended_at = now() where id = 'b8000000-0000-0000-0000-000000000002'$$,'P0001','forbidden','users cannot write suspended_at');
reset role;
select ok(exists(select 1 from information_schema.columns where table_schema='public'
  and table_name='profiles' and column_name='suspended_at'),'profiles.suspended_at exists');

select * from finish();
rollback;
