import '../../../../core/errors/result.dart';
import '../../../../core/network/rpc_client.dart';

abstract interface class KhatmaRemoteDataSource {
  Future<Result<dynamic>> getDashboard(String groupId);
}

class KhatmaRemoteDataSourceImpl implements KhatmaRemoteDataSource {
  KhatmaRemoteDataSourceImpl(this._rpc);

  final RpcClient _rpc;

  @override
  Future<Result<dynamic>> getDashboard(String groupId) =>
      _rpc.call<dynamic>('get_dashboard', {'p_group_id': groupId});
}
