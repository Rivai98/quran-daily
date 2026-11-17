import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/app/bootstrap.dart';
import 'package:quran_daily/app/bootstrap_cubit.dart';
import 'package:quran_daily/core/design_system/widgets/halaqa_logo.dart';

void main() {
  test(
    'bootstrap shares service initialization and retries failure (#21)',
    () async {
      var attempts = 0;
      final response = Completer<void>();
      final cubit = BootstrapCubit(() {
        attempts++;
        return response.future;
      });
      final first = cubit.initialize();
      final second = cubit.initialize();
      expect(attempts, 1);
      response.complete();
      await Future.wait([first, second]);
      expect(cubit.state.status, BootstrapStatus.ready);
      await cubit.close();
    },
  );
  test('failed service initialization remains retryable (#21)', () async {
    var attempts = 0;
    final cubit = BootstrapCubit(() async {
      if (++attempts == 1) throw StateError('unavailable');
    });
    await cubit.initialize();
    expect(cubit.state.status, BootstrapStatus.failure);
    await cubit.initialize();
    expect(cubit.state.status, BootstrapStatus.ready);
    await cubit.close();
  });

  testWidgets(
    'branded frame renders before services; app waits for readiness (#21)',
    (tester) async {
      final response = Completer<void>();
      var started = false;
      await tester.pumpWidget(
        BootstrapApp(
          initialize: () {
            started = true;
            return response.future;
          },
          app: const MaterialApp(home: Text('ready')),
        ),
      );
      expect(find.byType(HalaqaLogo), findsOneWidget);
      expect(started, isTrue);
      expect(find.text('ready'), findsNothing);
      response.complete();
      await tester.pumpAndSettle();
      expect(find.text('ready'), findsOneWidget);
      expect(
        find.byType(BlocBuilder<BootstrapCubit, BootstrapState>),
        findsOneWidget,
      );
    },
  );
}
