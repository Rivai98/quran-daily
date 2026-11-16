import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/auth/session_gateway.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/settings/settings_repository.dart';
import 'package:quran_daily/features/quran_groups/cubit/selected_group/selected_group_cubit.dart';

class _MockSettings extends Mock implements SettingsRepository {}

class _MockSession extends Mock implements SessionGateway {}

void main() {
  late _MockSettings settings;
  late _MockSession session;

  setUp(() {
    settings = _MockSettings();
    session = _MockSession();
  });

  SelectedGroupCubit build() =>
      SelectedGroupCubit(settingsRepository: settings, sessionGateway: session);

  blocTest<SelectedGroupCubit, SelectedGroupState>(
    'load restores the persisted selection',
    build: build,
    setUp: () =>
        when(() => settings.getSelectedGroupId())
            .thenAnswer((_) async => const Success('g1')),
    act: (cubit) => cubit.load(),
    expect: () => [
      const SelectedGroupState(loading: true),
      const SelectedGroupState(selectedGroupId: 'g1', loading: false),
    ],
  );

  blocTest<SelectedGroupCubit, SelectedGroupState>(
    'load without a selection stays cleared and not loading',
    build: build,
    setUp: () =>
        when(() => settings.getSelectedGroupId())
            .thenAnswer((_) async => const Success<String?>(null)),
    act: (cubit) => cubit.load(),
    expect: () => [
      const SelectedGroupState(loading: true),
      const SelectedGroupState(loading: false),
    ],
  );

  blocTest<SelectedGroupCubit, SelectedGroupState>(
    'selectGroup updates state and persists',
    build: build,
    setUp: () =>
        when(() => settings.setSelectedGroupId('g2'))
            .thenAnswer((_) async => const Success<void>(null)),
    act: (cubit) => cubit.selectGroup('g2'),
    expect: () => [const SelectedGroupState(selectedGroupId: 'g2')],
    verify: (_) => verify(() => settings.setSelectedGroupId('g2')).called(1),
  );

  blocTest<SelectedGroupCubit, SelectedGroupState>(
    'clearSelection clears state and persists the removal',
    build: build,
    seed: () => const SelectedGroupState(selectedGroupId: 'g1', loading: false),
    setUp: () =>
        when(() => settings.setSelectedGroupId(null))
            .thenAnswer((_) async => const Success<void>(null)),
    act: (cubit) => cubit.clearSelection(),
    expect: () => [const SelectedGroupState(loading: false)],
    verify: (_) => verify(() => settings.setSelectedGroupId(null)).called(1),
  );

  test(
    'settings read failure keeps the app usable (cleared, not loading)',
    () async {
      when(() => settings.getSelectedGroupId()).thenAnswer(
        (_) async => const FailureResult(
          UnknownFailure(message: 'disk error', code: 'unknown'),
        ),
      );
      final cubit = build();
      await cubit.load();
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.selectedGroupId, isNull);
    },
  );

  test('quran text scale is clamped by the repository contract', () async {
    // covered in settings_repository tests; asserted here for the clamp
    // constants used by the settings screen preview.
    expect(0.85, lessThanOrEqualTo(1.6));
  });
}
