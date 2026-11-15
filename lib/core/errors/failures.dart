import 'package:equatable/equatable.dart';

/// Stable failure kinds from the repository contract; each [AppFailure]
/// also carries its backend `code` for copy mapping and logs.
enum FailureKind {
  unauthenticated,
  forbidden,
  validation,
  network,
  offlineQueued,
  notFound,
  conflict,
  dayClosed,
  limitReached,
  unknown,
}

/// Backend error codes with a dedicated kind.
const _kindByCode = <String, FailureKind>{
  'unauthenticated': FailureKind.unauthenticated,
  'not_member': FailureKind.forbidden,
  'forbidden': FailureKind.forbidden,
  'validation_failed': FailureKind.validation,
  'password_mismatch': FailureKind.validation,
  'network': FailureKind.network,
  'offline_queued': FailureKind.offlineQueued,
  'group_not_found': FailureKind.notFound,
  'assignment_not_found': FailureKind.notFound,
  'user_not_found': FailureKind.notFound,
  'invite_invalid': FailureKind.notFound,
  'not_found': FailureKind.notFound,
  'juz_already_taken': FailureKind.conflict,
  'group_full': FailureKind.conflict,
  'already_member': FailureKind.conflict,
  'request_already_pending': FailureKind.conflict,
  'email_exists': FailureKind.conflict,
  'owner_must_transfer': FailureKind.conflict,
  'group_not_forming': FailureKind.conflict,
  'request_not_pending': FailureKind.conflict,
  'day_closed': FailureKind.dayClosed,
  'day_not_open': FailureKind.dayClosed,
  'owner_group_limit': FailureKind.limitReached,
  'membership_limit': FailureKind.limitReached,
};

extension AppFailureKind on AppFailure {
  /// Stable kind derived from the backend [code] (or the failure category
  /// as a fallback).
  FailureKind get kind =>
      _kindByCode[code] ??
      switch (category) {
        FailureCategory.auth => FailureKind.unauthenticated,
        FailureCategory.permission => FailureKind.forbidden,
        FailureCategory.validation => FailureKind.validation,
        FailureCategory.network => FailureKind.network,
        FailureCategory.offlineQueued => FailureKind.offlineQueued,
        FailureCategory.syncConflict => FailureKind.conflict,
        FailureCategory.unknown => FailureKind.unknown,
      };
}

enum FailureCategory {
  auth,
  permission,
  validation,
  network,
  offlineQueued,
  syncConflict,
  unknown,
}

abstract class AppFailure extends Equatable {
  const AppFailure({required this.message, required this.code, this.cause});

  final String message;
  final String code;
  final Object? cause;

  FailureCategory get category;

  @override
  List<Object?> get props => [category, message, code, cause];
}

class AuthFailure extends AppFailure {
  const AuthFailure({required super.message, required super.code, super.cause});

  @override
  FailureCategory get category => FailureCategory.auth;
}

class PermissionFailure extends AppFailure {
  const PermissionFailure({
    required super.message,
    required super.code,
    super.cause,
  });

  @override
  FailureCategory get category => FailureCategory.permission;
}

class ValidationFailure extends AppFailure {
  const ValidationFailure({
    required super.message,
    required super.code,
    super.cause,
  });

  @override
  FailureCategory get category => FailureCategory.validation;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({
    required super.message,
    required super.code,
    super.cause,
  });

  @override
  FailureCategory get category => FailureCategory.network;
}

class OfflineQueuedFailure extends AppFailure {
  const OfflineQueuedFailure({
    required super.message,
    required super.code,
    super.cause,
  });

  @override
  FailureCategory get category => FailureCategory.offlineQueued;
}

class SyncConflictFailure extends AppFailure {
  const SyncConflictFailure({
    required super.message,
    required super.code,
    super.cause,
  });

  @override
  FailureCategory get category => FailureCategory.syncConflict;
}

class UnknownFailure extends AppFailure {
  const UnknownFailure({
    required super.message,
    required super.code,
    super.cause,
  });

  @override
  FailureCategory get category => FailureCategory.unknown;
}
