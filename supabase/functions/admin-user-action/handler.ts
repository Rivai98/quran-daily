/**
 * admin-user-action (spec 008): auth-level user actions for app admins.
 *
 * POST { action, targetUserId }
 *   action: 'suspend' | 'unsuspend' | 'delete' | 'grant_admin' | 'revoke_admin'
 *
 * Admin status is verified server-side (requireAdmin -> is_app_admin with the
 * caller's token). Data-side steps run through admin_* RPCs with the CALLER's
 * token, so the database guard and its audit rows apply; auth-side steps
 * (ban, unban, delete) use the service role, which never leaves the server.
 *
 * This module has no runtime imports so it can be unit-tested with fakes.
 */

export type UserAction =
  | 'suspend'
  | 'unsuspend'
  | 'delete'
  | 'grant_admin'
  | 'revoke_admin';

export const USER_ACTIONS: readonly UserAction[] = [
  'suspend',
  'unsuspend',
  'delete',
  'grant_admin',
  'revoke_admin',
];

/** Effectively permanent auth ban (~100 years), lifted by 'unsuspend'. */
export const BAN_DURATION = '876000h';

export type AuditAction = 'suspend_user' | 'unsuspend_user' | 'delete_user';

export interface RpcError {
  message: string;
}

export interface AuthAdminError {
  status?: number;
}

export interface Deps {
  requireAdmin(
    authHeader: string | null,
  ): Promise<{ user: { id: string } } | { error: 'unauthenticated' | 'forbidden' }>;
  /** Calls a public RPC with the caller's (admin's) token. */
  callerRpc(
    authHeader: string,
    fn: string,
    args: Record<string, unknown>,
  ): Promise<{ data: unknown; error: RpcError | null }>;
  /** Service-role auth admin API. */
  setBan(userId: string, banDuration: string): Promise<{ error: AuthAdminError | null }>;
  deleteAuthUser(userId: string): Promise<{ error: AuthAdminError | null }>;
  writeAudit(input: {
    action: AuditAction;
    actorUserId: string;
    targetUserId: string;
    result: string;
    details?: Record<string, unknown>;
    correlationId: string;
  }): Promise<void>;
  correlationId(): string;
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** RPC error codes that are safe to return to the admin as-is. */
const RPC_CODES: Record<string, number> = {
  not_admin: 403,
  unauthenticated: 401,
  cannot_target_self: 409,
  target_is_admin: 409,
  target_suspended: 409,
  last_admin: 409,
  user_not_found: 404,
  validation_failed: 400,
};

function respond(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function rpcFailure(error: RpcError): Response {
  const code = Object.keys(RPC_CODES).find((c) => error.message?.includes(c));
  return code
    ? respond(RPC_CODES[code], { code })
    : respond(500, { code: 'operation_failed' });
}

function authFailureResult(error: AuthAdminError): string {
  if (error.status === 404) return 'user_not_found';
  if (error.status === 429) return 'rate_limited';
  return 'failed';
}

function authFailure(result: string): Response {
  if (result === 'user_not_found') return respond(404, { code: result });
  if (result === 'rate_limited') return respond(429, { code: result });
  return respond(500, { code: 'operation_failed' });
}

export function makeHandler(deps: Deps) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== 'POST') {
      return respond(405, { code: 'method_not_allowed' });
    }
    const authHeader = request.headers.get('Authorization');
    const auth = await deps.requireAdmin(authHeader);
    if ('error' in auth) {
      return respond(auth.error === 'unauthenticated' ? 401 : 403, { code: auth.error });
    }

    let body: Record<string, unknown>;
    try {
      body = await request.json();
    } catch (_error) {
      return respond(400, { code: 'validation_failed' });
    }

    const action = body?.action as UserAction;
    const target = typeof body?.targetUserId === 'string' && UUID_RE.test(body.targetUserId)
      ? body.targetUserId.toLowerCase()
      : null;
    if (!USER_ACTIONS.includes(action) || !target) {
      return respond(400, { code: 'validation_failed' });
    }

    const actor = auth.user.id;
    if (target === actor && action !== 'revoke_admin') {
      // Self-suspend/delete is refused here before touching auth; the
      // database repeats the check. Self-revoke is allowed unless last admin.
      return respond(409, { code: 'cannot_target_self' });
    }

    const header = authHeader as string;
    const cid = deps.correlationId();
    const audit = (a: AuditAction, result: string, details?: Record<string, unknown>) =>
      deps.writeAudit({
        action: a,
        actorUserId: actor,
        targetUserId: target,
        result,
        details,
        correlationId: cid,
      });

    try {
      switch (action) {
        case 'grant_admin':
        case 'revoke_admin': {
          // The RPC enforces last_admin / target_suspended and writes audit.
          const { data, error } = await deps.callerRpc(header, 'admin_set_admin', {
            p_user_id: target,
            p_grant: action === 'grant_admin',
          });
          if (error) return rpcFailure(error);
          const isAdmin = (data as { is_admin?: boolean } | null)?.is_admin ?? (action === 'grant_admin');
          return respond(200, { userId: target, action, isAdmin });
        }

        case 'suspend': {
          // Data side first: validates self/admin/not-found and ends
          // memberships (audited as suspend_cleanup), then the auth ban.
          const cleanup = await deps.callerRpc(header, 'admin_suspend_cleanup', {
            p_user_id: target,
          });
          if (cleanup.error) return rpcFailure(cleanup.error);
          const { error } = await deps.setBan(target, BAN_DURATION);
          if (error) {
            const result = authFailureResult(error);
            await audit('suspend_user', result);
            return authFailure(result);
          }
          await audit('suspend_user', 'succeeded');
          return respond(200, { userId: target, action, suspended: true, cleanup: cleanup.data });
        }

        case 'unsuspend': {
          const { error } = await deps.setBan(target, 'none');
          if (error) {
            const result = authFailureResult(error);
            await audit('unsuspend_user', result);
            return authFailure(result);
          }
          const cleared = await deps.callerRpc(header, 'admin_clear_suspension', {
            p_user_id: target,
          });
          if (cleared.error) {
            await audit('unsuspend_user', 'profile_not_cleared');
            return rpcFailure(cleared.error);
          }
          await audit('unsuspend_user', 'succeeded');
          return respond(200, { userId: target, action, suspended: false });
        }

        case 'delete': {
          // 1) hand groups over + anonymize history (audited), 2) block
          // sign-in, 3) delete the auth user (profile/memberships cascade).
          const prep = await deps.callerRpc(header, 'admin_prepare_user_delete', {
            p_user_id: target,
          });
          if (prep.error) return rpcFailure(prep.error);
          const ban = await deps.setBan(target, BAN_DURATION);
          if (ban.error) {
            const result = authFailureResult(ban.error);
            await audit('delete_user', result, { step: 'ban' });
            return authFailure(result);
          }
          const { error } = await deps.deleteAuthUser(target);
          if (error) {
            const result = authFailureResult(error);
            await audit('delete_user', result, { step: 'delete' });
            return authFailure(result);
          }
          await audit('delete_user', 'succeeded', { prepared: prep.data });
          return respond(200, { userId: target, action, deleted: true });
        }
      }
    } catch (_error) {
      if (action === 'suspend' || action === 'unsuspend' || action === 'delete') {
        await audit(`${action}_user` as AuditAction, 'failed');
      }
      return respond(500, { code: 'operation_failed' });
    }
    return respond(400, { code: 'validation_failed' });
  };
}
