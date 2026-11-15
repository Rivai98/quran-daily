import 'package:flutter/material.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../../core/design_system/widgets/skeleton.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../data/entities/entities.dart';

/// Forming state of S5 (ui-contract): member ratio, missing seats, invite
/// code + share, and the owner's start action. Data comes from the dashboard
/// snapshot's [SeatMap]; starting flows through [onStartKhatma] (wired to
/// GroupSettingsCubit by the dashboard screen).
class FormingGroupView extends StatelessWidget {
  const FormingGroupView({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.inviteCode,
    required this.activeMemberCount,
    required this.isOwner,
    this.seatMap,
    this.loading = false,
    required this.onStartKhatma,
  });

  final String groupId;
  final String groupName;
  final String? inviteCode;
  final int activeMemberCount;
  final bool isOwner;
  final SeatMap? seatMap;
  final bool loading;
  final ValueChanged<int> onStartKhatma;

  int get _missing => 30 - activeMemberCount;

  void _shareInvite(BuildContext context) {
    final code = inviteCode;
    if (code == null) return;
    AppSnackBar.show(
      context,
      '${ArabicStrings.formingInviteSnack}$code — qurandaily://join/$code',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return ListView(
      padding: AppSpacing.screen,
      children: [
        AppCard(
          highlighted: true,
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        ArabicStrings.formingLabel,
                        style: AppTypography.caption.copyWith(
                          color: colors.pendingFg,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      ArabicNumerals.ratio(activeMemberCount, 30),
                      style: AppTypography.title,
                    ),
                    Text(
                      ' · ${ArabicStrings.missingX} ${ArabicNumerals.format(_missing)}',
                      style: AppTypography.title,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  ArabicStrings.formingStartHint,
                  style: AppTypography.caption.copyWith(color: colors.inkMuted),
                ),
                if (inviteCode != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ArabicNumerals.format(inviteCode!),
                          style: AppTypography.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppButton(
                        label: ArabicStrings.shareInviteAction,
                        variant: AppButtonVariant.tonal,
                        onPressed: () => _shareInvite(context),
                        icon: const Icon(Icons.share),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SeatList(seatMap: seatMap, loading: loading),
        const SizedBox(height: AppSpacing.lg),
        if (isOwner)
          AppButton(
            label: ArabicStrings.startKhatmaAction,
            expanded: true,
            onPressed: () => _showStartSheet(context),
            icon: const Icon(Icons.play_arrow),
          ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  void _showStartSheet(BuildContext context) {
    var startJuz = 1;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ArabicStrings.startKhatmaAction,
                    style: AppTypography.title,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(ArabicStrings.startJuzChoice, style: AppTypography.body),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (var juz = 1; juz <= 30; juz++)
                        ChoiceChip(
                          label: Text(ArabicNumerals.format(juz)),
                          selected: startJuz == juz,
                          onSelected: (_) =>
                              setSheetState(() => startJuz = juz),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: ArabicStrings.startKhatmaAction,
                    expanded: true,
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onStartKhatma(startJuz);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SeatList extends StatelessWidget {
  const _SeatList({required this.seatMap, required this.loading});

  final SeatMap? seatMap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    if (loading) {
      return AppCard(
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                const SkeletonBox(height: 14),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      );
    }

    final members = seatMap?.members ?? const <SeatMember>[];
    final emptySeats = seatMap?.emptySeats ?? const <int>[];

    return AppCard(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final member in members)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: AppSpacing.xl,
                      child: Text(
                        ArabicNumerals.format(member.seatNumber),
                        style: AppTypography.label,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        member.displayName,
                        style: AppTypography.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.role == GroupRole.owner)
                      Text(
                        ArabicStrings.roleOwner,
                        style: AppTypography.caption.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    if (member.role == GroupRole.supervisor)
                      Text(
                        ArabicStrings.roleSupervisor,
                        style: AppTypography.caption.copyWith(
                          color: colors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            for (final seat in emptySeats.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: AppSpacing.xl,
                      child: Text(
                        ArabicNumerals.format(seat),
                        style: AppTypography.label,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        ArabicStrings.vacantSeat,
                        style: AppTypography.caption.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (emptySeats.length > 5)
              Text(
                '+ ${ArabicNumerals.format(emptySeats.length - 5)} '
                '${ArabicStrings.moreVacantSeats}',
                style: AppTypography.caption.copyWith(color: colors.inkMuted),
              ),
          ],
        ),
      ),
    );
  }
}
