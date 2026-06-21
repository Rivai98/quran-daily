import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import '../widgets/public_group_profile_card.dart';

class PublicGroupDiscoveryScreen extends StatelessWidget {
  const PublicGroupDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.discoverGroups)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          TextField(
            decoration: InputDecoration(
              labelText: 'ابحث باسم المجموعة',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          SizedBox(height: 16),
          PublicGroupProfileCard(),
          SizedBox(height: 16),
          _EmptyDiscoveryPreview(),
        ],
      ),
    );
  }
}

class _EmptyDiscoveryPreview extends StatelessWidget {
  const _EmptyDiscoveryPreview();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            Icon(Icons.search_off),
            SizedBox(width: 12),
            Expanded(child: Text(ArabicStrings.noPublicGroups)),
          ],
        ),
      ),
    );
  }
}
