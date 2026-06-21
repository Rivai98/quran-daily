import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';

class MemberManagementScreen extends StatelessWidget {
  const MemberManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.memberManagementTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('جاهزية المجموعة',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('29 / 30 عضو نشط'),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 29 / 30,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 1; index <= 8; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('$index')),
                  title: Text(index == 1 ? 'مالك المجموعة' : 'عضو $index'),
                  subtitle: Text(index == 1 ? 'مالك' : 'عضو'),
                  trailing: const Icon(Icons.verified_user_outlined),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
