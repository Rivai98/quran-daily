# Contract: Authentication Repository and Cubit

## AuthRepository

The repository is the boundary between AuthCubit and Supabase Auth/profile storage.

**Methods**
- `currentSession() -> AuthSession?`
- `watchAuthState() -> Stream<AuthSession?>`
- `signUp(displayName, email, password) -> Result<AuthenticatedUser>`
- `signIn(email, password) -> Result<AuthenticatedUser>`
- `loadCurrentProfile() -> Result<UserProfile>`
- `signOut() -> Result<void>`

**Rules**
- Normalize email consistently before authentication requests.
- Never return, retain, emit, or log password values.
- Signup does not insert the profile; the database trigger provisions it.
- Successful auth is not exposed as ready until the matching profile loads.
- Map provider-specific errors to stable categories: validation, invalid credentials, duplicate email, network, rate limited, missing profile, permission, and unknown.
- Login errors shown to unauthenticated users remain non-revealing.
- Only one mutation may be in flight per AuthCubit.
- `AuthRepositoryImpl` also implements the core interface `SessionGateway`
  (`lib/core/auth/session_gateway.dart`: `currentUserId`, `signOut()`), so other
  features (quran_groups, settings) depend on `lib/core` instead of importing
  `features/auth` (constitution Principle IV; spec 001 repository contracts).

## AuthCubit

One application-level ViewModel owns authentication bootstrap and entry-form state.

**Commands**
- `bootstrap()`
- `showLogin()`
- `showSignup()`
- `submitLogin(email, password)`
- `submitSignup(displayName, email, password, confirmation)`
- `retryProfileLoad()`
- `signOut()`

**Observable state**
- Mode: `login` or `signup`.
- Status: `checkingSession`, `unauthenticated`, `submitting`, `loadingProfile`, `authenticated`, `failure`, or `profileFailure`.
- Authenticated user/profile identity when ready.
- Display-safe Arabic failure category/message key.
- Submission enabled/disabled state.

**Rules**
- State never contains a password or token.
- Cubit subscribes to repository auth changes and cancels the subscription on close.
- A missing/failed profile blocks private navigation.
- Duplicate submit calls while `submitting` are ignored.
- Views own text controllers, focus, and password visibility only.

## Validation Contract

- Display name: trim; require 1-100 non-whitespace characters.
- Email: trim, case-normalize for identity, and require plausible email syntax.
- Password: at least 8 characters.
- Confirmation: exact match with password.
- Validate on submit and revalidate a changed invalid field.
- Client and server validate independently; client validation is not an authorization boundary.

## Authentication Gate Contract

- Render a neutral full-screen checking state until bootstrap resolves.
- `authenticated` with a loaded profile opens the existing signed-in destination.
- All other states block private routes.
- Logout and expiry replace the private navigation stack with auth.
- Back navigation and deep links cannot rebuild private content while unauthenticated.
- Offline login/signup fail recoverably; the separate cached Quran assignment policy is unchanged.

## Explicit Exclusions

- No Google/OAuth repository method.
- No OTP, magic-link, verification-email, or reset-email method.
- No client administrator method using a service-role key.
- No notification-token registration or permission method.
