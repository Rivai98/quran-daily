import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../data_sources/supabase_auth_data_source.dart';
import '../data_sources/google_auth_client.dart';
import '../entities/app_user.dart';
import '../entities/user_profile.dart';
import 'auth_repository.dart';

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.dataSource, required this.googleAuthClient});

  final SupabaseAuthDataSource dataSource;
  final GoogleAuthClient googleAuthClient;

  @override
  String? get currentUserId => dataSource.currentUserId();

  @override
  Stream<String?> watchAuthState() => dataSource.watchUserIds();

  @override
  Future<Result<AuthenticatedUser>> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final normalized = _validate(
      displayName: displayName,
      email: email,
      password: password,
    );
    if (normalized == null) {
      return const FailureResult(
        AuthFailure(message: 'invalid input', code: 'validation_failed'),
      );
    }

    try {
      final session = await dataSource.signUp(
        email: normalized.$2,
        password: password,
        displayName: normalized.$1,
      );
      // Some hosted configurations create the account already confirmed but
      // return no session at signup; fall back to a password sign-in so the
      // user lands authenticated either way.
      if (session == null && dataSource.currentUserId() == null) {
        await dataSource.signIn(email: normalized.$2, password: password);
      }
      return _authenticatedResult(email: normalized.$2);
    } catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  @override
  Future<Result<AuthenticatedUser>> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null || password.isEmpty) {
      return const FailureResult(
        AuthFailure(message: 'invalid input', code: 'validation_failed'),
      );
    }

    try {
      await dataSource.signIn(email: normalizedEmail, password: password);
      return _authenticatedResult(email: normalizedEmail);
    } catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  @override
  Future<Result<AuthenticatedUser>?> signInWithGoogle() async {
    try {
      final tokens = await googleAuthClient.authenticate();
      if (tokens == null) return null;
      final idToken = tokens.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const FailureResult(AuthFailure(
          message: 'missing Google ID token', code: 'google_auth_failed'));
      }
      await dataSource.signInWithGoogleIdToken(idToken: idToken);
      final userId = currentUserId;
      if (userId == null) {
        return const FailureResult(AuthFailure(
          message: 'no session', code: 'unauthenticated'));
      }
      final profile = await loadCurrentProfile();
      return profile.when(
        success: (value) => Success(AuthenticatedUser(
          user: AppUser(id: userId, email: ''), profile: value)),
        failure: FailureResult.new,
      );
    } catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  @override
  Future<Result<UserProfile>> loadCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) {
      return const FailureResult(
        AuthFailure(message: 'no session', code: 'unauthenticated'),
      );
    }
    try {
      final profile = UserProfile.fromRow(await dataSource.selectProfile(userId));
      if (profile == null) {
        return const FailureResult(
          AuthFailure(message: 'profile missing', code: 'missing_profile'),
        );
      }
      return Success(profile);
    } catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await dataSource.signOut();
      await googleAuthClient.signOut();
      return const Success<void>(null);
    } catch (error) {
      return FailureResult(_mapError(error));
    }
  }

  Future<Result<AuthenticatedUser>> _authenticatedResult({
    required String email,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      return const FailureResult(
        AuthFailure(message: 'no session', code: 'unauthenticated'),
      );
    }
    final profileResult = await loadCurrentProfile();
    return profileResult.when(
      success: (profile) => Success(
        AuthenticatedUser(
          user: AppUser(id: userId, email: email),
          profile: profile,
        ),
      ),
      failure: (failure) => FailureResult(failure),
    );
  }

  (String, String)? _validate({
    required String displayName,
    required String email,
    required String password,
  }) {
    final name = displayName.trim();
    final normalizedEmail = _normalizeEmail(email);
    if (name.isEmpty || name.length > 100) return null;
    if (normalizedEmail == null) return null;
    if (password.length < 8) return null;
    return (name, normalizedEmail);
  }

  String? _normalizeEmail(String raw) {
    final email = raw.trim().toLowerCase();
    if (!_emailRe.hasMatch(email) || email.length > 254) return null;
    return email;
  }

  /// Maps provider errors to stable, NON-REVEALING codes; the original
  /// message never leaves this layer.
  AppFailure _mapError(Object error) {
    final code = _providerCode(error);

    if (code == 'user_banned' || code == 'banned' ||
        error.toString().toLowerCase().contains('banned')) {
      return const AuthFailure(message: 'account suspended', code: 'suspended');
    }

    switch (code) {
      case 'user_already_exists':
      case 'email_exists':
        return const AuthFailure(
            message: 'email already registered', code: 'email_exists');
      case 'invalid_credentials':
        return const AuthFailure(
            message: 'credentials rejected', code: 'invalid_credentials');
      case 'weak_password':
        return const AuthFailure(
            message: 'invalid input', code: 'validation_failed');
      case 'over_request_rate_limit':
      case 'rate_limited':
        return const AuthFailure(
            message: 'too many attempts', code: 'rate_limited');
    }

    final text = error.toString();
    if (code == 'network' ||
        text.contains('SocketException') ||
        text.contains('fetch failed') ||
        text.contains('ClientException') ||
        text.contains('TimeoutException') ||
        text.contains('Failed to fetch')) {
      return const AuthFailure(
          message: 'network unreachable', code: 'network');
    }

    return const AuthFailure(message: 'unexpected error', code: 'unknown');
  }

  String? _providerCode(Object error) {
    try {
      final dynamic coded = error;
      return coded.code as String?;
    } catch (_) {
      return null;
    }
  }
}
