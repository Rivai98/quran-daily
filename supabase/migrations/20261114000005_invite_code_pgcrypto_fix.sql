-- 003a fix-forward: new_invite_code uses pgcrypto's gen_random_bytes
-- (extensions schema; the function runs with search_path = '').
create extension if not exists pgcrypto with schema extensions;

create or replace function public.new_invite_code()
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_alphabet text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  v_code text := '';
  i int;
  v_bytes bytea;
begin
  v_bytes := extensions.gen_random_bytes(8);
  for i in 1..8 loop
    v_code := v_code || substr(v_alphabet,
      ((get_byte(v_bytes, i - 1) % 32) + 1), 1);
  end loop;
  return v_code;
end;
$$;
