# Contract: Supabase Authentication Backend

## Project Configuration

- Enable email/password authentication.
- Disable email confirmation for public signup.
- Do not configure the app to call OTP, magic-link, invite, or password-recovery email flows.
- Flutter receives only `SUPABASE_URL` and the publishable/anonymous key.
- Store the service-role/secret key only in trusted Edge Function secret storage; never source control, app assets, client environment, test fixtures, logs, or responses.
- Use separate development/test and production Supabase projects.

## Database Migration Contract

The migration creates:

- `public.profiles` as defined in [data-model.md](../data-model.md).
- A schema-qualified `SECURITY DEFINER SET search_path = ''` function that validates `raw_user_meta_data.display_name` and inserts the profile.
- An `AFTER INSERT ON auth.users` trigger invoking that function.
- An updated-at mechanism that clients cannot forge.
- Owner-only RLS policies and minimal grants for profile select/update.
- Protected `app_admins` and `admin_auth_audit` relations.

**Required invariants**

- Every successfully created auth user has exactly one profile.
- Failure to provision a valid profile fails account creation cleanly.
- Anonymous users cannot access profiles.
- One user cannot read or change another profile.
- Mobile clients cannot create/delete profiles or grant administrator rights.
- No database relation stores readable passwords or notification destinations.

## Edge Function: `admin-create-user`

**Authentication**: Required bearer session.

**Authorization**: Caller must exist in authoritative `app_admins`.

**Request**

```json
{
  "displayName": "string, 1-100 trimmed characters",
  "email": "normalized valid email",
  "password": "string, minimum 8 characters"
}
```

**Operation**

1. Validate caller session using the bearer token.
2. Verify caller administrator membership using a caller-scoped client.
3. Validate and normalize input server-side.
4. Invoke the server-only Auth Admin create-user operation with the email already confirmed and display name in non-authoritative metadata.
5. Rely on the database trigger for profile creation.
6. Write a secret-free audit result.

**Responses**
- `201`: `{ "userId": "uuid" }`
- `400`: `{ "code": "validation_failed" }`
- `401`: `{ "code": "unauthenticated" }`
- `403`: `{ "code": "forbidden" }`
- `409`: `{ "code": "email_exists" }`
- `429`: `{ "code": "rate_limited" }`
- `500`: `{ "code": "operation_failed", "correlationId": "uuid" }`

## Edge Function: `admin-reset-password`

**Authentication/authorization**: Same as `admin-create-user`.

**Request**

```json
{
  "targetUserId": "uuid",
  "newPassword": "string, minimum 8 characters"
}
```

**Operation**

1. Authenticate and authorize the caller.
2. Validate target and password.
3. Invoke the server-only Auth Admin update-user operation.
4. Write a secret-free audit result.
5. Do not generate or send an email, link, or code.

**Responses**
- `200`: `{ "userId": "uuid", "passwordReplaced": true }`
- `400`, `401`, `403`, `429`, `500`: same stable shape as account creation.
- `404`: `{ "code": "user_not_found" }`, returned only to an authorized administrator.

## Security and Operational Rules

- Never trust admin status from request data, Flutter state, group organizer role, or user metadata.
- Rate-limit privileged functions and protect duplicate/concurrent account creation.
- Passwords and tokens must not appear in logs, audits, analytics, or error bodies.
- Replacement passwords are communicated by the administrator outside this application.
- The acceptance contract guarantees old credentials fail and new credentials work; it does not guarantee revocation of already-issued sessions unless added and verified separately.
- No administrator mobile screen is delivered in this feature; these functions form the contract for a trusted operational client.
