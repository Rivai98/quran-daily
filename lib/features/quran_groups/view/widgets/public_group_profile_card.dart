import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';

class PublicGroupProfileCard extends StatelessWidget {
  const PublicGroupProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مجموعة الورد اليومي',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text('مجموعة عامة لختم القرآن يوميا بتوزيع جزء لكل عضو.'),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('26 عضو')),
                Chip(label: Text('توقيت القاهرة')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('طلب الانضمام'),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    ArabicStrings.pendingApproval,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
