import 'package:equatable/equatable.dart';

import 'user_profile.dart';

/// Auth identity (spec 002). No password material ever lives here.
class AppUser extends Equatable {
  const AppUser({required this.id, required this.email});

  final String id;
  final String email;

  @override
  List<Object?> get props => [id, email];
}

/// Signed-in identity with its freshly loaded profile. Successful auth is
/// never exposed as ready until the matching profile loads (spec 002).
class AuthenticatedUser extends Equatable {
  const AuthenticatedUser({required this.user, required this.profile});

  final AppUser user;
  final UserProfile profile;

  @override
  List<Object?> get props => [user, profile];
}
