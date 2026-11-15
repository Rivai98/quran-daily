import 'package:flutter/material.dart';

import '../../localization/arabic_numerals.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

enum ProgressVariant { ring, bar }

/// Progress summary: ring or bar + `display` count `١٢ / ٣٠` + percentage.
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({
    super.key,
    required this.completed,
    required this.total,
    this.variant = ProgressVariant.ring,
    this.caption,
  });

  final int completed;
  final int total;
  final ProgressVariant variant;
  final String? caption;

  int get _percent => total == 0 ? 0 : (completed * 100 / total).round();
  double get _value => total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final ratio = Text(
      ArabicNumerals.ratio(completed, total),
      style: AppTypography.display,
    );
    final percent = Text(
      ArabicNumerals.percent(_percent),
      style: AppTypography.title.copyWith(color: colors.primary),
    );

    if (variant == ProgressVariant.bar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [ratio, percent],
          ),
          const SizedBox(height: AppSpacing.xxs),
          LinearProgressIndicator(
            value: _value,
            minHeight: 8,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(caption!, style: AppTypography.caption),
          ],
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CircularProgressIndicator(
                  value: _value,
                  strokeWidth: 8,
                  strokeAlign: BorderSide.strokeAlignInside,
                  backgroundColor: colors.surfaceMuted,
                ),
              ),
              Text(
                ArabicNumerals.percent(_percent),
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation('wght', 700)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ratio,
              if (caption != null)
                Text(caption!, style: AppTypography.caption),
            ],
          ),
        ),
      ],
    );
  }
}
