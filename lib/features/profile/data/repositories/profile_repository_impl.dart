import '../../../../core/auth/session_gateway.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/connectivity_service.dart';
import '../entities/profile_entities.dart';
import '../models/profile_model.dart';
import '../sources/profile_local_data_source.dart';
import '../sources/profile_remote_data_source.dart';
import 'profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required this._remote,
    required this._cache,
    required SessionGateway sessionGateway,
    required this._connectivity,
  }) : _session = sessionGateway;

  final ProfileRemoteDataSource _remote;
  final ProfileLocalDataSource _cache;
  final SessionGateway _session;
  final ConnectivityService _connectivity;

  @override
  Future<Result<UserProfile>> getProfile({bool forceRefresh = false}) async {
    final userId = _session.currentUserId;
    if (userId == null) {
      return const FailureResult(
        AuthFailure(message: 'no session', code: 'unauthenticated'),
      );
    }

    if (!forceRefresh) {
      final isOnline = await _connectivity.isOnline;
      if (!isOnline) {
        final cached = await _cache.getCachedProfile(userId);
        if (cached != null) {
          return Success(ProfileModel.fromJson(cached.json, isStale: true));
        }
      }
    }

    final remoteResult = await _remote.getMyProfile();
    return remoteResult.when(
      success: (payload) async {
        final json = (payload! as Map).cast<String, Object?>();
        await _cache.cacheProfile(userId, json);
        return Success(ProfileModel.fromJson(json, isStale: false));
      },
      failure: (failure) async {
        final cached = await _cache.getCachedProfile(userId);
        if (cached != null) {
          return Success(ProfileModel.fromJson(cached.json, isStale: true));
        }
        return FailureResult(failure);
      },
    );
  }
}
