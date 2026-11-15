import 'package:equatable/equatable.dart';

import '../data/entities/user_profile.dart';
import '../../../core/errors/failures.dart';

enum AuthMode { login, signup }

enum AuthStatus {
  checkingSession,
  unauthenticated,
  submitting,
  loadingProfile,
  authenticated,
  signingOut,
  failure,
  profileFailure,
}

/// Immutable auth state (spec 002). Never carries passwords, tokens,
/// Arabic copy, or BuildContext; the View maps [AuthFailure.code] to copy.
class AuthState extends Equatable {
  const AuthState({
    this.mode = AuthMode.login,
    this.status = AuthStatus.checkingSession,
    this.profile,
    this.failure,
  });

  final AuthMode mode;
  final AuthStatus status;
  final UserProfile? profile;
  final AppFailure? failure;

  AuthState copyWith({
    AuthMode? mode,
    AuthStatus? status,
    UserProfile? profile,
    bool clearProfile = false,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return AuthState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [mode, status, profile, failure];
}
