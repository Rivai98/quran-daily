import '../../../../core/errors/result.dart';
import '../../../../core/network/rpc_client.dart';

abstract class KhatmaRemoteDataSource {
  Future<Result<dynamic>> call(String function, [Map<String, Object?>? params]);
}

class KhatmaRemoteDataSourceImpl implements KhatmaRemoteDataSource {
  KhatmaRemoteDataSourceImpl(this._rpc);

  final RpcClient _rpc;

  @override
  Future<Result<dynamic>> call(String function,
      [Map<String, Object?>? params]) {
    return _rpc.call<dynamic>(function, params);
  }
}
