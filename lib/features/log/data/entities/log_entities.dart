import 'package:equatable/equatable.dart';

enum LogItemStatus { completed, late, missed, pending, unread }

enum LogItemKind { seat, override, volunteer }

class LogMonthSummary extends Equatable {
  const LogMonthSummary({
    required this.year,
    required this.month,
    required this.fullDays,
    required this.daysWithItems,
  });
  final int year;
  final int month;
  final int fullDays;
  final int daysWithItems;
  factory LogMonthSummary.fromJson(Map<String, Object?> json) =>
      LogMonthSummary(
        year: json['year'] as int,
        month: json['month'] as int,
        fullDays: json['full_days'] as int,
        daysWithItems: json['days_with_items'] as int,
      );
  @override
  List<Object?> get props => [year, month, fullDays, daysWithItems];
}

class LogItem extends Equatable {
  const LogItem({
    required this.groupId,
    required this.groupName,
    required this.portionUnit,
    required this.portionIndex,
    required this.kind,
    required this.status,
    required this.completedAt,
    required this.groupDayId,
  });
  final String groupId;
  final String groupName;
  final String portionUnit;
  final int portionIndex;
  final LogItemKind kind;
  final LogItemStatus status;
  final DateTime? completedAt;
  final String groupDayId;
  factory LogItem.fromJson(Map<String, Object?> json) => LogItem(
    groupId: json['group_id'] as String,
    groupName: json['group_name'] as String,
    portionUnit: json['portion_unit'] as String,
    portionIndex: json['portion_index'] as int,
    kind: LogItemKind.values.byName(json['kind'] as String),
    status: LogItemStatus.values.byName(json['status'] as String),
    completedAt: json['completed_at'] == null
        ? null
        : DateTime.parse(json['completed_at'] as String),
    groupDayId: json['group_day_id'] as String,
  );
  @override
  List<Object?> get props => [
    groupId,
    groupName,
    portionUnit,
    portionIndex,
    kind,
    status,
    completedAt,
    groupDayId,
  ];
}

class LogDay extends Equatable {
  const LogDay({
    required this.date,
    required this.complete,
    required this.items,
  });
  final DateTime date;
  final bool complete;
  final List<LogItem> items;
  factory LogDay.fromJson(Map<String, Object?> json) => LogDay(
    date: DateTime.parse(json['date'] as String),
    complete: json['complete'] as bool,
    items: (json['items'] as List)
        .map((item) => LogItem.fromJson((item as Map).cast<String, Object?>()))
        .toList(growable: false),
  );
  @override
  List<Object?> get props => [date, complete, items];
}

class PersonalLog extends Equatable {
  const PersonalLog({
    required this.streak,
    required this.bestStreak,
    required this.month,
    required this.days,
    required this.nextBefore,
    this.isStale = false,
  });
  final int streak;
  final int bestStreak;
  final LogMonthSummary month;
  final List<LogDay> days;
  final String? nextBefore;
  final bool isStale;
  PersonalLog copyWith({bool? isStale}) => PersonalLog(
    streak: streak,
    bestStreak: bestStreak,
    month: month,
    days: days,
    nextBefore: nextBefore,
    isStale: isStale ?? this.isStale,
  );
  factory PersonalLog.fromJson(Map<String, Object?> json) => PersonalLog(
    streak: json['streak'] as int,
    bestStreak: json['best_streak'] as int,
    month: LogMonthSummary.fromJson(
      (json['month'] as Map).cast<String, Object?>(),
    ),
    days: (json['days'] as List)
        .map((day) => LogDay.fromJson((day as Map).cast<String, Object?>()))
        .toList(growable: false),
    nextBefore: json['next_before'] as String?,
  );
  @override
  List<Object?> get props => [
    streak,
    bestStreak,
    month,
    days,
    nextBefore,
    isStale,
  ];
}
