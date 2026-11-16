import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_daily/features/home/view/widgets/date_header.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));
  testWidgets('shows Hijri date before Gregorian date using Arabic numerals', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DateHeader(date: DateTime(2026, 11, 15))),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text).first);
    expect(text.data, contains('١٤٤٨'));
    expect(find.textContaining('٢٠٢٦'), findsOneWidget);
  });
}
