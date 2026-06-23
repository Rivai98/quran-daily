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
}
