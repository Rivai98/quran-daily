import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/localization/arabic_strings.dart';

class GroupSelectionScreen extends StatelessWidget {
  const GroupSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.groupSelectionTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionPanel(
            title: ArabicStrings.noApprovedGroups,
            primaryLabel: ArabicStrings.createGroup,
            secondaryLabel: ArabicStrings.discoverGroups,
            onPrimary: () => _showCreateGroupSheet(context),
            onSecondary: () => Navigator.pushNamed(context, AppRoutes.discovery),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('مجموعة الفجر'),
              subtitle: const Text('30 عضو - توقيت القاهرة - آخر مزامنة قبل 5 دقائق'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.pushNamed(context, AppRoutes.dashboard),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إنشاء مجموعة عامة',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'اسم المجموعة')),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(labelText: 'وصف قصير'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(labelText: 'المنطقة الزمنية'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(ArabicStrings.createGroup),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.title,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String title;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPrimary,
              icon: const Icon(Icons.add),
              label: Text(primaryLabel),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onSecondary,
              icon: const Icon(Icons.search),
              label: Text(secondaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
