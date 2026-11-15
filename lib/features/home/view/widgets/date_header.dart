import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';

class DateHeader extends StatelessWidget {
  const DateHeader({super.key, required this.date});
  final DateTime date;
  static const _months = [
    'محرم','صفر','ربيع الأول','ربيع الآخر','جمادى الأولى','جمادى الآخرة',
    'رجب','شعبان','رمضان','شوال','ذو القعدة','ذو الحجة',
  ];
  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendar.fromDate(date);
    final hijriText = '${ArabicNumerals.format(hijri.hDay)} ${_months[hijri.hMonth - 1]} ${ArabicNumerals.format(hijri.hYear)}';
    final gregorian = DateFormat('EEEE d MMMM y', 'ar').format(date);
    final localizedGregorian = ArabicNumerals.format(gregorian);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(hijriText, style: AppTypography.title),
      const SizedBox(height: AppSpacing.xxs),
      Text(localizedGregorian, style: AppTypography.caption),
    ]);
  }
}
