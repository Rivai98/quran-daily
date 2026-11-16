import 'package:material_ui/material_ui.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/islamic_ornament.dart';
import '../../../../core/localization/arabic_strings.dart';

class SurahTitleBand extends StatelessWidget {
  const SurahTitleBand({super.key, required this.surahName});

  final String surahName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      height: AppSpacing.xxl,
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: AppRadius.mdBR,
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: AppRadius.mdBR,
              child: CustomPaint(
                painter: GirihPainter(colors.accent.withValues(alpha: 0.08)),
              ),
            ),
          ),
          PositionedDirectional(
            start: AppSpacing.md,
            child: Icon(Icons.star_rounded, size: 18, color: colors.accent),
          ),
          PositionedDirectional(
            end: AppSpacing.md,
            child: Icon(Icons.star_rounded, size: 18, color: colors.accent),
          ),
          Text(
            '${ArabicStrings.surahWord} $surahName',
            style: AppTypography.quranLabel.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
