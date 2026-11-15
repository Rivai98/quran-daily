import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_card.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_strings.dart';
import '../cubit/mushaf_font_download_cubit.dart';

class MushafFontDownloadSection extends StatelessWidget {
  const MushafFontDownloadSection({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<MushafFontDownloadCubit, MushafFontDownloadState>(
    builder: (context, state) {
      final cubit = context.read<MushafFontDownloadCubit>();
      final downloading = state.status == MushafFontDownloadStatus.downloading;
      final progress = state.totalBytes == 0
          ? '٠'
          : ArabicNumerals.format((state.cachedBytes / (1024 * 1024)).round());
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories_rounded, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    ArabicStrings.mushafDownloadAll,
                    style: AppTypography.title,
                  ),
                ),
              ],
            ),
            Text(
              '${ArabicStrings.mushafFontSizeHint} · ${ArabicStrings.cachedFontSize(progress)}',
              style: AppTypography.caption,
            ),
            if (downloading) ...[
              LinearProgressIndicator(value: state.completedPages / 604),
              Text(
                '${ArabicNumerals.format(state.completedPages)} / ${ArabicNumerals.format(604)}',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
            if (state.status == MushafFontDownloadStatus.complete)
              Text(
                ArabicStrings.mushafDownloaded,
                style: AppTypography.caption,
              ),
            if (state.status == MushafFontDownloadStatus.error)
              Text(
                ArabicStrings.mushafFontDownloadError,
                style: AppTypography.caption,
              ),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: downloading
                        ? ArabicStrings.mushafCancelDownload
                        : ArabicStrings.mushafDownloadAll,
                    icon: Icon(
                      downloading
                          ? Icons.close_rounded
                          : Icons.download_rounded,
                    ),
                    variant: downloading
                        ? AppButtonVariant.secondary
                        : AppButtonVariant.primary,
                    onPressed: downloading ? cubit.cancel : cubit.downloadAll,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppButton(
                    label: ArabicStrings.mushafDeleteFonts,
                    variant: AppButtonVariant.secondary,
                    onPressed: state.cachedBytes == 0 || downloading
                        ? null
                        : cubit.deleteCache,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
