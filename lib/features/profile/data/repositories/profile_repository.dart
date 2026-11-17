import '../../../../core/errors/result.dart';
import '../entities/profile_entities.dart';

abstract interface class ProfileRepository {
  void invalidate();
  Future<Result<UserProfile>> getProfile({bool forceRefresh = false});
}
