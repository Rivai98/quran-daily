import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/shell/home_shell.dart';

void main() {
  testWidgets('shows three labelled destinations and opens Home first', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell(
      homeBuilder: _home, groupsBuilder: _groups, logBuilder: _log,
    )));
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('مجموعاتي'), findsOneWidget);
    expect(find.text('السجل'), findsOneWidget);
    expect(find.text('HOME CONTENT'), findsOneWidget);
  });
}

Widget _home(BuildContext context) => const Scaffold(body: Text('HOME CONTENT'));
Widget _groups(BuildContext context) => const Scaffold(body: Text('GROUPS CONTENT'));
Widget _log(BuildContext context) => const Scaffold(body: Text('LOG CONTENT'));
