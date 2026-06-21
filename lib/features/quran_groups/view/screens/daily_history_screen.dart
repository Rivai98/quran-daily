import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';

class DailyHistoryScreen extends StatelessWidget {
  const DailyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final days = [
      ('20 يونيو', '30 / 30', '100%', 'لا توجد أجزاء فائتة'),
      ('19 يونيو', '27 / 30', '90%', '3 أجزاء فائتة'),
      ('18 يونيو', '29 / 30', '97%', 'جزء مكتمل متأخر'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.historyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(ArabicStrings.emptyHistory),
            ),
          ),
          const SizedBox(height: 12),
          for (final day in days)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(day.$1),
                  subtitle: Text('${day.$2} - ${day.$4}'),
                  trailing: Text(
                    day.$3,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
