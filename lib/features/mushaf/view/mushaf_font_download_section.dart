import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/localization/arabic_strings.dart';
import '../cubit/mushaf_font_download_cubit.dart';

/// Settings → reading: download the Mushaf page fonts for offline reading.
///
/// Rendered inside the Settings reading card, so it has no card of its own:
/// a hairline divider, a title row, a thin status bar and full-width actions
/// with short one-line labels.
class MushafFontDownloadSection extends StatelessWidget {
  const MushafFontDownloadSection({super.key});

  static const _pageCount = 604;
  static const _bytesPerMb = 1024 * 1024;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<MushafFontDownloadCubit, MushafFontDownloadState>(
    builder: (context, state) {
      final colors = Theme.of(context).extension<AppColors>()!;
      final cubit = context.read<MushafFontDownloadCubit>();
      final downloading = state.status == MushafFontDownloadStatus.downloading;
      final complete =
          state.status == MushafFontDownloadStatus.complete ||
          (state.totalBytes > 0 && state.cachedBytes >= state.totalBytes);
      final hasSaved = state.cachedBytes > 0;
      final savedMb = (state.cachedBytes / _bytesPerMb).round();
      final totalMb = (state.totalBytes / _bytesPerMb).round();
      final pagesFraction = (state.completedPages / _pageCount).clamp(0.0, 1.0);
      final bytesFraction = state.totalBytes == 0
          ? 0.0
          : (state.cachedBytes / state.totalBytes).clamp(0.0, 1.0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: colors.border, height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.download_for_offline_rounded, color: colors.ink),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  ArabicStrings.mushafOfflineTitle,
                  style: AppTypography.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (complete && !downloading)
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: colors.completedFg,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    ArabicStrings.mushafSavedOnDevice,
                    style: AppTypography.body.copyWith(
                      color: colors.completedFg,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            ClipRRect(
              borderRadius: AppRadius.smBR,
              child: LinearProgressIndicator(
                value: downloading ? pagesFraction : bytesFraction,
                minHeight: 6,
                backgroundColor: colors.surfaceMuted,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              downloading
                  ? ArabicStrings.mushafDownloadingPercent(
                      (pagesFraction * 100).round(),
                    )
                  : ArabicStrings.mushafSavedOf(savedMb, totalMb),
              style: AppTypography.caption.copyWith(color: colors.inkMuted),
            ),
          ],
          if (state.status == MushafFontDownloadStatus.error) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: colors.danger,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    ArabicStrings.mushafFontDownloadError,
                    style: AppTypography.caption.copyWith(color: colors.danger),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (downloading)
            AppButton(
              label: ArabicStrings.mushafCancelDownload,
              icon: const Icon(Icons.close_rounded),
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: cubit.cancel,
            )
          else if (!complete)
            AppButton(
              label: hasSaved
                  ? ArabicStrings.mushafResumeDownload
                  : ArabicStrings.mushafDownloadAction,
              icon: const Icon(Icons.download_rounded),
              expanded: true,
              onPressed: cubit.downloadAll,
            ),
          if (hasSaved && !downloading) ...[
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: ArabicStrings.mushafDeleteSaved,
              icon: const Icon(Icons.delete_outline_rounded),
              variant: AppButtonVariant.text,
              expanded: true,
              onPressed: cubit.deleteCache,
            ),
          ],
        ],
      );
    },
  );
}
