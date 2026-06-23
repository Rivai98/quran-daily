import 'package:flutter/material.dart';

import '../../../../core/localization/arabic_strings.dart';
import 'dense_info_row.dart';

class AssignmentDraftRow extends StatelessWidget {
  const AssignmentDraftRow({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    return DenseInfoRow(
      icon: Icons.assignment,
      title: '${ArabicStrings.memberRole} $index',
      subtitle:
          '\u{62c}\u{632}\u{621} $index - ${ArabicStrings.readyToPublish}',
      trailing: IconButton(
        tooltip: ArabicStrings.swapPart,
        onPressed: () {},
        icon: const Icon(Icons.swap_horiz),
      ),
    );
  }
}
