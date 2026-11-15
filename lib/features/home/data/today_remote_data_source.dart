import '../../../core/network/rpc_client.dart';

class TodayRemoteDataSource {
  const TodayRemoteDataSource(this._rpc);
  final RpcClient _rpc;
  Future<Object?> getToday() async {
    final result = await _rpc.call<Object>('get_my_today');
    if (result.isFailure) throw result.failureOrNull!;
    return result.valueOrNull;
  }
  Future<void> setMainGroup(String? groupId) async {
    final result = await _rpc.call<Object?>('set_main_group', {'p_group_id': groupId});
    if (result.isFailure) throw result.failureOrNull!;
  }
  Future<void> markGroupOpened(String groupId) async {
    final result = await _rpc.call<Object?>('mark_group_opened', {'p_group_id': groupId});
    if (result.isFailure) throw result.failureOrNull!;
  }
}
