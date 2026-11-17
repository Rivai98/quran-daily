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
    this.now = DateTime.now,
    this.nextRollover,
  }) : _session = sessionGateway;

  final ProfileRemoteDataSource _remote;
  final ProfileLocalDataSource _cache;
  final SessionGateway _session;
  final ConnectivityService _connectivity;

  final DateTime Function() now;
  final Future<DateTime?> Function()? nextRollover;
  final Map<String, ({UserProfile profile, DateTime expiresAt})> _profiles = {};
  final Map<String, Future<Result<UserProfile>>> _requests = {};
  final Map<String, int> _versions = {};

  @override
  void invalidate() {
    final userId = _session.currentUserId;
    if (userId == null) return;
    _profiles.remove(userId);
    _requests.remove(userId);
    _versions[userId] = (_versions[userId] ?? 0) + 1;
  }

  @override
  Future<Result<UserProfile>> getProfile({bool forceRefresh = false}) {
    final userId = _session.currentUserId;
    if (userId == null) {
      return Future.value(
        const FailureResult(
          AuthFailure(message: 'no session', code: 'unauthenticated'),
        ),
      );
    }

    final cached = _profiles[userId];
    if (!forceRefresh && cached != null && now().isBefore(cached.expiresAt)) {
      return Future.value(Success(cached.profile));
    }
    final running = _requests[userId];
    if (running != null) return running;
    late Future<Result<UserProfile>> request;
    request = _fetch(userId, _versions[userId] ?? 0, forceRefresh).whenComplete(
      () {
        if (identical(_requests[userId], request)) _requests.remove(userId);
      },
    );
    _requests[userId] = request;
    return request;
  }

  Future<Result<UserProfile>> _fetch(
    String userId,
    int version,
    bool forceRefresh,
  ) async {
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
    if (_session.currentUserId != userId) {
      return const FailureResult(
        AuthFailure(message: 'session changed', code: 'unauthenticated'),
      );
    }
    if ((_versions[userId] ?? 0) != version) return getProfile();
    return remoteResult.when(
      success: (payload) async {
        final json = (payload! as Map).cast<String, Object?>();
        final profile = ProfileModel.fromJson(json, isStale: false);
        final rollover = await nextRollover?.call();
        if ((_versions[userId] ?? 0) != version) return getProfile();
        await _cache.cacheProfile(userId, json);
        if ((_versions[userId] ?? 0) != version) return getProfile();
        var expires = now().add(const Duration(minutes: 5));
        if (rollover != null &&
            rollover.isAfter(now()) &&
            rollover.isBefore(expires)) {
          expires = rollover;
        }
        _profiles[userId] = (profile: profile, expiresAt: expires);
        return Success(profile);
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
