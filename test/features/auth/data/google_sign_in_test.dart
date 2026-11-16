import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/features/auth/data/data_sources/google_auth_client.dart';
import 'package:quran_daily/features/auth/data/data_sources/supabase_auth_data_source.dart';
import 'package:quran_daily/features/auth/data/repositories/auth_repository_impl.dart';

class _DataSource extends Mock implements SupabaseAuthDataSource {}

class _GoogleClient implements GoogleAuthClient {
  GoogleAuthTokens? tokens;
  int signOutCalls = 0;
  @override
  Future<GoogleAuthTokens?> authenticate() async => tokens;
  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

void main() {
  late _DataSource source;
  late _GoogleClient google;
  late AuthRepositoryImpl repository;

  setUp(() {
    source = _DataSource();
    google = _GoogleClient();
    repository = AuthRepositoryImpl(
      dataSource: source,
      googleAuthClient: google,
    );
    when(() => source.watchUserIds()).thenAnswer((_) => const Stream.empty());
  });

  test('exchanges the Google ID token and loads the linked profile', () async {
    google.tokens = const GoogleAuthTokens(idToken: 'id-token');
    when(() => source.signInWithGoogleIdToken(idToken: 'id-token'))
        .thenAnswer((_) async {});
    when(() => source.currentUserId()).thenReturn('user-1');
    when(
      () => source.selectProfile('user-1'),
    ).thenAnswer((_) async => {'id': 'user-1', 'display_name': 'Google Name'});
    final result = await repository.signInWithGoogle();
    expect(result?.isSuccess, isTrue);
    expect(result?.valueOrNull?.profile.displayName, 'Google Name');
    verify(() => source.signInWithGoogleIdToken(idToken: 'id-token')).called(1);
  });

  test('cancel returns null without a failure result', () async {
    expect(await repository.signInWithGoogle(), isNull);
    verifyNever(
      () => source.signInWithGoogleIdToken(idToken: any(named: 'idToken')),
    );
  });

  test('missing ID token fails before Supabase exchange', () async {
    google.tokens = const GoogleAuthTokens(idToken: null);
    final result = await repository.signInWithGoogle();
    expect(result?.failureOrNull?.code, 'google_auth_failed');
    verifyNever(
      () => source.signInWithGoogleIdToken(idToken: any(named: 'idToken')),
    );
  });

  test('sign out clears Google authorization too', () async {
    when(() => source.signOut()).thenAnswer((_) async {});
    expect((await repository.signOut()).isSuccess, isTrue);
    expect(google.signOutCalls, 1);
  });
}
