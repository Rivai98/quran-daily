import '../../../../core/errors/result.dart';
import '../../../../core/network/rpc_client.dart';

abstract interface class KhatmaRemoteDataSource {
  Future<Result<dynamic>> getDashboard(String groupId);
  Future<Result<dynamic>> markComplete(
    String assignmentId,
    DateTime recordedAt, {
    required bool offlineSync,
  });
  Future<Result<dynamic>> undoCompletion(String assignmentId);
  Future<Result<dynamic>> volunteer(String assignmentId);
  Future<Result<dynamic>> overrideAssignment(
    String assignmentId,
    String membershipId,
  );

  /// Generic RPC call (US7 history reads).
  Future<Result<dynamic>> call(String function, [Map<String, Object?>? params]);
}

class KhatmaRemoteDataSourceImpl implements KhatmaRemoteDataSource {
  KhatmaRemoteDataSourceImpl(this._rpc);

  final RpcClient _rpc;

  @override
  Future<Result<dynamic>> getDashboard(String groupId) =>
      _rpc.call<dynamic>('get_dashboard', {'p_group_id': groupId});

  @override
  Future<Result<dynamic>> markComplete(
    String assignmentId,
    DateTime recordedAt, {
    required bool offlineSync,
  }) => _rpc.call<dynamic>('mark_assignment_complete', {
    'p_assignment_id': assignmentId,
    'p_client_recorded_at': recordedAt.toUtc().toIso8601String(),
    'p_source': offlineSync ? 'offline_sync' : 'online',
  });

  @override
  Future<Result<dynamic>> undoCompletion(String assignmentId) =>
      _rpc.call<dynamic>('undo_assignment_completion', {
        'p_assignment_id': assignmentId,
      });

  @override
  Future<Result<dynamic>> volunteer(String assignmentId) => _rpc.call<dynamic>(
    'volunteer_for_juz',
    {'p_assignment_id': assignmentId},
  );

  @override
  Future<Result<dynamic>> call(
    String function, [
    Map<String, Object?>? params,
  ]) => _rpc.call<dynamic>(function, params);

  @override
  Future<Result<dynamic>> overrideAssignment(
    String assignmentId,
    String membershipId,
  ) => _rpc.call<dynamic>('override_assignment', {
    'p_assignment_id': assignmentId,
    'p_membership_id': membershipId,
  });
}
