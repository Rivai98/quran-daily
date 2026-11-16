import '../../../../core/errors/result.dart';
import '../../../../core/network/rpc_client.dart';

abstract interface class ProfileRemoteDataSource {
  Future<Result<dynamic>> getMyProfile();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._rpc);

  final RpcClient _rpc;

  @override
  Future<Result<dynamic>> getMyProfile() =>
      _rpc.call<dynamic>('get_my_profile');
}
