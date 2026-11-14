/// The six assignment statuses of constitution Principle VI (v2.4.0).
///
/// UI code must always render a status as color + icon + Arabic label
/// together (see StatusChip / PartTile); color alone is prohibited.
enum AssignmentStatus {
  /// تمت القراءة
  completed,

  /// لم يُقرأ بعد
  pending,

  /// فائت
  missed,

  /// قُرئ متأخرًا
  late,

  /// متاح — current day, empty seat, nobody volunteered yet.
  available,

  /// لم يقرأه أحد — closed day, empty seat nobody read.
  unread,
}
