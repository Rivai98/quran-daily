import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin Supabase wrapper so the repository stays unit-testable and free of
/// provider types. Returns/throws raw provider shapes; mapping lives in
/// [AuthRepositoryImpl].
abstract class SupabaseAuthDataSource {
  Future<Object?> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<Object?> signIn({
    required String email,
    required String password,
  });

  String? currentUserId();

  Stream<String?> watchUserIds();

  Future<Map<String, dynamic>?> selectProfile(String userId);

  Future<void> signOut();
}

class SupabaseAuthDataSourceImpl implements SupabaseAuthDataSource {
  SupabaseAuthDataSourceImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<Object?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    return response.session;
  }

  @override
  Future<Object?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.session;
  }

  @override
  String? currentUserId() => _client.auth.currentSession?.user.id;

  @override
  Stream<String?> watchUserIds() {
    return _client.auth.onAuthStateChange.map((event) {
      final session = event.session;
      return session?.user.id;
    });
  }

  @override
  Future<Map<String, dynamic>?> selectProfile(String userId) {
    return _client
        .from('profiles')
        .select('id, display_name, created_at, updated_at')
        .eq('id', userId)
        .maybeSingle();
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
