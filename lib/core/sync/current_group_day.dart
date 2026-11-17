/// `ends_at` is the server's group-local midnight expressed as an instant.
/// Using it avoids assuming that the device and group share a timezone.
bool groupDayExpired(Map? day, DateTime now) =>
    day != null && !now.isBefore(DateTime.parse(day['ends_at'] as String));

Map<String, Object?> currentTodayJson(
  Map<String, Object?> json,
  DateTime now,
) => {
  ...json,
  'groups': [
    for (final raw in json['groups'] as List? ?? const [])
      if (groupDayExpired((raw as Map)['day'] as Map?, now))
        {...raw.cast<String, Object?>(), 'day': null, 'items': <Object?>[]}
      else
        raw,
  ],
};

Map<String, Object?> currentDashboardJson(
  Map<String, Object?> json,
  DateTime now,
) => groupDayExpired(json['today'] as Map?, now)
    ? {
        ...json,
        'today': null,
        'my_assignments': <Object?>[],
        'assignments': <Object?>[],
      }
    : json;
