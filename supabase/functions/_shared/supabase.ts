import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2';

export function env(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`missing environment variable ${name}`);
  }
  return value;
}

/** Caller-scoped client: carries the caller's JWT so RLS applies. */
export function callerClient(authHeader: string | null): SupabaseClient {
  return createClient(env('SUPABASE_URL'), env('SUPABASE_ANON_KEY'), {
    global: { headers: { Authorization: authHeader ?? '' } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/** Server-only client with the service role key; never returned to callers. */
export function serviceClient(): SupabaseClient {
  return createClient(env('SUPABASE_URL'), env('SUPABASE_SERVICE_ROLE_KEY'), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
