import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/widgets.dart';
import '../../../core/localization/arabic_strings.dart';
import '../cubit/auth_cubit.dart';

/// Two-mode auth entry (spec 002 & Polish D): login / create account. Email content
/// renders LTR inside its own field while the page stays Arabic RTL.
class AuthEntryScreen extends StatefulWidget {
  const AuthEntryScreen({super.key});

  @override
  State<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends State<AuthEntryScreen> {
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  String? _displayNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmationError;

  @override
  void initState() {
    super.initState();
    // Revalidate a changed invalid field after edits (ui-contract).
    _displayName.addListener(_refreshDisplayNameError);
    _email.addListener(_refreshEmailError);
    _password.addListener(_refreshPasswordError);
    _confirmation.addListener(_refreshConfirmationError);
  }

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _refreshDisplayNameError() {
    if (_displayNameError != null && _displayName.text.trim().isNotEmpty) {
      setState(() => _displayNameError = null);
    }
  }

  void _refreshEmailError() {
    if (_emailError != null && _validEmail(_email.text)) {
      setState(() => _emailError = null);
    }
  }

  void _refreshPasswordError() {
    if (_passwordError != null && _password.text.length >= 8) {
      setState(() => _passwordError = null);
    }
  }

  void _refreshConfirmationError() {
    if (_confirmationError != null && _confirmation.text == _password.text) {
      setState(() => _confirmationError = null);
    }
  }

  bool _validEmail(String raw) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(raw.trim());

  bool _validateLogin() {
    setState(() {
      _emailError = _validEmail(_email.text)
          ? null
          : ArabicStrings.invalidEmailError;
      _passwordError = _password.text.isEmpty
          ? ArabicStrings.requiredFieldError
          : null;
    });
    return _emailError == null && _passwordError == null;
  }

  bool _validateSignup() {
    setState(() {
      _displayNameError = _displayName.text.trim().isEmpty
          ? ArabicStrings.displayNameError
          : null;
      _emailError = _validEmail(_email.text)
          ? null
          : ArabicStrings.invalidEmailError;
      _passwordError = _password.text.length < 8
          ? ArabicStrings.shortPasswordError
          : null;
      _confirmationError = _confirmation.text != _password.text
          ? ArabicStrings.passwordMismatchError
          : null;
    });
    return _displayNameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmationError == null;
  }

  void _submit(AuthCubit cubit) {
    final mode = cubit.state.mode;
    final ok = mode == AuthMode.signup ? _validateSignup() : _validateLogin();
    if (!ok) return;

    if (mode == AuthMode.signup) {
      cubit.submitSignup(
        displayName: _displayName.text,
        email: _email.text,
        password: _password.text,
        confirmation: _confirmation.text,
      );
    } else {
      cubit.submitLogin(email: _email.text, password: _password.text);
    }

    // Clear password values after submission (ui-contract); non-secret
    // values are preserved.
    _password.clear();
    _confirmation.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.failure) {
              setState(() {
                _password.clear();
                _confirmation.clear();
              });
            }
          },
          builder: (context, state) {
            if (state.status == AuthStatus.profileFailure) {
              return StatePanel(
                icon: Icons.person_off_rounded,
                title: ArabicStrings.profileLoadTitle,
                message: ArabicStrings.authError('missing_profile'),
                actionLabel: ArabicStrings.retry,
                onAction: () => context.read<AuthCubit>().retryProfileLoad(),
                actionVariant: AppButtonVariant.secondary,
              );
            }

            final submitting = state.status == AuthStatus.submitting;

            return Center(
              child: SingleChildScrollView(
                padding: AppSpacing.screenH,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: AppRadius.lgBR,
                        child: IslamicOrnamentBand(
                          height: 112,
                          contentPadding: AppSpacing.sm,
                          refined: true,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HalaqaLogo(size: 48),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                ArabicStrings.appName,
                                textAlign: TextAlign.center,
                                style: AppTypography.headline.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                ArabicStrings.signInHint,
                                textAlign: TextAlign.center,
                                style: AppTypography.caption.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ModeToggle(enabled: !submitting),
                            const SizedBox(height: AppSpacing.md),
                            if (state.mode == AuthMode.signup) ...[
                              AppTextField(
                                key: const ValueKey('auth-displayName'),
                                label: ArabicStrings.displayNameLabel,
                                controller: _displayName,
                                errorText: _displayNameError,
                                prefixIcon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            AppTextField(
                              key: const ValueKey('auth-email'),
                              label: ArabicStrings.emailLabel,
                              controller: _email,
                              errorText: _emailError,
                              hint: 'name@example.com',
                              ltr: true,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              prefixIcon: Icons.mail_outline_rounded,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              key: const ValueKey('auth-password'),
                              label: ArabicStrings.passwordLabel,
                              controller: _password,
                              errorText: _passwordError,
                              hint: ArabicStrings.passwordHint,
                              obscure: true,
                              prefixIcon: Icons.lock_outline_rounded,
                              textInputAction: state.mode == AuthMode.login
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              autofillHints: state.mode == AuthMode.login
                                  ? const [AutofillHints.password]
                                  : const [AutofillHints.newPassword],
                              onSubmitted: state.mode == AuthMode.login
                                  ? (_) => _submit(context.read<AuthCubit>())
                                  : null,
                            ),
                            if (state.mode == AuthMode.signup) ...[
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                key: const ValueKey('auth-confirmation'),
                                label: ArabicStrings.confirmPasswordLabel,
                                controller: _confirmation,
                                errorText: _confirmationError,
                                obscure: true,
                                prefixIcon: Icons.lock_outline_rounded,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) =>
                                    _submit(context.read<AuthCubit>()),
                              ),
                            ],
                            if (state.status == AuthStatus.failure &&
                                state.failure != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              AppBanner.error(
                                message: ArabicStrings.authError(
                                  state.failure!.code,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: state.mode == AuthMode.login
                                  ? ArabicStrings.signInTitle
                                  : ArabicStrings.createAccountTitle,
                              onPressed: submitting
                                  ? null
                                  : () => _submit(context.read<AuthCubit>()),
                              loading: submitting,
                              expanded: true,
                              icon: const Icon(Icons.login_rounded),
                            ),
                            if (context
                                .read<AuthCubit>()
                                .googleSignInEnabled) ...[
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: colors.border),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
                                          horizontal: AppSpacing.md,
                                        ),
                                    child: Text(
                                      ArabicStrings.or,
                                      style: AppTypography.caption.copyWith(
                                        color: colors.inkMuted,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: colors.border),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AppButton(
                                label: ArabicStrings.googleSignIn,
                                variant: AppButtonVariant.secondary,
                                expanded: true,
                                onPressed: submitting
                                    ? null
                                    : () => context
                                          .read<AuthCubit>()
                                          .signInWithGoogle(),
                                icon: const Icon(Icons.g_mobiledata),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (state.mode == AuthMode.login) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: colors.inkMuted,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                ArabicStrings.forgotPasswordGuidance,
                                style: AppTypography.caption.copyWith(
                                  color: colors.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final mode = context.select((AuthCubit cubit) => cubit.state.mode);

    Widget segment(AuthMode value, String label) {
      final selected = mode == value;
      return Expanded(
        child: AbsorbPointer(
          absorbing: !enabled,
          child: TextButton(
            onPressed: () => value == AuthMode.login
                ? context.read<AuthCubit>().showLogin()
                : context.read<AuthCubit>().showSignup(),
            style: TextButton.styleFrom(
              backgroundColor: selected
                  ? colors.primaryContainer
                  : colors.surface,
              foregroundColor: selected
                  ? colors.onPrimaryContainer
                  : colors.inkMuted,
              minimumSize: const Size(64, 48),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
              ),
            ),
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                color: selected ? colors.onPrimaryContainer : colors.inkMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: ShapeDecoration(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBR,
          side: BorderSide(color: colors.border),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: Row(
        children: [
          segment(AuthMode.login, ArabicStrings.signInTitle),
          const SizedBox(width: AppSpacing.xxs),
          segment(AuthMode.signup, ArabicStrings.createAccountTitle),
        ],
      ),
    );
  }
}
