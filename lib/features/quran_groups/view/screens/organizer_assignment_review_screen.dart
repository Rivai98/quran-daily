import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';

class OrganizerAssignmentReviewScreen extends StatelessWidget {
  const OrganizerAssignmentReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.organizerReviewTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(ArabicStrings.publishBlocked),
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 1; index <= 10; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('$index')),
                  title: Text('عضو $index'),
                  subtitle: Text('جزء $index - جاهز للنشر'),
                  trailing: IconButton(
                    tooltip: 'تبديل الجزء',
                    onPressed: () {},
                    icon: const Icon(Icons.swap_horiz),
                  ),
                ),
              ),
            ),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.publish),
            label: const Text('نشر ورد اليوم'),
          ),
        ],
      ),
    );
  }
}
