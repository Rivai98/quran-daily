import '../../../core/errors/result.dart';
import 'today_snapshot.dart';

abstract class TodayRepository {
  Future<Result<TodaySnapshot>> getToday({
    void Function(TodaySnapshot)? onCached,
  });
  Future<Result<void>> setMainGroup(String? groupId);
  Future<void> markGroupOpened(String groupId);
}
