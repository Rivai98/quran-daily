import { requireAdmin } from '../_shared/auth.ts';
import { correlationId, writeAudit } from '../_shared/audit.ts';
import { fail, json } from '../_shared/http.ts';
import { validPassword, validUuid } from '../_shared/validate.ts';
import { serviceClient } from '../_shared/supabase.ts';

Deno.serve(async (request: Request) => {
  const auth = await requireAdmin(request.headers.get('Authorization'));
  if ('error' in auth) {
    return fail(auth.error === 'unauthenticated' ? 401 : 403, auth.error);
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch (_error) {
    return fail(400, 'validation_failed');
  }

  const targetUserId = validUuid(body.targetUserId);
  const newPassword = validPassword(body.newPassword);
  if (!targetUserId || !newPassword) {
    return fail(400, 'validation_failed');
  }

  const cid = correlationId();

  try {
    const service = serviceClient();
    const { error } = await service.auth.admin.updateUserById(targetUserId, {
      password: newPassword,
    });

    if (error) {
      const status = error.status ?? 500;
      const result = status === 404
        ? 'user_not_found'
        : status === 429
        ? 'rate_limited'
        : 'failed';
      if (status === 404) {
        return fail(404, 'user_not_found');
      }
      if (status === 429) {
        await writeAudit({
          action: 'reset_password',
          actorUserId: auth.user.id,
          targetUserId,
          result,
          correlationId: cid,
        });
        return fail(429, 'rate_limited');
      }
      await writeAudit({
        action: 'reset_password',
        actorUserId: auth.user.id,
        targetUserId,
        result,
        correlationId: cid,
      });
      return fail(500, 'operation_failed');
    }

    await writeAudit({
      action: 'reset_password',
      actorUserId: auth.user.id,
      targetUserId,
      result: 'succeeded',
      correlationId: cid,
    });
    return json(200, { userId: targetUserId, passwordReplaced: true });
  } catch (_error) {
    await writeAudit({
      action: 'reset_password',
      actorUserId: auth.user.id,
      targetUserId,
      result: 'failed',
      correlationId: cid,
    });
    return fail(500, 'operation_failed');
  }
});
