# Data Model: Email and Password Authentication

## Entity Overview

```text
AuthUser 1--1 UserProfile
AuthUser 0--1 AppAdministrator
AuthUser 1--* AdminAuthAudit (actor)
AuthUser 1--* AdminAuthAudit (target)
AuthUser 1--* AuthSession       # Supabase-managed, not an app table
```

## AuthUser

Supabase Auth-owned identity and credential lifecycle.

**Relevant attributes**
- `id`: stable UUID used by all application relationships.
- `email`: normalized unique login identifier owned by Auth.
- `password_verifier`: Auth-managed credential material; never exposed to or stored by the app.
- `raw_user_meta_data.display_name`: non-authoritative input used only when provisioning the profile.
- `created_at`, `last_sign_in_at`: Auth-managed timestamps.

**Rules**
- Email/password is the only enabled app sign-in provider.
- Email confirmation is disabled for self-registration; administrator-created users are explicitly confirmed without email.
- The client never reads or writes password verifier data.
- Duplicate normalized emails must not create multiple identities.

## UserProfile (`public.profiles`)

Application data linked one-to-one with AuthUser.

**Fields**
- `id uuid primary key`: references `auth.users(id)` with cascade delete.
- `display_name text not null`: trimmed visible name.
- `created_at timestamptz not null`: database-generated creation time.
- `updated_at timestamptz not null`: database-maintained modification time.

**Rules**
- Created automatically by the auth-user trigger for every self-registered or administrator-created identity.
- `display_name` must be nonblank after trimming and use a bounded length selected in the migration (recommended 1-100 characters).
- Email, password, roles, device tokens, and notification preferences are not stored here.
- Authenticated owners can read and update only their own allowed profile fields.
- Clients cannot insert/delete profiles or change `id`/timestamps.
- Future notification entities reference this stable `id` but are not part of this feature.

## AppAdministrator (`private.app_admins` or equally protected schema)

Authoritative permission for application-wide account administration.

**Fields**
- `user_id uuid primary key`: references `auth.users(id)` with cascade delete.
- `granted_at timestamptz not null`: grant time.
- `granted_by uuid nullable`: trusted actor that granted access.

**Rules**
- Distinct from Quran group organizer membership.
- Cannot be created, updated, or deleted by the mobile client.
- Edge Functions verify membership server-side for every privileged request.
- The first administrator is seeded through a trusted manual migration/dashboard operation.
- No authority may be derived from user-controlled metadata.

## AdminAuthAudit (`private.admin_auth_audit`)

Minimal evidence for administrator account operations.

**Fields**
- `id uuid primary key`: generated audit identifier.
- `action text not null`: `create_user` or `reset_password`.
- `actor_user_id uuid not null`: administrator initiating the action.
- `target_user_id uuid nullable`: affected user when known.
- `result text not null`: `succeeded` or a stable failure category.
- `correlation_id uuid not null`: request tracing identifier.
- `created_at timestamptz not null`: server timestamp.

**Rules**
- Written only by trusted server-side code.
- Never contains email passwords, password hashes, access/refresh tokens, or service secrets.
- Normal mobile users cannot read or mutate it.

## AuthSession

Supabase-managed renewable authenticated state persisted by the mobile SDK.

**Relevant attributes**
- Auth user identity.
- Access-token expiry and refresh capability.
- Authentication event type.

**Rules**
- The app does not create a custom session database table or manually persist tokens.
- A valid session plus a readable profile is required before private navigation.
- Expiry, revocation, or sign-out returns the app to unauthenticated state.
- Password replacement guarantees old credentials fail; existing-session revocation is not promised unless separately implemented and tested.

## State Transitions

### Authentication

```text
unknown -> checking_session
checking_session -> unauthenticated
checking_session -> loading_profile -> authenticated
loading_profile -> profile_failure
unauthenticated -> submitting_signup -> loading_profile -> authenticated
unauthenticated -> submitting_login -> loading_profile -> authenticated
submitting_signup -> unauthenticated_with_error
submitting_login -> unauthenticated_with_error
authenticated -> signing_out -> unauthenticated
authenticated -> unauthenticated       # expiry/revocation event
```

### Administrator Account Creation

```text
request_received -> caller_authenticated -> administrator_authorized
administrator_authorized -> auth_user_created -> profile_triggered -> success
request_received -> rejected_unauthenticated
caller_authenticated -> rejected_forbidden
administrator_authorized -> validation_or_duplicate_failure
```

### Administrator Password Reset

```text
request_received -> caller_authenticated -> administrator_authorized
administrator_authorized -> password_replaced -> success
request_received -> rejected_unauthenticated
caller_authenticated -> rejected_forbidden
administrator_authorized -> validation_or_target_failure
```
