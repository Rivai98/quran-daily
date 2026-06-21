import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double textSize = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('حجم نص الجزء والمدى',
                      style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: textSize,
                    min: 0.85,
                    max: 1.4,
                    divisions: 5,
                    label: '${(textSize * 100).round()}%',
                    onChanged: (value) => setState(() => textSize = value),
                  ),
                  Text(
                    'جزء 2 - البقرة 142 إلى البقرة 252',
                    style: TextStyle(fontSize: 18 * textSize),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('آخر حفظ للمجموعة المختارة: قبل 5 دقائق'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
