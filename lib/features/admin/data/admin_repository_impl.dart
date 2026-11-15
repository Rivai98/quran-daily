import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../../../core/network/rpc_client.dart';
import 'admin_repository.dart';

typedef AdminFunctionInvoker =
    Future<Object?> Function(String name, Map<String, Object?> body);

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({
    required RpcClient rpc,
    required AdminFunctionInvoker invoke,
  }) : _rpc = rpc,
       _invoke = invoke;

  final RpcClient _rpc;
  final AdminFunctionInvoker _invoke;

  AdminJson _map(Object? value) => (value! as Map).cast<String, Object?>();

  Future<Result<AdminJson>> _read(
    String name, [
    Map<String, Object?>? params,
  ]) async {
    final result = await _rpc.call<dynamic>(name, params);
    return result.when(
      success: (value) => Success(_map(value)),
      failure: FailureResult.new,
    );
  }

  Future<Result<void>> _call(
    String name, [
    Map<String, Object?>? params,
  ]) async {
    final result = await _rpc.call<dynamic>(name, params);
    return result.when(
      success: (_) => const Success<void>(null),
      failure: FailureResult.new,
    );
  }

  @override
  Future<Result<bool>> isAdmin() async {
    final result = await _rpc.call<bool>('admin_is_admin');
    return result.when(
      success: (value) => Success(value ?? false),
      failure: FailureResult.new,
    );
  }

  @override
  Future<Result<AdminJson>> overview() => _read('admin_overview');

  @override
  Future<Result<AdminJson>> groups({String? query, String? status}) => _read(
    'admin_list_groups',
    {'p_query': query, 'p_status': status, 'p_limit': 50, 'p_offset': 0},
  );

  @override
  Future<Result<AdminJson>> groupDetail(String groupId) =>
      _read('admin_group_detail', {'p_group_id': groupId});

  @override
  Future<Result<AdminJson>> users({String? query, String? status}) => _read(
    'admin_list_users',
    {'p_query': query, 'p_status': status, 'p_limit': 50, 'p_offset': 0},
  );

  @override
  Future<Result<AdminJson>> userDetail(String userId) =>
      _read('admin_user_detail', {'p_user_id': userId});

  @override
  Future<Result<AdminJson>> audit({String? action}) => _read(
    'admin_list_audit',
    {'p_action': action, 'p_limit': 50, 'p_offset': 0},
  );

  @override
  Future<Result<void>> groupAction(
    String action,
    String groupId, {
    String? confirmName,
    String? membershipId,
  }) {
    final (fn, args) = switch (action) {
      'archive' => ('admin_archive_group', {'p_group_id': groupId}),
      'restore' => ('admin_restore_group', {'p_group_id': groupId}),
      'delete' => (
        'admin_delete_group',
        {'p_group_id': groupId, 'p_confirm_name': confirmName},
      ),
      'remove_member' => (
        'admin_remove_member',
        {'p_group_id': groupId, 'p_membership_id': membershipId},
      ),
      'transfer' => (
        'admin_transfer_ownership',
        {'p_group_id': groupId, 'p_new_owner_membership_id': membershipId},
      ),
      'regenerate_invite' => (
        'admin_regenerate_invite',
        {'p_group_id': groupId},
      ),
      _ => throw ArgumentError.value(action, 'action'),
    };
    return _call(fn, args);
  }

  @override
  Future<Result<void>> userAction(String action, String userId) =>
      _invokeResult('admin-user-action', {
        'action': action,
        'targetUserId': userId,
      });

  @override
  Future<Result<void>> createUser({
    required String name,
    required String email,
    required String password,
  }) => _invokeResult('admin-create-user', {
    'displayName': name,
    'email': email,
    'password': password,
  });

  @override
  Future<Result<void>> resetPassword(String userId, String password) =>
      _invokeResult('admin-reset-password', {
        'targetUserId': userId,
        'newPassword': password,
      });

  Future<Result<void>> _invokeResult(
    String function,
    Map<String, Object?> body,
  ) async {
    try {
      await _invoke(function, body);
      return const Success<void>(null);
    } on FunctionException catch (error) {
      return FailureResult(
        UnknownFailure(
          message: 'admin action failed',
          code:
              (error.details is Map ? (error.details as Map)['code'] : null)
                  ?.toString() ??
              'unknown',
          cause: error,
        ),
      );
    } catch (error) {
      return FailureResult(
        UnknownFailure(
          message: 'admin action failed',
          code: 'unknown',
          cause: error,
        ),
      );
    }
  }
}
