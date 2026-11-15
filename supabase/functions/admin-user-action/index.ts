import { requireAdmin } from '../_shared/auth.ts';
import { correlationId, writeAudit } from '../_shared/audit.ts';
import { callerClient, serviceClient } from '../_shared/supabase.ts';
import { makeHandler } from './handler.ts';

// The service role key is read from the function environment by
// serviceClient(); it is never logged or returned.
Deno.serve(makeHandler({
  requireAdmin,
  callerRpc: async (authHeader, fn, args) => {
    const { data, error } = await callerClient(authHeader).rpc(fn, args);
    return { data, error: error ? { message: error.message } : null };
  },
  setBan: async (userId, banDuration) => {
    const { error } = await serviceClient().auth.admin.updateUserById(userId, {
      ban_duration: banDuration,
    });
    return { error: error ? { status: error.status } : null };
  },
  deleteAuthUser: async (userId) => {
    const { error } = await serviceClient().auth.admin.deleteUser(userId);
    return { error: error ? { status: error.status } : null };
  },
  writeAudit,
  correlationId,
}));
