import '../../../core/errors/result.dart';

typedef AdminJson = Map<String, Object?>;

abstract class AdminRepository {
  Future<Result<bool>> isAdmin();
  Future<Result<AdminJson>> overview();
  Future<Result<AdminJson>> groups({String? query, String? status});
  Future<Result<AdminJson>> groupDetail(String groupId);
  Future<Result<AdminJson>> users({String? query, String? status});
  Future<Result<AdminJson>> userDetail(String userId);
  Future<Result<AdminJson>> audit({String? action});
  Future<Result<void>> groupAction(
    String action,
    String groupId, {
    String? confirmName,
    String? membershipId,
  });
  Future<Result<void>> userAction(String action, String userId);
  Future<Result<void>> createUser({
    required String name,
    required String email,
    required String password,
  });
  Future<Result<void>> resetPassword(String userId, String password);
}
