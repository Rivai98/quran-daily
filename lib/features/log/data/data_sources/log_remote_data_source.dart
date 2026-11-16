import '../../../../core/network/rpc_client.dart';
import '../entities/log_entities.dart';

class LogRemoteDataSource {
  const LogRemoteDataSource(this._rpc);
  final RpcClient _rpc;

  Future<PersonalLog> getLog({String? before, int days = 30}) async {
    final result = await _rpc.call<Object?>('get_my_log', {
      'p_before': before,
      'p_days': days,
    });
    return result.when(
      success: (payload) =>
          PersonalLog.fromJson((payload! as Map).cast<String, Object?>()),
      failure: (failure) => throw failure,
    );
  }
}
