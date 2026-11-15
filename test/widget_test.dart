import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/app/app.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/features/auth/cubit/auth_cubit.dart';
import 'package:quran_daily/features/auth/data/repositories/auth_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('shows Arabic auth entry as the first screen', (tester) async {
    final repository = _MockAuthRepository();
    when(() => repository.watchAuthState())
        .thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(QuranDailyApp(
      authCubit: AuthCubit(repository: repository)
        ..emit(const AuthState(
            status: AuthStatus.unauthenticated, mode: AuthMode.login)),
    ));
    await tester.pumpAndSettle();

    expect(find.text(ArabicStrings.appName), findsOneWidget);
    expect(find.text(ArabicStrings.signInTitle), findsAtLeastNWidgets(1));
    // Email/password only (spec 002): no Google sign-in control anywhere.
    expect(find.textContaining('Google'), findsNothing);
  });
}
