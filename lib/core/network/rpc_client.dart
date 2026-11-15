import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/failures.dart';
import '../errors/result.dart';

/// Executes one RPC call on the Supabase client; injectable for tests.
typedef RpcExecutor = Future<Object?> Function(
  String function,
  Map<String, Object?>? params,
);

/// Thin wrapper around `supabase.rpc` that maps Postgres/provider errors to
/// stable [AppFailure]s (backend codes keep flowing through `code`).
class RpcClient {
  RpcClient({required RpcExecutor execute}) : _execute = execute;

  factory RpcClient.forClient(SupabaseClient client) {
    return RpcClient(
      execute: (function, params) =>
          client.rpc(function, params: params) as Future<Object?>,
    );
  }

  final RpcExecutor _execute;

  /// Calls [function]; a null result is passed through as `null`.
  Future<Result<T?>> call<T>(
    String function, [
    Map<String, Object?>? params,
  ]) async {
    try {
      return Success(await _execute(function, params) as T?);
    } catch (error) {
      return FailureResult(_map(error));
    }
  }

  AppFailure _map(Object error) {
    if (error is PostgrestException) {
      // Our SECURITY DEFINER functions raise stable codes as the message.
      final known = _knownCodes.firstWhere(
        (code) => error.message.contains(code),
        orElse: () => '',
      );
      if (known.isNotEmpty) {
        return _failureForCode(known);
      }
      switch (error.code) {
        case '42501':
          return const PermissionFailure(
              message: 'permission denied', code: 'forbidden');
        case 'PGRST301':
        case '401':
          return const AuthFailure(
              message: 'not signed in', code: 'unauthenticated');
      }
      if (error.message.contains('socket') ||
          error.message.contains('fetch') ||
          error.message.contains('network')) {
        return const NetworkFailure(
            message: 'network unreachable', code: 'network');
      }
      return UnknownFailure(message: error.message, code: error.code ?? 'unknown');
    }

    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('fetch failed') ||
        text.contains('TimeoutException')) {
      return const NetworkFailure(
          message: 'network unreachable', code: 'network');
    }
    return UnknownFailure(message: 'rpc failed', code: 'unknown');
  }

  AppFailure _failureForCode(String code) {
    switch (code) {
      case 'unauthenticated':
        return AuthFailure(message: code, code: code);
      case 'network':
        return NetworkFailure(message: code, code: code);
      case 'validation_failed':
      case 'password_mismatch':
      case 'invalid_display_name':
      case 'invalid_bio':
      case 'invalid_photo_path':
        return ValidationFailure(message: code, code: code);
      case 'forbidden':
      case 'not_member':
      case 'profile_not_accessible':
        return PermissionFailure(message: code, code: code);
      case 'group_not_found':
      case 'photo_not_found':
      case 'profile_not_found':
        return UnknownFailure(message: code, code: code);
      default:
        return AuthFailure(message: code, code: code);
    }
  }

  static const _knownCodes = <String>[
    'unauthenticated',
    'group_not_found',
    'photo_not_found',
    'profile_not_found',
    'profile_not_accessible',
    'invalid_display_name',
    'invalid_bio',
    'invalid_photo_path',
    'group_not_forming',
    'group_archived',
    'group_not_public',
    'group_full',
    'not_member',
    'forbidden',
    'validation_failed',
    'membership_limit',
    'owner_group_limit',
    'invite_invalid',
    'already_member',
    'request_already_pending',
    'request_not_pending',
    'day_closed',
    'day_not_open',
    'not_reader',
    'assignment_not_found',
    'juz_already_taken',
    'already_completed',
    'owner_must_transfer',
    'user_not_found',
    'no_group_available',
  ];
}
