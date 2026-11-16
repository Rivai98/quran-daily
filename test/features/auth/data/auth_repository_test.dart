import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/auth/data/data_sources/supabase_auth_data_source.dart';
import 'package:quran_daily/features/auth/data/data_sources/google_auth_client.dart';
import 'package:quran_daily/features/auth/data/entities/app_user.dart';
import 'package:quran_daily/features/auth/data/entities/user_profile.dart';
import 'package:quran_daily/features/auth/data/repositories/auth_repository_impl.dart';

class _MockDataSource extends Mock implements SupabaseAuthDataSource {}

class _FakeGoogleAuthClient implements GoogleAuthClient {
  @override
  Future<GoogleAuthTokens?> authenticate() async => null;
  @override
  Future<void> signOut() async {}
}

void main() {
  late _MockDataSource dataSource;
  late AuthRepositoryImpl repository;

  const user = AppUser(
    id: '11111111-1111-1111-1111-111111111111',
    email: 'Sara@Test.local',
  );

  final profileRow = {
    'id': user.id,
    'display_name': 'سارة',
    'created_at': '2026-11-01T10:00:00Z',
    'updated_at': '2026-11-02T10:00:00Z',
  };

  setUp(() {
    dataSource = _MockDataSource();
    repository = AuthRepositoryImpl(
      dataSource: dataSource,
      googleAuthClient: _FakeGoogleAuthClient(),
    );
    registerFallbackValue(Uri.parse('https://fallback.local'));
  });

  group('email normalization', () {
    test(
      'trims and lowercases the email before calling the data source',
      () async {
        when(
          () => dataSource.signIn(
            email: 'sara@test.local',
            password: 'password123',
          ),
        ).thenAnswer((_) async => 'signed-in-session');
        when(() => dataSource.currentUserId())
            .thenReturn('11111111-1111-1111-1111-111111111111');
        when(() => dataSource.selectProfile(user.id))
            .thenAnswer((_) async => profileRow);

        final result = await repository.signIn(
          email: '  Sara@Test.Local  ',
          password: 'password123',
        );

        expect(result.isSuccess, isTrue);
        verify(
          () => dataSource.signIn(
            email: 'sara@test.local',
            password: 'password123',
          ),
        ).called(1);
      },
    );
  });

  group('signUp', () {
    test('returns authenticated user with profile on success', () async {
      when(
        () => dataSource.signUp(
          email: 'sara@test.local',
          password: 'password123',
          displayName: 'سارة',
        ),
      ).thenAnswer((_) async => 'signing-up');
      when(() => dataSource.currentUserId())
          .thenReturn('11111111-1111-1111-1111-111111111111');
      when(() => dataSource.selectProfile(user.id))
          .thenAnswer((_) async => profileRow);

      final result = await repository.signUp(
        displayName: ' سارة ',
        email: 'sara@test.local',
        password: 'password123',
      );

      expect(result, isA<Success<AuthenticatedUser>>());
      result.when(
        success: (authenticated) {
          expect(authenticated.user.email, 'sara@test.local');
          expect(authenticated.profile.displayName, 'سارة');
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('rejects invalid input before any network call', () async {
      final shortPassword = await repository.signUp(
        displayName: 'سارة',
        email: 'sara@test.local',
        password: 'short',
      );

      expect(shortPassword.isFailure, isTrue);
      expect(shortPassword.failureOrNull!.code, 'validation_failed');

      final badEmail = await repository.signUp(
        displayName: 'سارة',
        email: 'not-an-email',
        password: 'password123',
      );
      expect(badEmail.failureOrNull!.code, 'validation_failed');

      final blankName = await repository.signUp(
        displayName: '   ',
        email: 'sara@test.local',
        password: 'password123',
      );
      expect(blankName.failureOrNull!.code, 'validation_failed');

      verifyNever(
        () => dataSource.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      );
    });

    test('falls back to sign-in when signup returns no session', () async {
      when(
        () => dataSource.signUp(
          email: 'sara@test.local',
          password: 'password123',
          displayName: 'سارة',
        ),
      ).thenAnswer((_) async => null);

      // No session right after signup; the fallback sign-in establishes it.
      var currentUserIdCalls = 0;
      when(() => dataSource.currentUserId())
          .thenAnswer((_) => currentUserIdCalls++ == 0 ? null : user.id);
      when(
        () => dataSource.signIn(
          email: 'sara@test.local',
          password: 'password123',
        ),
      ).thenAnswer((_) async => 'signed-in-after-signup');
      when(() => dataSource.selectProfile(user.id))
          .thenAnswer((_) async => profileRow);

      final result = await repository.signUp(
        displayName: 'سارة',
        email: 'sara@test.local',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      verify(
        () => dataSource.signIn(
          email: 'sara@test.local',
          password: 'password123',
        ),
      ).called(1);
    });

    test('maps duplicate email to a stable non-revealing code', () async {
      when(
        () => dataSource.signUp(
          email: 'sara@test.local',
          password: 'password123',
          displayName: 'سارة',
        ),
      ).thenThrow(_fakeAuthException(code: 'user_already_exists'));

      final result = await repository.signUp(
        displayName: 'سارة',
        email: 'sara@test.local',
        password: 'password123',
      );

      expect(result.failureOrNull!.code, 'email_exists');
    });
  });

  group('signIn', () {
    test('maps a banned account to the suspended state', () async {
      when(
        () => dataSource.signIn(
          email: 'sara@test.local',
          password: 'password123',
        ),
      ).thenThrow(_fakeAuthException(code: 'user_banned'));

      final result = await repository.signIn(
        email: 'sara@test.local',
        password: 'password123',
      );

      expect(result.failureOrNull!.code, 'suspended');
    });

    test('maps invalid credentials to invalid_credentials', () async {
      when(
        () => dataSource.signIn(
          email: 'sara@test.local',
          password: 'wrong-password',
        ),
      ).thenThrow(_fakeAuthException(code: 'invalid_credentials'));

      final result = await repository.signIn(
        email: 'sara@test.local',
        password: 'wrong-password',
      );

      expect(result.failureOrNull!.code, 'invalid_credentials');
      // Non-revealing: no raw provider message leaks out.
      expect(result.failureOrNull!.message, isNot(contains('invalid')));
    });

    test('loads the profile after a successful sign-in', () async {
      when(
        () => dataSource.signIn(
          email: 'sara@test.local',
          password: 'password123',
        ),
      ).thenAnswer((_) async => 'signed-in');
      when(() => dataSource.currentUserId())
          .thenReturn('11111111-1111-1111-1111-111111111111');
      when(() => dataSource.selectProfile(user.id))
          .thenAnswer((_) async => profileRow);

      final result = await repository.signIn(
        email: 'sara@test.local',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
    });

    test(
      'missing profile blocks authentication with missing_profile',
      () async {
        when(
          () => dataSource.signIn(
            email: 'sara@test.local',
            password: 'password123',
          ),
        ).thenAnswer((_) async => 'signed-in');
        when(() => dataSource.currentUserId())
            .thenReturn('11111111-1111-1111-1111-111111111111');
        when(() => dataSource.selectProfile(user.id))
            .thenAnswer((_) async => null);

        final result = await repository.signIn(
          email: 'sara@test.local',
          password: 'password123',
        );

        expect(result.failureOrNull!.code, 'missing_profile');
      },
    );
  });

  group('loadCurrentProfile / session restore', () {
    test('returns the stored profile for the current session user', () async {
      when(() => dataSource.currentUserId())
          .thenReturn('11111111-1111-1111-1111-111111111111');
      when(() => dataSource.selectProfile(user.id))
          .thenAnswer((_) async => profileRow);

      final result = await repository.loadCurrentProfile();

      expect(result, isA<Success<UserProfile>>());
      result.when(
        success: (profile) => expect(profile.displayName, 'سارة'),
        failure: (_) => fail('expected success'),
      );
    });

    test('unauthenticated session maps to unauthenticated failure', () async {
      when(() => dataSource.currentUserId()).thenReturn(null);

      final result = await repository.loadCurrentProfile();

      expect(result.failureOrNull!.code, 'unauthenticated');
    });
  });

  group('signOut', () {
    test('delegates to the data source', () async {
      when(() => dataSource.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result, isA<Success<void>>());
      verify(() => dataSource.signOut()).called(1);
    });
  });

  group('network errors', () {
    test('connectivity failures map to network code', () async {
      when(
        () => dataSource.signIn(
          email: 'sara@test.local',
          password: 'password123',
        ),
      ).thenThrow(Exception('Failed to fetch: SocketException'));

      final result = await repository.signIn(
        email: 'sara@test.local',
        password: 'password123',
      );

      expect(result.failureOrNull!.code, 'network');
    });
  });

  test(
    'currentUserId and watchAuthState expose the session gateway shape',
    () async {
      when(() => dataSource.currentUserId()).thenReturn(user.id);
      when(() => dataSource.watchUserIds())
          .thenAnswer((_) => Stream.value(user.id));

      expect(repository.currentUserId, user.id);
      await expectLater(repository.watchAuthState(), emits(user.id));
    },
  );
}

/// Minimal stand-in carrying the provider error shape we map from.
class _FakeAuthException implements Exception {
  const _FakeAuthException({required this.code});

  final String code;

  @override
  String toString() => '_FakeAuthException($code)';
}

Object _fakeAuthException({required String code}) =>
    _FakeAuthException(code: code);
