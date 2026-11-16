import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/auth/session_gateway.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/settings/settings_repository.dart';
import 'package:quran_daily/features/settings/cubit/settings_cubit.dart';
import 'package:quran_daily/features/settings/cubit/settings_state.dart';

class _MockSettingsRepo extends Mock implements SettingsRepository {}

class _MockSessionGateway extends Mock implements SessionGateway {}

void main() {
  late _MockSettingsRepo settingsRepo;
  late _MockSessionGateway sessionGateway;

  setUp(() {
    settingsRepo = _MockSettingsRepo();
    sessionGateway = _MockSessionGateway();
  });

  SettingsCubit build() => SettingsCubit(
    settingsRepository: settingsRepo,
    sessionGateway: sessionGateway,
  );

  group('SettingsCubit', () {
    test('initial state has default scale 1.0', () {
      final cubit = build();
      expect(cubit.state.quranTextScale, 1.0);
      expect(cubit.state.status, SettingsStatus.initial);
    });

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings reads scale from repo',
      build: build,
      setUp: () =>
          when(() => settingsRepo.getQuranTextScale())
              .thenAnswer((_) async => const Success(1.25)),
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsState(
          status: SettingsStatus.success,
          quranTextScale: 1.25,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'setQuranTextScale clamps between 0.85 and 1.6 and persists',
      build: build,
      setUp: () =>
          when(() => settingsRepo.setQuranTextScale(any()))
              .thenAnswer((_) async => const Success(null)),
      act: (cubit) async {
        await cubit.setQuranTextScale(2.0); // should clamp to 1.6
      },
      expect: () => [const SettingsState(quranTextScale: 1.6)],
      verify: (_) {
        verify(() => settingsRepo.setQuranTextScale(1.6)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'signOut calls session gateway and emits signedOut',
      build: build,
      setUp: () =>
          when(() => sessionGateway.signOut())
              .thenAnswer((_) async => const Success(null)),
      act: (cubit) => cubit.signOut(),
      expect: () => [
        const SettingsState(status: SettingsStatus.signingOut),
        const SettingsState(status: SettingsStatus.signedOut),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'signOut failure emits failure state',
      build: build,
      setUp: () => when(() => sessionGateway.signOut()).thenAnswer(
        (_) async => const FailureResult(
          UnknownFailure(message: 'error', code: 'unknown'),
        ),
      ),
      act: (cubit) => cubit.signOut(),
      expect: () => [
        const SettingsState(status: SettingsStatus.signingOut),
        isA<SettingsState>()
            .having((s) => s.status, 'status', SettingsStatus.failure)
            .having((s) => s.failure, 'failure', isNotNull),
      ],
    );
  });
}
