import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/auth_repository.dart';
import '../data/entities/app_user.dart';
import '../data/entities/user_profile.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import 'auth_state.dart';

export 'auth_state.dart';

/// One application-level auth ViewModel (spec 002): session bootstrap,
/// entry-form mode, submit guards, sign-out, and expiry events.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository repository, this.googleSignInEnabled = false})
      : _repository = repository,
        super(const AuthState()) {
    _subscription = _repository.watchAuthState().listen(_onAuthEvent);
  }

  final AuthRepository _repository;
  final bool googleSignInEnabled;
  late final StreamSubscription<String?> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }

  String? _lastUserId;

  void _onAuthEvent(String? userId) {
    // Server-side expiry/revocation/sign-out from another flow: only act
    // when we actually drop from signed-in to signed-out, and never
    // override an in-flight submit.
    final wasSignedIn = _lastUserId != null;
    _lastUserId = userId;
    if (userId == null && wasSignedIn && !isClosed) {
      if (state.status == AuthStatus.submitting ||
          state.status == AuthStatus.signingOut) {
        return;
      }
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        mode: AuthMode.login,
        clearProfile: true,
        clearFailure: true,
      ));
    }
  }

  /// Resolves the persisted session before private navigation opens.
  Future<void> bootstrap() async {
    emit(state.copyWith(status: AuthStatus.checkingSession, clearFailure: true));
    final userId = _repository.currentUserId;
    _lastUserId = userId;
    if (userId == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }
    await _loadProfile();
  }

  void showLogin() =>
      emit(state.copyWith(mode: AuthMode.login, clearFailure: true));

  void showSignup() =>
      emit(state.copyWith(mode: AuthMode.signup, clearFailure: true));

  Future<void> submitLogin({
    required String email,
    required String password,
  }) async {
    if (state.status == AuthStatus.submitting) return;
    if (!_validEmail(email) || password.isEmpty) {
      _failValidation();
      return;
    }
    await _submit(() => _repository.signIn(email: email, password: password));
  }

  Future<void> submitSignup({
    required String displayName,
    required String email,
    required String password,
    required String confirmation,
  }) async {
    if (state.status == AuthStatus.submitting) return;
    if (displayName.trim().isEmpty || !_validEmail(email)) {
      _failValidation();
      return;
    }
    if (password.length < 8) {
      _failValidation('validation_failed');
      return;
    }
    if (password != confirmation) {
      _failValidation('password_mismatch');
      return;
    }
    await _submit(() => _repository.signUp(
          displayName: displayName,
          email: email,
          password: password,
        ));
  }

  Future<void> signInWithGoogle() async {
    if (state.status == AuthStatus.submitting) return;
    emit(state.copyWith(status: AuthStatus.submitting, clearFailure: true));
    final result = await _repository.signInWithGoogle();
    if (result == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearFailure: true));
      return;
    }
    result.when(
      success: (user) => emit(state.copyWith(
        status: AuthStatus.authenticated, profile: user.profile)),
      failure: (failure) => emit(state.copyWith(
        status: AuthStatus.failure, failure: failure)),
    );
  }

  Future<void> retryProfileLoad() async {
    if (_repository.currentUserId == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }
    await _loadProfile();
  }

  Future<void> signOut() async {
    emit(state.copyWith(status: AuthStatus.signingOut));
    await _repository.signOut();
    _lastUserId = null;
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      mode: AuthMode.login,
      clearProfile: true,
      clearFailure: true,
    ));
  }

  Future<void> _loadProfile() async {
    emit(state.copyWith(status: AuthStatus.loadingProfile, clearFailure: true));
    final result = await _repository.loadCurrentProfile();
    result.when(
      success: (UserProfile profile) =>
          emit(state.copyWith(status: AuthStatus.authenticated, profile: profile)),
      failure: (AppFailure failure) => emit(state.copyWith(
            status: AuthStatus.profileFailure,
            failure: failure,
          )),
    );
  }

  Future<void> _submit(
      Future<Result<AuthenticatedUser>> Function() call) async {
    emit(state.copyWith(status: AuthStatus.submitting, clearFailure: true));
    final result = await call();
    result.when(
      success: (AuthenticatedUser authenticated) => emit(state.copyWith(
            status: AuthStatus.authenticated,
            profile: authenticated.profile,
          )),
      failure: (AppFailure failure) => emit(state.copyWith(
            status: AuthStatus.failure,
            failure: failure,
          )),
    );
  }

  void _failValidation([String code = 'validation_failed']) {
    emit(state.copyWith(
      status: AuthStatus.failure,
      failure: AuthFailure(message: 'invalid input', code: code),
    ));
  }

  bool _validEmail(String raw) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(raw.trim());
}
