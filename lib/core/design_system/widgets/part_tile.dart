import 'package:flutter/material.dart';

import '../../localization/arabic_numerals.dart';
import '../../localization/arabic_strings.dart';
import '../app_colors.dart';
import '../app_typography.dart';
import '../assignment_status.dart';
import 'status_chip.dart';

/// One of the 30 juz cells of the progress grid: Arabic-Indic number +
/// status icon + status background. The member's own juz gets a primary
/// outline; the semantic label reads "الجزء ٥، الحالة، جزؤك".
class PartTile extends StatelessWidget {
  const PartTile({
    super.key,
    required this.juz,
    required this.status,
    this.isMine = false,
    this.onTap,
  });

  final int juz;
  final AssignmentStatus status;
  final bool isMine;
  final VoidCallback? onTap;

  String get _semanticLabel {
    final buffer = StringBuffer(
      '${ArabicStrings.partLabel} ${ArabicNumerals.format(juz)}'
      '، ${status.label}',
    );
    if (isMine) {
      buffer.write('، ${ArabicStrings.mineSuffix}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final fg = colors.statusFg(status);

    return Semantics(
      label: _semanticLabel,
      container: true,
      button: onTap != null,
      enabled: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: ShapeDecoration(
              color: colors.statusBg(status),
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                side: isMine
                    ? BorderSide(color: colors.primary, width: 2)
                    : BorderSide.none,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ArabicNumerals.format(juz),
                  style: AppTypography.label.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontVariations: const [FontVariation('wght', 700)],
                  ),
                ),
                Icon(status.icon, size: 14, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
