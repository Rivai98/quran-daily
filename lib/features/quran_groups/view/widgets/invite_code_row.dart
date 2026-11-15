import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../../core/localization/arabic_strings.dart';

/// Invite code with copy and share actions.
///
/// The code is always shown with Latin letters and digits, left-to-right,
/// exactly as members type it; it is never converted to Arabic-Indic digits.
class InviteCodeRow extends StatelessWidget {
  const InviteCodeRow({super.key, required this.code, required this.groupName});

  final String code;
  final String groupName;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      AppSnackBar.show(context, ArabicStrings.inviteCodeCopied);
    }
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: ArabicStrings.inviteShareText(groupName: groupName, code: code),
        subject: ArabicStrings.inviteShareSubject,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: ArabicStrings.copyInviteCode,
            child: InkWell(
              onTap: () => _copy(context),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Flexible(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          code,
                          semanticsLabel:
                              '${ArabicStrings.inviteCodeLabel} $code',
                          style: AppTypography.bodyLarge.copyWith(
                            letterSpacing: 2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.copy_rounded, size: 18, color: colors.inkMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          label: ArabicStrings.shareInviteAction,
          variant: AppButtonVariant.tonal,
          onPressed: () => _share(context),
          icon: const Icon(Icons.share_rounded),
        ),
      ],
    );
  }
}
