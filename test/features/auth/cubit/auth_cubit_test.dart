import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/auth/cubit/auth_cubit.dart';
import 'package:quran_daily/features/auth/data/entities/app_user.dart';
import 'package:quran_daily/features/auth/data/entities/user_profile.dart';
import 'package:quran_daily/features/auth/data/repositories/auth_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const user = AppUser(
    id: '11111111-1111-1111-1111-111111111111',
    email: 'sara@test.local',
  );
  const profile = UserProfile(
    id: '11111111-1111-1111-1111-111111111111',
    displayName: 'سارة',
  );
  const authenticated = AuthenticatedUser(user: user, profile: profile);

  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
    when(() => repository.watchAuthState())
        .thenAnswer((_) => const Stream.empty());
    registerFallbackValue(const AuthFailure(message: '', code: ''));
  });

  AuthCubit buildCubit() => AuthCubit(repository: repository);

  group('bootstrap', () {
    blocTest<AuthCubit, AuthState>(
      'no session ends unauthenticated',
      build: buildCubit,
      setUp: () => when(() => repository.currentUserId).thenReturn(null),
      act: (cubit) => cubit.bootstrap(),
      expect: () => [
        const AuthState(status: AuthStatus.checkingSession),
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'valid session restores the profile and authenticates',
      build: buildCubit,
      setUp: () {
        when(() => repository.currentUserId).thenReturn(user.id);
        when(() => repository.loadCurrentProfile())
            .thenAnswer((_) async => const Success(profile));
      },
      act: (cubit) => cubit.bootstrap(),
      expect: () => [
        const AuthState(status: AuthStatus.checkingSession),
        const AuthState(status: AuthStatus.loadingProfile),
        const AuthState(
          status: AuthStatus.authenticated,
          profile: profile,
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'profile failure blocks private navigation',
      build: buildCubit,
      setUp: () {
        when(() => repository.currentUserId).thenReturn(user.id);
        when(() => repository.loadCurrentProfile()).thenAnswer(
            (_) async => const FailureResult(AuthFailure(
                message: 'profile missing', code: 'missing_profile')));
      },
      act: (cubit) => cubit.bootstrap(),
      expect: () => [
        const AuthState(status: AuthStatus.checkingSession),
        const AuthState(status: AuthStatus.loadingProfile),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.profileFailure),
      ],
    );
  });

  group('mode switching', () {
    blocTest<AuthCubit, AuthState>(
      'toggles between login and signup modes',
      build: buildCubit,
      seed: () => const AuthState(status: AuthStatus.unauthenticated),
      act: (cubit) => cubit
        ..showSignup()
        ..showLogin(),
      expect: () => [
        const AuthState(
            status: AuthStatus.unauthenticated, mode: AuthMode.signup),
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );
  });

  group('submitLogin', () {
    blocTest<AuthCubit, AuthState>(
      'success path authenticates with profile',
      build: buildCubit,
      seed: () => const AuthState(status: AuthStatus.unauthenticated),
      setUp: () {
        when(() => repository.signIn(
              email: 'sara@test.local',
              password: 'password123',
            )).thenAnswer((_) async => const Success(authenticated));
      },
      act: (cubit) =>
          cubit.submitLogin(email: 'sara@test.local', password: 'password123'),
      expect: () => [
        const AuthState(status: AuthStatus.submitting),
        const AuthState(status: AuthStatus.authenticated, profile: profile),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'invalid credentials return to failure with a non-revealing code',
      build: buildCubit,
      seed: () => const AuthState(status: AuthStatus.unauthenticated),
      setUp: () {
        when(() => repository.signIn(
              email: 'sara@test.local',
              password: 'wrong-password',
            )).thenAnswer((_) async => const FailureResult(AuthFailure(
            message: 'provider noise', code: 'invalid_credentials')));
      },
      act: (cubit) => cubit.submitLogin(
          email: 'sara@test.local', password: 'wrong-password'),
      skip: 1,
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.failure)
            .having((s) => s.failure!.code, 'code', 'invalid_credentials'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'client-side validation never calls the repository',
      build: buildCubit,
      seed: () => const AuthState(status: AuthStatus.unauthenticated),
      act: (cubit) => cubit.submitLogin(email: 'not-an-email', password: 'x'),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.failure)
            .having((s) => s.failure!.code, 'code', 'validation_failed'),
      ],
      verify: (_) {
        verifyNever(() => repository.signIn(
            email: any(named: 'email'), password: any(named: 'password')));
      },
    );

    blocTest<AuthCubit, AuthState>(
      'duplicate submissions while submitting are ignored',
      build: buildCubit,
      seed: () => const AuthState(status: AuthStatus.submitting),
      act: (cubit) => cubit.submitLogin(
          email: 'sara@test.local', password: 'password123'),
      expect: () => <AuthState>[],
      verify: (_) {
        verifyNever(() => repository.signIn(
            email: any(named: 'email'), password: any(named: 'password')));
      },
    );
  });

  group('submitSignup', () {
    blocTest<AuthCubit, AuthState>(
      'mismatched confirmation fails validation before network',
      build: buildCubit,
      seed: () => const AuthState(
          status: AuthStatus.unauthenticated, mode: AuthMode.signup),
      act: (cubit) => cubit.submitSignup(
        displayName: 'سارة',
        email: 'sara@test.local',
        password: 'password123',
        confirmation: 'password124',
      ),
      expect: () => [
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.failure)
            .having((s) => s.failure!.code, 'code', 'password_mismatch'),
      ],
      verify: (_) {
        verifyNever(() => repository.signUp(
            displayName: any(named: 'displayName'),
            email: any(named: 'email'),
            password: any(named: 'password')));
      },
    );

    blocTest<AuthCubit, AuthState>(
      'success path authenticates',
      build: buildCubit,
      seed: () => const AuthState(
          status: AuthStatus.unauthenticated, mode: AuthMode.signup),
      setUp: () {
        when(() => repository.signUp(
              displayName: 'سارة',
              email: 'sara@test.local',
              password: 'password123',
            )).thenAnswer((_) async => const Success(authenticated));
      },
      act: (cubit) => cubit.submitSignup(
        displayName: 'سارة',
        email: 'sara@test.local',
        password: 'password123',
        confirmation: 'password123',
      ),
      expect: () => [
        const AuthState(
            status: AuthStatus.submitting, mode: AuthMode.signup),
        const AuthState(
            status: AuthStatus.authenticated,
            mode: AuthMode.signup,
            profile: profile),
      ],
    );
  });

  group('expiry event and sign out', () {
    blocTest<AuthCubit, AuthState>(
      'auth stream emitting null (expiry/revocation) signs the user out',
      build: () {
        when(() => repository.watchAuthState()).thenAnswer(
          (_) => Stream<String?>.fromFutures([
            Future.value(user.id),
            Future<void>.delayed(const Duration(milliseconds: 10))
                .then((_) => null),
          ]),
        );
        return AuthCubit(repository: repository);
      },
      seed: () => const AuthState(
          status: AuthStatus.authenticated, profile: profile),
      wait: const Duration(milliseconds: 30),
      expect: () => [
        const AuthState(
          status: AuthStatus.unauthenticated,
          mode: AuthMode.login,
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'signOut clears the session through the repository',
      build: buildCubit,
      seed: () => const AuthState(
          status: AuthStatus.authenticated, profile: profile),
      setUp: () {
        when(() => repository.signOut()).thenAnswer((_) async => const Success<void>(null));
      },
      act: (cubit) => cubit.signOut(),
      expect: () => [
        const AuthState(status: AuthStatus.signingOut, profile: profile),
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );
  });

  group('retryProfileLoad', () {
    blocTest<AuthCubit, AuthState>(
      'retrying a failed profile load authenticates when it recovers',
      build: buildCubit,
      seed: () => const AuthState(status: AuthStatus.profileFailure),
      setUp: () {
        when(() => repository.currentUserId).thenReturn(user.id);
        when(() => repository.loadCurrentProfile())
            .thenAnswer((_) async => const Success(profile));
      },
      act: (cubit) => cubit.retryProfileLoad(),
      expect: () => [
        const AuthState(status: AuthStatus.loadingProfile),
        const AuthState(status: AuthStatus.authenticated, profile: profile),
      ],
    );
  });
}
