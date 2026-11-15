import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/portion_unit.dart';
import '../../../../core/quran/quran_metadata_repository.dart';

/// Unit and cycle length shown wherever a group is summarized.
class PortionUnitChip extends StatelessWidget {
  const PortionUnitChip({
    super.key,
    required this.unit,
    required this.metadataRepository,
  });

  final PortionUnit unit;
  final QuranMetadataRepository metadataRepository;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return FutureBuilder<void>(
      future: metadataRepository.load(),
      builder: (context, state) {
        if (state.connectionState != ConnectionState.done || state.hasError) {
          return const SizedBox.shrink();
        }
        return Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: AppRadius.pillBR,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book, size: 18, color: colors.onPrimaryContainer),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  ArabicStrings.dailyUnitChip(unit),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
