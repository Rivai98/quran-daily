import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/widgets.dart';
import '../../../core/localization/arabic_strings.dart';
import '../cubit/auth_cubit.dart';

/// Two-mode auth entry (spec 002): login / create account. Email content
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
    if (_confirmationError != null &&
        _confirmation.text == _password.text) {
      setState(() => _confirmationError = null);
    }
  }

  bool _validEmail(String raw) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(raw.trim());

  bool _validateLogin() {
    setState(() {
      _emailError =
          _validEmail(_email.text) ? null : ArabicStrings.invalidEmailError;
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
      _emailError =
          _validEmail(_email.text) ? null : ArabicStrings.invalidEmailError;
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
    final ok =
        mode == AuthMode.signup ? _validateSignup() : _validateLogin();
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
                icon: Icons.person_off_outlined,
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
                padding: AppSpacing.screen,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      Icon(Icons.menu_book, size: 72, color: colors.primary),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        ArabicStrings.appName,
                        textAlign: TextAlign.center,
                        style: AppTypography.headline,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        ArabicStrings.signInHint,
                        textAlign: TextAlign.center,
                        style:
                            AppTypography.body.copyWith(color: colors.inkMuted),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ModeToggle(enabled: !submitting),
                      const SizedBox(height: AppSpacing.md),
                      if (state.mode == AuthMode.signup) ...[
                        AppTextField(
                          label: ArabicStrings.displayNameLabel,
                          controller: _displayName,
                          errorText: _displayNameError,
                          prefixIcon: Icons.person_outline,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      AppTextField(
                        label: ArabicStrings.emailLabel,
                        controller: _email,
                        errorText: _emailError,
                        hint: 'name@example.com',
                        ltr: true,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        label: ArabicStrings.passwordLabel,
                        controller: _password,
                        errorText: _passwordError,
                        hint: ArabicStrings.passwordHint,
                        obscure: true,
                        prefixIcon: Icons.lock_outline,
                      ),
                      if (state.mode == AuthMode.signup) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          label: ArabicStrings.confirmPasswordLabel,
                          controller: _confirmation,
                          errorText: _confirmationError,
                          obscure: true,
                          prefixIcon: Icons.lock_outline,
                        ),
                      ],
                      if (state.status == AuthStatus.failure &&
                          state.failure != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _ErrorBanner(
                            message:
                                ArabicStrings.authError(state.failure!.code)),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: state.mode == AuthMode.login
                            ? ArabicStrings.signInTitle
                            : ArabicStrings.createAccountTitle,
                        onPressed: submitting
                            ? null
                            : () => _submit(context.read<AuthCubit>()),
                        loading: submitting,
                        expanded: true,
                        icon: const Icon(Icons.login),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 20, color: colors.inkMuted),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              ArabicStrings.forgotPasswordGuidance,
                              style: AppTypography.caption
                                  .copyWith(color: colors.inkMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: ShapeDecoration(
        color: colors.missedBg,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBR,
          side: BorderSide(color: colors.danger.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: colors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style:
                    AppTypography.caption.copyWith(color: colors.danger)),
          ),
        ],
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
              backgroundColor:
                  selected ? colors.primaryContainer : colors.surface,
              foregroundColor:
                  selected ? colors.onPrimaryContainer : colors.inkMuted,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(AppRadius.md)),
              ),
            ),
            child: Text(label),
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
