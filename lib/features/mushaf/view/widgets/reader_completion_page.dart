import 'package:material_ui/material_ui.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/islamic_ornament.dart';
import '../../../../core/localization/arabic_strings.dart';

class ReaderCompletionPage extends StatelessWidget {
  const ReaderCompletionPage({super.key, required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SingleChildScrollView(
      key: const ValueKey('reader-completion-page'),
      padding: AppSpacing.screenH,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          IslamicOrnamentBand(
            refined: true,
            child: Center(
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: AppSpacing.xxl,
                color: colors.primary,
                semanticLabel: ArabicStrings.completeReadingAction,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            completed
                ? ArabicStrings.readerCompletionRecorded
                : ArabicStrings.readerCompletionTitle,
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(color: colors.ink),
          ),
          if (!completed) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              ArabicStrings.readerCompletionMessage,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: colors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}
