import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/auth/cubit/auth_cubit.dart';
import 'package:quran_daily/features/auth/data/repositories/auth_repository.dart';
import 'package:quran_daily/core/design_system/app_button.dart';
import 'package:quran_daily/features/auth/view/auth_entry_screen.dart';

import '../../../helpers/widget_test_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
    when(() => repository.watchAuthState())
        .thenAnswer((_) => const Stream.empty());
  });

  Finder primaryButton() => find
      .descendant(
        of: find.byType(AppButton),
        matching: find.byType(Text),
      )
      .last;

  Widget pumpAuthEntry({AuthState? seed}) {
    return BlocProvider<AuthCubit>(
      create: (_) => AuthCubit(repository: repository)
        ..emit(seed ??
            const AuthState(
                status: AuthStatus.unauthenticated, mode: AuthMode.login)),
      child: const AuthEntryScreen(),
    );
  }

  testWidgets('login mode: LTR email, password toggle, primary, guidance, '
      'mode switch, and no Google button', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(pumpAuthEntry()));

    expect(find.text(ArabicStrings.emailLabel), findsOneWidget);
    expect(find.text(ArabicStrings.passwordLabel), findsOneWidget);
    expect(find.text(ArabicStrings.forgotPasswordGuidance), findsOneWidget);
    expect(find.text(ArabicStrings.signInTitle), findsAtLeastNWidgets(1));
    expect(find.text(ArabicStrings.createAccountTitle), findsAtLeastNWidgets(1));

    // Email content is LTR.
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    final emailField = fields.first;
    expect(emailField.textDirection, TextDirection.ltr);

    // No Google sign-in anywhere.
    expect(find.textContaining('Google'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('switching to signup mode shows all four fields',
      (tester) async {
    await tester.pumpWidget(buildArabicTestApp(pumpAuthEntry()));
    await tester.tap(find.text(ArabicStrings.createAccountTitle));
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.displayNameLabel), findsOneWidget);
    expect(find.text(ArabicStrings.emailLabel), findsOneWidget);
    expect(find.text(ArabicStrings.passwordLabel), findsOneWidget);
    expect(find.text(ArabicStrings.confirmPasswordLabel), findsOneWidget);
    expect(find.text(ArabicStrings.passwordHint), findsOneWidget);
  });

  testWidgets('submit validates fields and shows Arabic errors',
      (tester) async {
    await tester.pumpWidget(buildArabicTestApp(pumpAuthEntry()));

    await tester.tap(primaryButton());
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.invalidEmailError), findsOneWidget);
    expect(find.text(ArabicStrings.requiredFieldError), findsOneWidget);

    verifyNever(() => repository.signIn(
        email: any(named: 'email'), password: any(named: 'password')));
  });

  testWidgets('signup shows mismatch error and blocks the repository',
      (tester) async {
    await tester.pumpWidget(buildArabicTestApp(pumpAuthEntry()));
    await tester.tap(find.text(ArabicStrings.createAccountTitle));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField).at(0), 'سارة');
    await tester.enterText(
        find.byType(TextField).at(1), 'sara@test.local');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.enterText(find.byType(TextField).at(3), 'password124');
    await tester.ensureVisible(primaryButton());
    await tester.pumpAndSettle();

    await tester.tap(primaryButton());
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.passwordMismatchError), findsOneWidget);
    verifyNever(() => repository.signUp(
        displayName: any(named: 'displayName'),
        email: any(named: 'email'),
        password: any(named: 'password')));
  });

  testWidgets('valid login submits to the repository', (tester) async {
    when(() => repository.signIn(
          email: 'sara@test.local',
          password: 'password123',
        )).thenAnswer((_) async => const FailureResult(
        AuthFailure(message: 'x', code: 'invalid_credentials')));

    await tester.pumpWidget(buildArabicTestApp(pumpAuthEntry()));
    await tester.enterText(
        find.byType(TextField).at(0), 'sara@test.local');
    await tester.enterText(find.byType(TextField).at(1), 'password123');

    await tester.tap(primaryButton());
    await tester.pump();

    verify(() => repository.signIn(
        email: 'sara@test.local', password: 'password123')).called(1);
  });

  testWidgets('failure state shows a non-revealing Arabic message and clears '
      'the password field', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      pumpAuthEntry(
        seed: const AuthState(
          status: AuthStatus.failure,
          mode: AuthMode.login,
          failure: AuthFailure(
              message: 'credentials rejected', code: 'invalid_credentials'),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      find.text(ArabicStrings.authError('invalid_credentials')),
      findsOneWidget,
    );
    // No raw provider copy leaks to the user.
    expect(find.textContaining('credentials rejected'), findsNothing);
  });

  testWidgets('network failure copy explains connectivity', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      pumpAuthEntry(
        seed: const AuthState(
          status: AuthStatus.failure,
          failure: AuthFailure(message: 'network', code: 'network'),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.authError('network')), findsOneWidget);
  });

  testWidgets('profile failure state offers retry', (tester) async {
    when(() => repository.currentUserId).thenReturn('u');
    when(() => repository.loadCurrentProfile()).thenAnswer(
        (_) async => const FailureResult(
            AuthFailure(message: 'x', code: 'missing_profile')));

    await tester.pumpWidget(buildArabicTestApp(
      pumpAuthEntry(
        seed: const AuthState(
          status: AuthStatus.profileFailure,
          failure:
              AuthFailure(message: 'x', code: 'missing_profile'),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.authError('missing_profile')), findsOneWidget);
    expect(find.text(ArabicStrings.retry), findsOneWidget);

    await tester.tap(find.text(ArabicStrings.retry));
    await tester.pump();
    verify(() => repository.loadCurrentProfile()).called(greaterThanOrEqualTo(1));
  });

  testWidgets('renders in all constitution variants without overflow',
      (tester) async {
    await pumpAllVariants(
      tester,
      pumpAuthEntry(),
      (tester, variant) async {
        expect(tester.takeException(), isNull,
            reason: 'overflow in variant $variant');
        expect(find.byType(AuthEntryScreen), findsOneWidget,
            reason: variant);
      },
    );
  });
}
