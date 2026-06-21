import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../widgets/status_chip.dart';

class PersonalAssignmentDetailScreen extends StatelessWidget {
  const PersonalAssignmentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.assignmentDetailTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('جزء 2',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('البقرة 142 إلى البقرة 252'),
                  const SizedBox(height: 12),
                  const StatusChip(
                    label: ArabicStrings.pending,
                    status: ReadingStatus.pending,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check),
                    label: const Text(ArabicStrings.completeAction),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.undo),
                    label: const Text(ArabicStrings.undoAction),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(ArabicStrings.noQuranReader),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(ArabicStrings.syncQueued),
            ),
          ),
        ],
      ),
    );
  }
}
