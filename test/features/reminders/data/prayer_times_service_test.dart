import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/reminders/data/prayer_times_service.dart';

void main() {
  const cairo = PrayerLocation(
    name: 'القاهرة',
    latitude: 30.0444,
    longitude: 31.2357,
  );
  test('defaults to Egyptian authority and calculates a valid Cairo day', () {
    final service = PrayerTimesService();
    expect(service.method, PrayerCalculationMethod.egyptian);
    final result = service.calculate(DateTime(2026, 11, 15), cairo);
    expect(result.fajr.isBefore(result.asr), isTrue);
    expect(result.asr.isBefore(result.maghrib), isTrue);
  });

  test('supports switching calculation authority', () {
    final service = PrayerTimesService(
      method: PrayerCalculationMethod.ummAlQura,
    );
    expect(service.calculate(DateTime(2026, 11, 15), cairo).fajr, isNotNull);
    expect(service.method, PrayerCalculationMethod.ummAlQura);
  });
}
