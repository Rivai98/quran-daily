import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';

void main() {
  group('Result', () {
    test('maps a success value without exposing a failure', () {
      const result = Result.success('dashboard');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 'dashboard');
      expect(result.failureOrNull, isNull);
      expect(
        result.when(
          success: (value) => 'loaded $value',
          failure: (_) => 'failed',
        ),
        'loaded dashboard',
      );
    });

    test('maps a typed failure without exposing a value', () {
      const failure = NetworkFailure(
        message: 'Connection failed. Try again.',
        code: 'network_unavailable',
      );
      const result = Result<String>.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, failure);
      expect(
        result.when(
          success: (_) => 'loaded',
          failure: (failure) => failure.code,
        ),
        'network_unavailable',
      );
    });
  });

  group('AppFailure', () {
    test('keeps display-safe failure details stable for equality', () {
      const first = ValidationFailure(
        message: 'The group must include 30 active members.',
        code: 'group_requires_30_active_members',
      );
      const second = ValidationFailure(
        message: 'The group must include 30 active members.',
        code: 'group_requires_30_active_members',
      );

      expect(first, second);
      expect(first.category, FailureCategory.validation);
    });

    test('provides all required failure categories', () {
      const failures = <AppFailure>[
        AuthFailure(message: 'Sign-in failed.', code: 'auth_failed'),
        PermissionFailure(
          message: 'Organizer access required.',
          code: 'not_organizer',
        ),
        ValidationFailure(message: 'Invalid input.', code: 'invalid_input'),
        NetworkFailure(message: 'Connection failed.', code: 'network_error'),
        OfflineQueuedFailure(
          message: 'Queued offline.',
          code: 'queued_offline',
        ),
        SyncConflictFailure(message: 'Sync conflict.', code: 'sync_conflict'),
        UnknownFailure(message: 'Unexpected error.', code: 'unknown'),
      ];

      expect(
        failures.map((failure) => failure.category),
        containsAll(FailureCategory.values),
      );
    });
  });

  group('FailureKind mapping (repository contract)', () {
    test('backend codes map to their stable kinds', () {
      const cases = <String, FailureKind>{
        'unauthenticated': FailureKind.unauthenticated,
        'forbidden': FailureKind.forbidden,
        'not_member': FailureKind.forbidden,
        'validation_failed': FailureKind.validation,
        'network': FailureKind.network,
        'group_not_found': FailureKind.notFound,
        'juz_already_taken': FailureKind.conflict,
        'group_full': FailureKind.conflict,
        'day_closed': FailureKind.dayClosed,
        'owner_group_limit': FailureKind.limitReached,
      };
      for (final entry in cases.entries) {
        final failure = UnknownFailure(message: 'm', code: entry.key);
        expect(failure.kind, entry.value, reason: entry.key);
      }
    });

    test('unknown codes fall back to the failure category', () {
      const failure = NetworkFailure(message: 'm', code: 'some_new_code');
      expect(failure.kind, FailureKind.network);
    });

    test('offline queued failures keep their kind', () {
      const failure = OfflineQueuedFailure(
        message: 'queued',
        code: 'offline_queued',
      );
      expect(failure.kind, FailureKind.offlineQueued);
    });
  });
}
