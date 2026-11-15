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
import '../../../../core/quran/portion_unit.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
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
    this.portionUnit = PortionUnit.juz,
    this.metadataRepository,
  });

  final String groupId;
  final String groupName;
  final String? inviteCode;
  final int activeMemberCount;
  final bool isOwner;
  final SeatMap? seatMap;
  final bool loading;
  final ValueChanged<int> onStartKhatma;
  final PortionUnit portionUnit;
  final QuranMetadataRepository? metadataRepository;

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
                Text(
                  ArabicStrings.formingLabel,
                  style: AppTypography.caption.copyWith(color: colors.infoFg),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ArabicStrings.groupMembersRatio(activeMemberCount, 30),
                        style: AppTypography.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${ArabicStrings.missingX} ${ArabicNumerals.format(_missing)}',
                      style: AppTypography.body,
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final metadata = metadataRepository ?? QuranMetadataRepository();
    var startPortion = 1;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => FutureBuilder<void>(
        future: metadata.load(),
        builder: (sheetContext, metadataState) {
          if (metadataState.connectionState != ConnectionState.done ||
              metadataState.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          final count = metadata.portions(portionUnit).length;
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
                    Text(
                      portionUnit == PortionUnit.juz
                          ? ArabicStrings.startJuzChoice
                          : ArabicStrings.startPortionChoice,
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (portionUnit == PortionUnit.juz)
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (var portion = 1; portion <= count; portion++) ...[
                            SizedBox.square(
                              dimension: AppSpacing.xxl,
                              child: ChoiceChip(
                                label: Center(
                                  child: Text(ArabicNumerals.format(portion)),
                                ),
                                selected: startPortion == portion,
                                selectedColor: colors.primaryContainer,
                                labelStyle: AppTypography.label.copyWith(
                                  color: startPortion == portion
                                      ? colors.onPrimaryContainer
                                      : colors.ink,
                                ),
                                padding: EdgeInsets.zero,
                                labelPadding: EdgeInsets.zero,
                                side: BorderSide(
                                  color: startPortion == portion
                                      ? colors.primary
                                      : colors.border,
                                ),
                                onSelected: (_) => setSheetState(
                                  () => startPortion = portion,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                        ),
                        child: ListView.builder(
                          itemCount: count,
                          itemBuilder: (context, index) {
                            final portion = index + 1;
                            return ListTile(
                              selected: startPortion == portion,
                              title: Text(
                                ArabicStrings.portionName(portionUnit, portion),
                                style: AppTypography.quranLabel,
                              ),
                              onTap: () =>
                                  setSheetState(() => startPortion = portion),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: ArabicStrings.startKhatmaAction,
                      expanded: true,
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        onStartKhatma(startPortion);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
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
