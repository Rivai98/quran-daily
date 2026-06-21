import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/app/app.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';

void main() {
  testWidgets('shows Arabic auth entry as the first screen', (tester) async {
    await tester.pumpWidget(const QuranDailyApp());

    expect(find.text(ArabicStrings.appName), findsOneWidget);
    expect(find.text(ArabicStrings.signInWithGoogle), findsOneWidget);
  });
}
