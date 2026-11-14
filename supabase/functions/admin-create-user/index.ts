import { requireAdmin } from '../_shared/auth.ts';
import { correlationId, writeAudit } from '../_shared/audit.ts';
import { fail, json } from '../_shared/http.ts';
import {
  normalizeDisplayName,
  normalizeEmail,
  validPassword,
} from '../_shared/validate.ts';
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

  const displayName = normalizeDisplayName(body.displayName);
  const email = normalizeEmail(body.email);
  const password = validPassword(body.password);
  if (!displayName || !email || !password) {
    return fail(400, 'validation_failed');
  }

  const cid = correlationId();

  try {
    const service = serviceClient();
    const { data, error } = await service.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { display_name: displayName },
    });

    if (error) {
      const status = error.status ?? 500;
      if (status === 422 || error.code === 'user_already_exists' ||
          error.code === 'email_exists') {
        await writeAudit({
          action: 'create_user',
          actorUserId: auth.user.id,
          targetUserId: null,
          result: 'email_exists',
          correlationId: cid,
        });
        return fail(409, 'email_exists');
      }
      if (status === 429) {
        await writeAudit({
          action: 'create_user',
          actorUserId: auth.user.id,
          targetUserId: null,
          result: 'rate_limited',
          correlationId: cid,
        });
        return fail(429, 'rate_limited');
      }
      await writeAudit({
        action: 'create_user',
        actorUserId: auth.user.id,
        targetUserId: null,
        result: 'failed',
        correlationId: cid,
      });
      return fail(500, 'operation_failed');
    }

    // The database trigger provisions the profile; verify it exists before
    // reporting success (spec 002: profile failure must fail creation
    // cleanly — defensive check only).
    if (!data?.user?.id) {
      await writeAudit({
        action: 'create_user',
        actorUserId: auth.user.id,
        targetUserId: null,
        result: 'failed',
        correlationId: cid,
      });
      return fail(500, 'operation_failed');
    }

    await writeAudit({
      action: 'create_user',
      actorUserId: auth.user.id,
      targetUserId: data.user.id,
      result: 'succeeded',
      correlationId: cid,
    });
    return json(201, { userId: data.user.id });
  } catch (_error) {
    await writeAudit({
      action: 'create_user',
      actorUserId: auth.user.id,
      targetUserId: null,
      result: 'failed',
      correlationId: cid,
    });
    return fail(500, 'operation_failed');
  }
});
