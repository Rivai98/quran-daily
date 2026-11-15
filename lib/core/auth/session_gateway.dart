import '../errors/result.dart';

/// Core interface so feature modules never import `features/auth`
/// (constitution Principle IV). Implemented by `AuthRepositoryImpl` and
/// registered in DI under both types.
abstract class SessionGateway {
  /// Stable id of the signed-in user, or null when unauthenticated.
  String? get currentUserId;

  /// Ends the current session.
  Future<Result<void>> signOut();
}
