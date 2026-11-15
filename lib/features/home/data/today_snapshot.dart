import 'package:equatable/equatable.dart';
import '../../../core/quran/portion_unit.dart';

DateTime _date(Object? value) => DateTime.parse(value! as String).toLocal();
Map<String, Object?> _map(Object? value) => (value as Map).cast<String, Object?>();

class TodaySnapshot extends Equatable {
  const TodaySnapshot({required this.serverGeneratedAt, required this.mainGroupId, required this.groups, this.isStale = false});
  final DateTime serverGeneratedAt;
  final String? mainGroupId;
  final List<TodayGroup> groups;
  final bool isStale;
  factory TodaySnapshot.fromJson(Map<String, Object?> json, {bool isStale = false}) => TodaySnapshot(
    serverGeneratedAt: _date(json['server_generated_at']), mainGroupId: json['main_group_id'] as String?,
    groups: (json['groups'] as List? ?? const []).map((e) => TodayGroup.fromJson(_map(e))).toList(), isStale: isStale,
  );
  Map<String, Object?> toJson() => {'server_generated_at': serverGeneratedAt.toUtc().toIso8601String(), 'main_group_id': mainGroupId, 'groups': groups.map((e) => e.toJson()).toList()};
  @override List<Object?> get props => [serverGeneratedAt, mainGroupId, groups, isStale];
}

class TodayGroup extends Equatable {
  const TodayGroup({required this.groupId, required this.name, required this.role, required this.status, required this.portionUnit, required this.isMain, required this.items, this.day, this.activeMemberCount = 0, this.photoPath});
  final String groupId, name, role, status;
  final PortionUnit portionUnit;
  final bool isMain;
  final int activeMemberCount;
  final String? photoPath;
  final TodayDay? day;
  final List<TodayItem> items;
  factory TodayGroup.fromJson(Map<String, Object?> j) => TodayGroup(
    groupId: j['group_id'] as String, name: j['name'] as String, role: j['role'] as String,
    status: j['status'] as String, portionUnit: PortionUnit.values.firstWhere((e) => e.name == j['portion_unit'], orElse: () => PortionUnit.juz),
    isMain: j['is_main'] == true, day: j['day'] == null ? null : TodayDay.fromJson(_map(j['day'])),
    activeMemberCount: (j['active_member_count'] as num?)?.toInt() ?? 0, photoPath: j['photo_path'] as String?,
    items: (j['items'] as List? ?? const []).map((e) => TodayItem.fromJson(_map(e))).toList(),
  );
  Map<String, Object?> toJson() => {'group_id': groupId, 'name': name, 'role': role, 'status': status, 'portion_unit': portionUnit.name, 'is_main': isMain,
    'day': day?.toJson(), 'items': items.map((e) => e.toJson()).toList(), 'active_member_count': activeMemberCount, 'photo_path': photoPath};
  @override List<Object?> get props => [groupId, name, role, status, portionUnit, isMain, day, items, activeMemberCount, photoPath];
}

class TodayDay extends Equatable {
  const TodayDay({required this.groupDate, required this.state, required this.endsAt, required this.closesAt, required this.cycleNumber, required this.cycleDay, required this.cycleLength, required this.completedCount, required this.totalCount, required this.restDay, this.completedMemberCount = 0});
  final String groupDate, state;
  final DateTime endsAt, closesAt;
  final int cycleNumber, cycleDay, cycleLength, completedCount, totalCount;
  final int completedMemberCount;
  final bool restDay;
  factory TodayDay.fromJson(Map<String, Object?> j) => TodayDay(groupDate: j['group_date'] as String, state: j['state'] as String,
    endsAt: _date(j['ends_at']), closesAt: _date(j['closes_at']), cycleNumber: (j['cycle_number'] as num).toInt(), cycleDay: (j['cycle_day'] as num).toInt(),
    cycleLength: (j['cycle_length'] as num).toInt(), completedCount: (j['completed_count'] as num).toInt(), totalCount: (j['total_count'] as num).toInt(), restDay: j['rest_day'] == true,
    completedMemberCount: (j['completed_member_count'] as num?)?.toInt() ?? 0);
  Map<String, Object?> toJson() => {'group_date': groupDate, 'state': state, 'ends_at': endsAt.toUtc().toIso8601String(), 'closes_at': closesAt.toUtc().toIso8601String(),
    'cycle_number': cycleNumber, 'cycle_day': cycleDay, 'cycle_length': cycleLength, 'completed_count': completedCount, 'total_count': totalCount, 'rest_day': restDay, 'completed_member_count': completedMemberCount};
  @override List<Object?> get props => [groupDate,state,endsAt,closesAt,cycleNumber,cycleDay,cycleLength,completedCount,totalCount,restDay,completedMemberCount];
}

class TodayItem extends Equatable {
  const TodayItem({required this.assignmentId, required this.kind, required this.seatNumber, required this.portionIndex, required this.status, required this.canUndo, this.completedAt});
  final String assignmentId, kind, status;
  final int seatNumber, portionIndex;
  final bool canUndo;
  final DateTime? completedAt;
  factory TodayItem.fromJson(Map<String, Object?> j) => TodayItem(assignmentId: j['assignment_id'] as String, kind: j['kind'] as String, seatNumber: (j['seat_number'] as num?)?.toInt() ?? 0,
    portionIndex: (j['portion_index'] as num).toInt(), status: j['status'] as String, canUndo: j['can_undo'] == true, completedAt: j['completed_at'] == null ? null : _date(j['completed_at']));
  Map<String, Object?> toJson() => {'assignment_id': assignmentId,'kind': kind,'seat_number': seatNumber,'portion_index': portionIndex,'status': status,'can_undo': canUndo,'completed_at': completedAt?.toUtc().toIso8601String()};
  @override List<Object?> get props => [assignmentId,kind,seatNumber,portionIndex,status,canUndo,completedAt];
}
