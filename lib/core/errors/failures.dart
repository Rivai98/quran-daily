import 'package:equatable/equatable.dart';

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
  const AppFailure({
    required this.message,
    required this.code,
    this.cause,
  });

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
