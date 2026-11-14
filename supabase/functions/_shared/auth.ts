import { callerClient } from './supabase.ts';

/**
 * Resolves the caller and refuses anyone who is not an application
 * administrator (private.app_admins), verified server-side through the
 * SECURITY DEFINER RPC `public.is_app_admin()` executed with the CALLER's
 * token. Admin status is NEVER taken from request data, user metadata, or
 * group roles (spec 002 backend contract).
 */
export async function requireAdmin(authHeader: string | null) {
  if (!authHeader?.startsWith('Bearer ')) {
    return { error: 'unauthenticated' as const };
  }

  const client = callerClient(authHeader);

  const { data: userData, error: userError } = await client.auth.getUser();
  if (userError || !userData?.user) {
    return { error: 'unauthenticated' as const };
  }

  const { data: isAdmin, error: adminError } = await client
    .rpc('is_app_admin');
  if (adminError || isAdmin !== true) {
    return { error: 'forbidden' as const };
  }

  return { user: userData.user };
}
