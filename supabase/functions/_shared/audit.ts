import { serviceClient } from './supabase.ts';
import { json } from './http.ts';

export type AdminAuditAction = 'create_user' | 'reset_password';

/**
 * Secret-free audit trail (private.admin_auth_audit) via a SECURITY
 * DEFINER RPC; never stores passwords, tokens, or secrets.
 */
export async function writeAudit(input: {
  action: AdminAuditAction;
  actorUserId: string;
  targetUserId?: string | null;
  result: string;
  correlationId: string;
}): Promise<void> {
  try {
    const service = serviceClient();
    await service.rpc('write_admin_auth_audit', {
      p_action: input.action,
      p_actor_user_id: input.actorUserId,
      p_target_user_id: input.targetUserId ?? null,
      p_result: input.result,
      p_correlation_id: input.correlationId,
    });
  } catch (_error) {
    // Auditing must never leak internals or break the response; the
    // operation result is still returned to the caller.
  }
}

export function correlationId(): string {
  return crypto.randomUUID();
}

export { json };
