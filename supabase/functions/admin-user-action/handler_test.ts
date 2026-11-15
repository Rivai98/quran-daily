// Unit tests for the admin-user-action handler with fake dependencies.
// Run: deno test supabase/functions/admin-user-action/handler_test.ts
import { strict as assert } from 'node:assert';
import { BAN_DURATION, type Deps, makeHandler } from './handler.ts';

const ADMIN = '11111111-1111-4111-8111-111111111111';
const TARGET = '22222222-2222-4222-8222-222222222222';

type Call = [string, ...unknown[]];

function fakes(overrides: Partial<Deps> = {}) {
  const calls: Call[] = [];
  const audits: Record<string, unknown>[] = [];
  const deps: Deps = {
    requireAdmin: (header) =>
      Promise.resolve(
        header === 'Bearer admin'
          ? { user: { id: ADMIN } }
          : header === 'Bearer user'
          ? { error: 'forbidden' as const }
          : { error: 'unauthenticated' as const },
      ),
    callerRpc: (header, fn, args) => {
      calls.push(['rpc', header, fn, args]);
      return Promise.resolve({ data: { ok: true }, error: null });
    },
    setBan: (id, duration) => {
      calls.push(['ban', id, duration]);
      return Promise.resolve({ error: null });
    },
    deleteAuthUser: (id) => {
      calls.push(['delete', id]);
      return Promise.resolve({ error: null });
    },
    writeAudit: (input) => {
      audits.push(input);
      return Promise.resolve();
    },
    correlationId: () => 'cid-1',
    ...overrides,
  };
  return { deps, calls, audits };
}

function post(body: unknown, auth = 'Bearer admin'): Request {
  return new Request('http://local/admin-user-action', {
    method: 'POST',
    headers: { Authorization: auth, 'Content-Type': 'application/json' },
    body: typeof body === 'string' ? body : JSON.stringify(body),
  });
}

async function run(deps: Deps, req: Request) {
  const res = await makeHandler(deps)(req);
  return { status: res.status, body: await res.json() };
}

Deno.test('refuses unauthenticated and non-admin callers before any work', async () => {
  const f = fakes();
  assert.equal((await run(f.deps, post({ action: 'suspend', targetUserId: TARGET }, ''))).status, 401);
  const r = await run(f.deps, post({ action: 'suspend', targetUserId: TARGET }, 'Bearer user'));
  assert.deepEqual(r, { status: 403, body: { code: 'forbidden' } });
  assert.equal(f.calls.length, 0);
});

Deno.test('validates the body', async () => {
  const f = fakes();
  assert.equal((await run(f.deps, post('{bad'))).status, 400);
  assert.equal((await run(f.deps, post({ action: 'nuke', targetUserId: TARGET }))).status, 400);
  assert.equal((await run(f.deps, post({ action: 'suspend', targetUserId: 'x' }))).status, 400);
  assert.equal(f.calls.length, 0);
});

Deno.test('refuses self-suspend and self-delete without touching auth', async () => {
  const f = fakes();
  for (const action of ['suspend', 'delete']) {
    const r = await run(f.deps, post({ action, targetUserId: ADMIN }));
    assert.deepEqual(r, { status: 409, body: { code: 'cannot_target_self' } });
  }
  assert.equal(f.calls.length, 0);
});

Deno.test('suspend: cleanup RPC with caller token, then permanent ban, then audit', async () => {
  const f = fakes();
  const r = await run(f.deps, post({ action: 'suspend', targetUserId: TARGET }));
  assert.equal(r.status, 200);
  assert.equal(r.body.suspended, true);
  assert.deepEqual(f.calls, [
    ['rpc', 'Bearer admin', 'admin_suspend_cleanup', { p_user_id: TARGET }],
    ['ban', TARGET, BAN_DURATION],
  ]);
  assert.equal(f.audits.length, 1);
  assert.equal(f.audits[0].action, 'suspend_user');
  assert.equal(f.audits[0].result, 'succeeded');
  assert.equal(f.audits[0].actorUserId, ADMIN);
});

Deno.test('suspend: database refusal is returned and no ban happens', async () => {
  const f = fakes({
    callerRpc: () => Promise.resolve({ data: null, error: { message: 'target_is_admin' } }),
  });
  const r = await run(f.deps, post({ action: 'suspend', targetUserId: TARGET }));
  assert.deepEqual(r, { status: 409, body: { code: 'target_is_admin' } });
  assert.equal(f.calls.filter((c) => c[0] === 'ban').length, 0);
});

Deno.test('suspend: failed ban is audited and reported', async () => {
  const f = fakes({ setBan: () => Promise.resolve({ error: { status: 500 } }) });
  const r = await run(f.deps, post({ action: 'suspend', targetUserId: TARGET }));
  assert.deepEqual(r, { status: 500, body: { code: 'operation_failed' } });
  assert.equal(f.audits[0].result, 'failed');
});

Deno.test('unsuspend: lifts the ban and clears the profile flag', async () => {
  const f = fakes();
  const r = await run(f.deps, post({ action: 'unsuspend', targetUserId: TARGET }));
  assert.equal(r.status, 200);
  assert.deepEqual(f.calls, [
    ['ban', TARGET, 'none'],
    ['rpc', 'Bearer admin', 'admin_clear_suspension', { p_user_id: TARGET }],
  ]);
  assert.equal(f.audits[0].action, 'unsuspend_user');
});

Deno.test('unsuspend: unknown auth user maps to 404', async () => {
  const f = fakes({ setBan: () => Promise.resolve({ error: { status: 404 } }) });
  const r = await run(f.deps, post({ action: 'unsuspend', targetUserId: TARGET }));
  assert.deepEqual(r, { status: 404, body: { code: 'user_not_found' } });
});

Deno.test('delete: prepare RPC, ban, delete auth user, audit', async () => {
  const f = fakes();
  const r = await run(f.deps, post({ action: 'delete', targetUserId: TARGET }));
  assert.equal(r.status, 200);
  assert.equal(r.body.deleted, true);
  assert.deepEqual(f.calls.map((c) => c[0] === 'rpc' ? c[2] : c[0]), [
    'admin_prepare_user_delete',
    'ban',
    'delete',
  ]);
  assert.equal(f.audits[0].action, 'delete_user');
  assert.equal(f.audits[0].result, 'succeeded');
});

Deno.test('delete: auth delete failure is audited and nothing claims success', async () => {
  const f = fakes({ deleteAuthUser: () => Promise.resolve({ error: { status: 429 } }) });
  const r = await run(f.deps, post({ action: 'delete', targetUserId: TARGET }));
  assert.deepEqual(r, { status: 429, body: { code: 'rate_limited' } });
  assert.equal(f.audits[0].result, 'rate_limited');
});

Deno.test('grant/revoke admin go through admin_set_admin (DB audits them)', async () => {
  const f = fakes({
    callerRpc: (header, fn, args) => {
      f.calls.push(['rpc', header, fn, args]);
      return Promise.resolve({ data: { is_admin: args.p_grant }, error: null });
    },
  });
  const g = await run(f.deps, post({ action: 'grant_admin', targetUserId: TARGET }));
  assert.deepEqual(g.body, { userId: TARGET, action: 'grant_admin', isAdmin: true });
  const v = await run(f.deps, post({ action: 'revoke_admin', targetUserId: TARGET }));
  assert.equal(v.body.isAdmin, false);
  assert.equal(f.audits.length, 0);
});

Deno.test('self revoke reaches the database, which protects the last admin', async () => {
  const f = fakes({
    callerRpc: () => Promise.resolve({ data: null, error: { message: 'last_admin' } }),
  });
  const r = await run(f.deps, post({ action: 'revoke_admin', targetUserId: ADMIN }));
  assert.deepEqual(r, { status: 409, body: { code: 'last_admin' } });
});

Deno.test('unexpected RPC errors do not leak details', async () => {
  const f = fakes({
    callerRpc: () => Promise.resolve({ data: null, error: { message: 'relation "x" does not exist' } }),
  });
  const r = await run(f.deps, post({ action: 'grant_admin', targetUserId: TARGET }));
  assert.deepEqual(r, { status: 500, body: { code: 'operation_failed' } });
});
