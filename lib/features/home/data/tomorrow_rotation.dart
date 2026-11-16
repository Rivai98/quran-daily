import '../../../core/quran/portion_unit.dart';

/// Mirrors public.portion_for_seat from migration 20261115090001.
/// The inputs are the persisted rotation offsets, where cycleDay is zero based.
int? tomorrowSeatPortion({
  required PortionUnit unit,
  required int currentPortion,
  required int seatNumber,
  required int cycleNumber,
  required int cycleDay,
  required int cycleLength,
}) {
  final count = switch (unit) {
    PortionUnit.juz => 30,
    PortionUnit.halfJuz || PortionUnit.hizb => 60,
    PortionUnit.quarter => 240,
    PortionUnit.page => 604,
  };
  if (currentPortion < 1 ||
      currentPortion > count ||
      seatNumber < 1 ||
      seatNumber > 30 ||
      cycleDay < 0 ||
      cycleLength < 1) {
    return null;
  }
  final cycleLen = (count + 29) ~/ 30;
  final currentSeatOffset = cycleDay * 30 + seatNumber - 1;
  if (currentSeatOffset >= count) return null;
  final rawStart = currentPortion - 1 - cycleNumber - currentSeatOffset;
  final start = ((rawStart % count) + count) % count;
  final nextDay = cycleDay + 1;
  final nextCycle = nextDay >= cycleLength ? cycleNumber + 1 : cycleNumber;
  final nextCycleDay = nextDay >= cycleLength ? 0 : nextDay;
  final seatOffset = nextCycleDay * 30 + seatNumber - 1;
  if (seatOffset >= count) return null;
  // The server's generated cycle length is ceil(portion_count / 30).
  if (cycleLength != cycleLen) return null;
  return ((start + nextCycle + seatOffset) % count) + 1;
}
