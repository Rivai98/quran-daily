import '../../../../core/errors/result.dart';
import '../entities/log_entities.dart';

abstract interface class LogRepository {
  Future<Result<PersonalLog>> getLog({
    String? before,
    int days = 30,
    void Function(PersonalLog)? onCached,
  });
}
