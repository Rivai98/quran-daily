# Feature Specification: Email and Password Authentication

**Feature Branch**: `[002-email-password-auth]`

**Created**: 2026-08-13

**Status**: Draft

**Input**: User description: "Make login using email and password, store accounts in the database using Supabase, and explain what is needed to set up accounts and the database."

## Clarifications

### Session 2026-08-13

- Q: Who may create user accounts? → A: Both administrators and users may create accounts.
- Q: How are forgotten passwords recovered without email codes? → A: An administrator resets the user's password.
- Q: Are mobile push notifications part of this authentication feature? → A: No; push notifications will be implemented as a separate feature.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create an Account (Priority: P1)

A new user creates an account with a display name, email address, and password so they can securely access the Quran group features from their own identity.

**Why this priority**: Account creation is the entry point for users who do not already have an account and provides the stable identity required for group membership and reading progress.

**Independent Test**: A new user can submit valid details, receive a signed-in account, and later find the same profile associated with that account.

**Acceptance Scenarios**:

1. **Given** an email address that is not registered, **When** the user submits a valid display name, email address, and password, **Then** an account and linked profile are created and the user enters the signed-in experience.
2. **Given** an email address that is already registered, **When** the user attempts to create another account with it, **Then** no duplicate account is created and the user receives a clear Arabic message directing them to sign in or contact an administrator.
3. **Given** invalid or incomplete account details, **When** the user submits the form, **Then** the account is not created and each invalid field receives clear Arabic guidance.
4. **Given** an authorized administrator, **When** the administrator supplies valid user details, **Then** an account and linked profile are created for that user.

---

### User Story 2 - Sign In and Resume a Session (Priority: P1)

A returning user signs in with their email address and password and remains signed in across normal app restarts until they sign out or their session can no longer be renewed.

**Why this priority**: Returning users need reliable access to their memberships, assignments, and personal progress.

**Independent Test**: An existing user can sign in, close and reopen the app, remain authenticated, and reach the appropriate post-login screen.

**Acceptance Scenarios**:

1. **Given** an existing account, **When** the user submits the correct email address and password, **Then** the user is authenticated and routed to the appropriate signed-in screen.
2. **Given** an incorrect email address or password, **When** the user attempts to sign in, **Then** access is denied and a non-revealing Arabic error explains how to retry or contact an administrator.
3. **Given** a valid renewable session, **When** the user reopens the app, **Then** the session is restored without requiring the password again.
4. **Given** an expired or invalid session, **When** the user reopens the app, **Then** private content remains unavailable and the user is returned to the authentication screen.

---

### User Story 3 - Administrator Resets a Forgotten Password (Priority: P2)

An authorized administrator sets a replacement password for a user who cannot sign in, without sending an email code or recovery message.

**Why this priority**: It provides a simple recovery path without adding an email delivery flow.

**Independent Test**: An administrator can set a replacement password, after which the user can sign in with it and cannot use the previous password.

**Acceptance Scenarios**:

1. **Given** an existing user who forgot their password, **When** an authorized administrator sets a valid replacement password, **Then** the old password stops working and the replacement password allows sign-in.
2. **Given** an unauthenticated user or a normal user, **When** they attempt to reset another user's password, **Then** the operation is denied.

---

### User Story 4 - Sign Out Safely (Priority: P2)

A signed-in user signs out so another person using the device cannot access their private account information.

**Why this priority**: Sign-out is necessary for account privacy on shared or lost devices.

**Independent Test**: After signing out, the user returns to the authentication screen and cannot reopen private screens without signing in again.

**Acceptance Scenarios**:

1. **Given** a signed-in user, **When** the user confirms sign-out, **Then** the active session is removed, private navigation is blocked, and the authentication screen is shown.

### Edge Cases

- Leading and trailing spaces in email addresses are ignored, and email matching is case-insensitive.
- A display name containing only whitespace is rejected.
- A password that does not meet the published minimum rules is rejected before account creation or password change.
- Repeated submissions while a request is in progress do not create duplicate accounts.
- Loss of connectivity during account creation, sign-in, or sign-out produces a recoverable Arabic error and does not display a false success state.
- A profile-creation failure does not leave the user in a signed-in experience with an unusable or missing profile.
- Authentication errors do not reveal whether a particular email address has an account; administrator account tools may identify users only after authorization.
- Back navigation cannot bypass authentication and reveal private screens after sign-out or session expiry.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST allow a new user to create an account using a display name, email address, password, and password confirmation.
- **FR-002**: The system MUST normalize email input, validate required fields, require matching password entries, and enforce the configured password rules before submitting account creation.
- **FR-003**: The system MUST prevent more than one account from using the same normalized email address.
- **FR-004**: The system MUST create exactly one user profile linked to each successfully created account, containing the user's stable identifier, display name, and creation/update timestamps.
- **FR-005**: The system MUST keep password verification data separate from the user profile and MUST never store or display a readable password.
- **FR-006**: The system MUST allow an existing user to sign in using their email address and password.
- **FR-007**: The system MUST present authentication validation, failure, and confirmation messages in clear Arabic with right-to-left presentation.
- **FR-008**: The system MUST use non-revealing failure messages for invalid sign-in so an unauthenticated person cannot determine whether an email is registered.
- **FR-009**: The system MUST restore a valid renewable session after an app restart and route the user to the correct signed-in destination.
- **FR-010**: The system MUST block access to private screens and data when no valid session exists.
- **FR-011**: The system MUST allow only an authorized administrator to set a replacement password for a user who cannot sign in; the system MUST NOT send an authentication code or password-recovery message by email.
- **FR-012**: The system MUST allow a signed-in user to sign out and MUST prevent access to private screens using the ended local session.
- **FR-013**: The system MUST prevent duplicate submissions while an authentication operation is in progress and MUST provide visible progress feedback.
- **FR-014**: The system MUST preserve entered non-secret form values after a recoverable validation or network error while clearing password values when retaining them would create a privacy risk.
- **FR-015**: User profiles MUST be readable and editable only by the account owner unless a future feature explicitly grants another authorized role access.
- **FR-016**: Account creation, sign-in, administrator password reset, and sign-out MUST require network connectivity; cached Quran assignment access remains governed by the existing offline-resilient feature.
- **FR-017**: Email and password MUST be the only supported sign-in method; Google login, one-time email codes, and other sign-in providers are out of scope.
- **FR-018**: The authentication entry screen MUST let users choose between signing in and creating an account and MUST tell users with forgotten passwords to contact an administrator.
- **FR-019**: The system MUST allow both public self-registration and account creation by authorized administrators, applying the same uniqueness and profile-creation rules to both paths.
- **FR-020**: This feature MUST NOT register device notification tokens, request notification permission, or send notifications; a separate mobile push notification feature may reference the stable user and profile identifiers created here.

### Key Entities

- **User Account**: The secure sign-in identity, identified by a stable unique identifier and normalized email address; owns authentication status and credential lifecycle.
- **User Profile**: The app-visible information linked one-to-one with a user account, including display name and timestamps; it does not contain the user's password. Its stable identifier can be referenced by future features such as mobile push notifications.
- **User Session**: The time-bounded authenticated state that allows access to private app features and may be renewed until it expires, is revoked, or the user signs out.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At least 90% of first-time users can create an account successfully on their first attempt without assistance.
- **SC-002**: Users with valid details can complete account creation or sign-in within 60 seconds.
- **SC-003**: At least 95% of successful authentication actions show the signed-in destination or confirmation within 3 seconds under normal mobile connectivity.
- **SC-004**: In testing, 100% of attempts to open private screens after sign-out or session expiry are redirected to authentication without exposing private data.
- **SC-005**: In testing, every created account has exactly one linked profile, and no profile contains a readable password.
- **SC-006**: At least 90% of test users can identify the next action after an Arabic authentication error without assistance.
- **SC-007**: In testing, 100% of authorized administrator password resets allow the replacement password and reject the previous password.
- **SC-008**: Reopening the app with a valid renewable session requires no credential re-entry in at least 99% of tested normal restarts.

## Assumptions

- The feature targets the existing Arabic-first iOS and Android application.
- Public self-registration and authorized administrator account creation are both allowed; self-registered accounts do not require administrator approval.
- The initial password rule is a minimum of eight characters; stronger service-level protections may apply without changing the user journey.
- Email verification is not required and the authentication flow sends no email codes or recovery messages.
- Administrator password reset is included; self-service recovery, changing a known password, changing an email address, deleting an account, and multi-factor authentication are outside this feature.
- Email and password are the only sign-in method in this feature; Google login and email-code login are excluded.
- Mobile push notifications, device-token storage, notification permission requests, and notification preferences are outside this feature and will be specified separately.
- Authentication and administrator password reset require connectivity. Previously cached personal Quran assignments may remain available according to the existing offline-resilient rules, but no private shared data is refreshed without a valid session.
- The project owner will provide access to the selected hosted authentication and data environment before implementation and testing.
