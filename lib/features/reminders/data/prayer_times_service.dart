import 'package:adhan/adhan.dart' as adhan;

import '../../../core/localization/arabic_strings.dart';
import '../domain/reminder_planner.dart';

enum PrayerCalculationMethod {
  egyptian,
  ummAlQura,
  muslimWorldLeague,
  karachi,
  isna,
}

class PrayerLocation {
  const PrayerLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
  final String name;
  final double latitude;
  final double longitude;
}

class CalculatedPrayerTimes extends PrayerTimesForDay {
  const CalculatedPrayerTimes({
    required super.fajr,
    required super.asr,
    required this.maghrib,
    required this.isha,
  });
  final DateTime maghrib;
  final DateTime isha;
}

class PrayerTimesService {
  PrayerTimesService({this.method = PrayerCalculationMethod.egyptian});
  final PrayerCalculationMethod method;

  CalculatedPrayerTimes calculate(DateTime date, PrayerLocation location) {
    final calculationMethod = switch (method) {
      PrayerCalculationMethod.egyptian => adhan.CalculationMethod.egyptian,
      PrayerCalculationMethod.ummAlQura => adhan.CalculationMethod.umm_al_qura,
      PrayerCalculationMethod.muslimWorldLeague =>
        adhan.CalculationMethod.muslim_world_league,
      PrayerCalculationMethod.karachi => adhan.CalculationMethod.karachi,
      PrayerCalculationMethod.isna => adhan.CalculationMethod.north_america,
    };
    final times = adhan.PrayerTimes(
      adhan.Coordinates(location.latitude, location.longitude),
      adhan.DateComponents(date.year, date.month, date.day),
      calculationMethod.getParameters(),
    );
    return CalculatedPrayerTimes(
      fajr: times.fajr,
      asr: times.asr,
      maghrib: times.maghrib,
      isha: times.isha,
    );
  }
}

/// Offline fallback directory. Coordinates are supplied by the package owner.
const fallbackPrayerCities = <PrayerLocation>[
  PrayerLocation(
    name: ArabicStrings.cityCairo,
    latitude: 30.0444,
    longitude: 31.2357,
  ),
  PrayerLocation(
    name: ArabicStrings.cityAlexandria,
    latitude: 31.2001,
    longitude: 29.9187,
  ),
  PrayerLocation(
    name: ArabicStrings.cityRiyadh,
    latitude: 24.7136,
    longitude: 46.6753,
  ),
  PrayerLocation(
    name: ArabicStrings.cityMakkah,
    latitude: 21.3891,
    longitude: 39.8579,
  ),
  PrayerLocation(
    name: ArabicStrings.cityMadinah,
    latitude: 24.5247,
    longitude: 39.5692,
  ),
  PrayerLocation(
    name: ArabicStrings.cityAmman,
    latitude: 31.9539,
    longitude: 35.9106,
  ),
  PrayerLocation(
    name: ArabicStrings.cityJerusalem,
    latitude: 31.7683,
    longitude: 35.2137,
  ),
  PrayerLocation(
    name: ArabicStrings.cityBeirut,
    latitude: 33.8938,
    longitude: 35.5018,
  ),
  PrayerLocation(
    name: ArabicStrings.cityDamascus,
    latitude: 33.5138,
    longitude: 36.2765,
  ),
  PrayerLocation(
    name: ArabicStrings.cityBaghdad,
    latitude: 33.3152,
    longitude: 44.3661,
  ),
  PrayerLocation(
    name: ArabicStrings.cityDoha,
    latitude: 25.2854,
    longitude: 51.5310,
  ),
  PrayerLocation(
    name: ArabicStrings.cityAbuDhabi,
    latitude: 24.4539,
    longitude: 54.3773,
  ),
  PrayerLocation(
    name: ArabicStrings.cityKuwait,
    latitude: 29.3759,
    longitude: 47.9774,
  ),
];
