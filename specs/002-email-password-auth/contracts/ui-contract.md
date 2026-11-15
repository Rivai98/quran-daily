# Contract: Arabic Email and Password UI

## App Startup Gate

**Purpose**: Resolve the persisted session before showing authentication or private content.

**States**
- Checking: neutral full-screen progress with an Arabic semantic label.
- Unauthenticated: show Auth Entry.
- Authenticated and profile ready: show the existing signed-in destination.
- Invalid/expired session: clear private navigation and show Auth Entry.
- Profile unavailable: block private content and show retry/contact-administrator guidance.

Private content must never flash before the decision finishes.

## Auth Entry Screen

Use one scrollable SafeArea screen with two modes:

### Login

- Email field.
- Password field with accessible show/hide action.
- Primary `تسجيل الدخول` action.
- Mode switch to `إنشاء حساب`.
- Static guidance: forgotten-password users contact the application administrator. It is not an email/recovery action.

### Create Account

- Display-name field.
- Email field.
- Password field.
- Confirm-password field.
- Primary `إنشاء حساب` action.
- Mode switch to `تسجيل الدخول`.

## Form Behavior

- Page and labels are RTL; email content is LTR and start-aligned for readability.
- Use email keyboard/autofill hints and password autofill hints.
- Validate on submit, focus/announce the first invalid field, then revalidate invalid fields after edits.
- Preserve display name/email after recoverable failure; clear password fields after submission failure or unsafe navigation.
- Disable primary action and mode switching during submission and show progress in the primary action.
- Keyboard, SafeArea, smallest phone width, and 200% text scale must not hide actions or cause overflow.

## Error Contract

- Invalid login: one non-revealing Arabic message instructing the user to check email/password or contact an administrator.
- Duplicate signup: direct the user to login or contact an administrator.
- Network/offline: explain connectivity and provide retry without false success.
- Rate limit: explain that the user must wait before retrying.
- Missing profile: block entry and offer retry/contact administrator.
- Errors appear next to relevant fields and/or in a semantic summary; color is not the only indicator.

## Navigation and Sign-Out

- Successful signup/login replaces auth with the existing group-selection destination.
- Every private route is centrally guarded by live AuthCubit state.
- Sign-out remains available from settings, uses confirmation, and replaces the full private stack with Auth Entry.
- System back and deep links cannot reopen private widgets after sign-out or expiry.

## Accessibility

- Arabic glyphs render correctly and traversal follows logical RTL order.
- Normal text meets WCAG 2.1 AA contrast.
- Interactive targets are at least 48x48 logical pixels.
- Password visibility, loading, and error controls have semantic labels.
- Layout works at 320 logical-pixel width and 200% text scaling.

## Exclusions Visible in UI

- No Google button.
- No email code, verification, magic-link, or reset-email control.
- No mobile administrator account-management UI.
- No notification permission prompt, token registration, or notification settings.
