import '../../../core/errors/result.dart';
import 'today_snapshot.dart';

abstract class TodayRepository {
  Future<Result<TodaySnapshot>> getToday();
  Future<Result<void>> setMainGroup(String? groupId);
  Future<void> markGroupOpened(String groupId);
}
