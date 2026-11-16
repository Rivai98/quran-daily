import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/home/data/tomorrow_rotation.dart';

void main() {
  test('continues the existing seat rotation on the next day', () {
    expect(
      tomorrowSeatPortion(
        unit: PortionUnit.juz,
        currentPortion: 1,
        seatNumber: 1,
        cycleNumber: 0,
        cycleDay: 0,
        cycleLength: 1,
      ),
      2,
    );
  });

  test('returns null when the seat has no portion after the final unit', () {
    expect(
      tomorrowSeatPortion(
        unit: PortionUnit.page,
        currentPortion: 604,
        seatNumber: 5,
        cycleNumber: 0,
        cycleDay: 20,
        cycleLength: 21,
      ),
      isNull,
    );
  });

  test('rejects inconsistent cycle metadata', () {
    expect(
      tomorrowSeatPortion(
        unit: PortionUnit.juz,
        currentPortion: 1,
        seatNumber: 1,
        cycleNumber: 0,
        cycleDay: 0,
        cycleLength: 2,
      ),
      isNull,
    );
  });
}
