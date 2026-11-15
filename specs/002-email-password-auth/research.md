# Research: Email and Password Authentication

## Supabase Auth as Credential Owner

**Decision**: Use Supabase Auth `signUp`, `signInWithPassword`, persisted session restoration, auth-state events, and `signOut`. Disable email confirmation and support no OTP, magic link, recovery email, or OAuth provider.

**Rationale**: This directly implements the clarified email/password-only flow and prevents the application database from handling readable passwords or password hashes.

**Alternatives considered**: A custom password table was rejected as unsafe duplication. Google, OTP, magic links, and verification/recovery emails were rejected by scope.

## Session Bootstrap and Route Protection

**Decision**: Initialize Supabase before rendering private navigation, resolve the persisted current session, subscribe to auth-state changes, and use one application-level AuthCubit/session gate to choose authentication or signed-in navigation.

**Rationale**: Supabase manages secure token persistence and renewal. A single gate prevents private-content flashes and route bypasses after expiry or sign-out.

**Alternatives considered**: Manual token storage was rejected as risky. Per-screen auth checks were rejected because they duplicate policy and leave bypass gaps.

## Auth MVVM Boundary

**Decision**: Views own controllers, focus, password visibility, and presentation only. AuthCubit owns mode, submission, bootstrap, session, profile readiness, and mapped failure states. AuthRepository abstracts Supabase Auth and profile reads.

**Rationale**: This satisfies the constitution while keeping the small feature simple. Cubit reacts to repository auth events and exposes no password in state.

**Alternatives considered**: Empty one-method use-case wrappers were rejected under YAGNI. Direct Supabase calls from widgets or Cubit were rejected because they prevent clean testing and violate boundaries.

## Atomic Profile Provisioning

**Decision**: Add an `AFTER INSERT` trigger on `auth.users` that invokes a schema-qualified `SECURITY DEFINER` function and inserts exactly one `public.profiles` row using the auth ID and validated display-name metadata.

**Rationale**: Self-registration and administrator-created accounts share one invariant. Trigger failure blocks account creation instead of leaving a usable auth account with no profile.

**Alternatives considered**: Client-side profile insertion was rejected because app/network failure can orphan the identity. Edge Functions inserting profiles separately were rejected as duplicate provisioning logic.

## Profile Privacy

**Decision**: Enable RLS and allow an authenticated user to select/update only their own profile. Clients cannot insert/delete profiles or edit identity/timestamp fields. Email remains Auth-owned and is not duplicated in `profiles`.

**Rationale**: Stable UUID identity supports current data ownership and future notification references while minimizing personal data duplication.

**Alternatives considered**: Public profiles and email-keyed relationships were rejected for privacy and mutability. Notification fields were deferred to the separate notifications feature.

## Global Administrator Authorization

**Decision**: Store global application administrators in a protected `app_admins` table distinct from Quran group organizer membership. Seed the first administrator manually through a trusted database operation.

**Rationale**: Account creation and password reset are application-wide security powers. Group organizer status must not grant them, and user-editable metadata must never confer admin rights.

**Alternatives considered**: User metadata was rejected because users can influence it. JWT claims were deferred because they add hooks, refresh, and stale-claim complexity.

## Privileged Account Operations

**Decision**: Provide authenticated `admin-create-user` and `admin-reset-password` Edge Functions. Each validates the caller session, checks `app_admins`, validates the payload, then uses a server-only admin client. Account creation auto-confirms the email without sending mail; reset directly replaces the password.

**Rationale**: Supabase admin APIs require a service secret that bypasses RLS and must never ship in Flutter. Separate functions keep permissions and audits explicit.

**Alternatives considered**: Service-role use in Flutter was rejected categorically. Invitation/reset-email methods were rejected because they send email. Database-only password manipulation was rejected because Auth owns credentials.

## Administrator User Experience

**Decision**: Do not add an administrator console to the mobile app. Administrators use a trusted operational client or dashboard that calls the functions; the user app only shows contact-administrator guidance.

**Rationale**: This fulfills the backend capability without expanding the mobile feature into account administration screens.

**Alternatives considered**: An in-app admin console is a separate future feature. Manual password manipulation is unsafe and unsupported.

## Simple Arabic Form UX

**Decision**: Use one scrollable, keyboard-safe Auth Entry screen with Login and Create Account modes. Login has email/password; signup adds display name and confirmation. Email is LTR, surrounding UI is RTL. Validate on submit, disable duplicate submissions, show inline plus summary errors, and clear password fields after failed submissions.

**Rationale**: This is the fewest screens while remaining accessible and clear. A static forgotten-password line directs users to an administrator.

**Alternatives considered**: Separate routes and modal signup add navigation complexity. Per-keystroke validation and strength meters were rejected as noisy and beyond the minimum eight-character rule.

## Error, Security, and Audit Behavior

**Decision**: Map login failures to non-revealing Arabic messages; distinguish network, rate-limit, invalid-session, and missing-profile states internally. Never log passwords, tokens, or service secrets. Record privileged action, actor, target, result, timestamp, and correlation ID without credential material.

**Rationale**: Users receive actionable recovery without account enumeration, while administrators retain operational evidence.

**Alternatives considered**: Raw Supabase errors and verbose client logging were rejected because they leak implementation/security details.

## Password Reset Session Tradeoff

**Decision**: The required outcome is that the previous password stops authenticating and the replacement works. Existing issued sessions are not claimed to be revoked by this feature unless a supported revocation step is selected and tested during implementation.

**Rationale**: Credential replacement and session revocation are distinct. The specification requires the former only, so the plan avoids an unsupported security promise.

**Alternatives considered**: Claiming all devices are logged out was rejected without a verified server-side revocation mechanism.
