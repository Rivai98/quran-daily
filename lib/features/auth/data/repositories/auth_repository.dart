import '../../../../core/auth/session_gateway.dart';
import '../../../../core/errors/result.dart';
import '../entities/app_user.dart';
import '../entities/user_profile.dart';

/// Auth boundary (spec 002 repository contract). All methods normalize
/// emails, never surface password material, and map provider errors to
/// stable non-revealing codes.
abstract class AuthRepository implements SessionGateway {
  Future<Result<AuthenticatedUser>> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  Future<Result<AuthenticatedUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<UserProfile>> loadCurrentProfile();

  @override
  Future<Result<void>> signOut();

  /// Emits the signed-in user id, or null on expiry/revocation/sign-out.
  Stream<String?> watchAuthState();
}
