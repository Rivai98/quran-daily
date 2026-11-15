import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_avatar.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_section_header.dart';
import '../../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../../core/design_system/widgets/app_text_field.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/arabic_initials.dart';
import '../../../../core/localization/arabic_numerals.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../../cubit/group_info/group_info_cubit.dart';
import '../../data/entities/entities.dart';
import '../../services/group_photo_service.dart';
import '../widgets/portion_unit_chip.dart';
import 'member_profile_screen.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({
    super.key,
    required this.groupId,
    this.photoService,
    this.metadataRepository,
  });

  final String groupId;
  final GroupPhotoService? photoService;
  final QuranMetadataRepository? metadataRepository;

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late final GroupPhotoService _photoService;
  late final QuranMetadataRepository _metadataRepository;

  @override
  void initState() {
    super.initState();
    _photoService = widget.photoService ?? const DefaultGroupPhotoService();
    _metadataRepository =
        widget.metadataRepository ??
        (serviceLocator.isRegistered<QuranMetadataRepository>()
            ? serviceLocator<QuranMetadataRepository>()
            : QuranMetadataRepository());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GroupInfoCubit>().load(widget.groupId);
      }
    });
  }

  void _showPhotoOptions(BuildContext context, GroupInfo info) {
    final cubit = context.read<GroupInfoCubit>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: AppSpacing.screenContent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ArabicStrings.changeGroupPhoto, style: AppTypography.title),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text(ArabicStrings.pickFromGallery),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final bytes = await _photoService.pickCropAndCompress(
                    source: ImageSource.gallery,
                  );
                  if (bytes != null && mounted) {
                    await cubit.uploadPhotoBytes(bytes);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text(ArabicStrings.takePhoto),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final bytes = await _photoService.pickCropAndCompress(
                    source: ImageSource.camera,
                  );
                  if (bytes != null && mounted) {
                    await cubit.uploadPhotoBytes(bytes);
                  }
                },
              ),
              if (info.photoPath != null) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    ArabicStrings.removeGroupPhoto,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await cubit.removePhoto();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDetailsDialog(BuildContext context, GroupInfo info) {
    final cubit = context.read<GroupInfoCubit>();
    final nameController = TextEditingController(text: info.name);
    final descController = TextEditingController(text: info.description ?? '');
    String? nameError;
    String? descError;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(ArabicStrings.editGroupDetails),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: ArabicStrings.groupNameLabel,
                    controller: nameController,
                    errorText: nameError,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: ArabicStrings.shortDescriptionLabel,
                    controller: descController,
                    errorText: descError,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(ArabicStrings.cancel),
              ),
              AppButton(
                label: ArabicStrings.saveChanges,
                onPressed: () async {
                  final name = nameController.text.trim();
                  final desc = descController.text.trim();
                  var valid = true;

                  if (name.length < 3 || name.length > 60) {
                    setDialogState(() {
                      nameError = ArabicStrings.invalidGroupName;
                    });
                    valid = false;
                  } else {
                    setDialogState(() => nameError = null);
                  }

                  if (desc.length > 200) {
                    setDialogState(() {
                      descError = ArabicStrings.invalidGroupDescription;
                    });
                    valid = false;
                  } else {
                    setDialogState(() => descError = null);
                  }

                  if (!valid) return;

                  Navigator.of(dialogContext).pop();
                  final success = await cubit.updateDetails(
                    name: name,
                    description: desc.isEmpty ? null : desc,
                  );
                  if (success && context.mounted) {
                    AppSnackBar.show(context, ArabicStrings.saveChanges);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _memberRoleString(GroupRole role) {
    switch (role) {
      case GroupRole.owner:
        return ArabicStrings.memberRoleOwner;
      case GroupRole.supervisor:
        return ArabicStrings.memberRoleSupervisor;
      case GroupRole.member:
        return ArabicStrings.memberRoleMember;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.groupInfoTitle)),
      body: BlocConsumer<GroupInfoCubit, GroupInfoState>(
        listenWhen: (prev, curr) =>
            prev.actionError != curr.actionError && curr.actionError != null,
        listener: (context, state) {
          if (state.actionError != null) {
            AppSnackBar.show(context, state.actionError!);
          }
        },
        builder: (context, state) {
          if (state.status == GroupInfoStatus.loading ||
              state.status == GroupInfoStatus.initial) {
            return Center(
              child: Semantics(
                label: ArabicStrings.loading,
                child: const CircularProgressIndicator(),
              ),
            );
          }

          if (state.status == GroupInfoStatus.offline) {
            return StatePanel(
              icon: Icons.cloud_off,
              title: ArabicStrings.networkFailure,
              message: ArabicStrings.networkFailure,
              actionLabel: ArabicStrings.retry,
              onAction: () =>
                  context.read<GroupInfoCubit>().load(widget.groupId),
              isError: true,
            );
          }

          if (state.status == GroupInfoStatus.failure ||
              state.groupInfo == null) {
            return StatePanel(
              icon: Icons.error_outline,
              title: ArabicStrings.operationFailed,
              message: ArabicStrings.operationFailed,
              actionLabel: ArabicStrings.retry,
              onAction: () =>
                  context.read<GroupInfoCubit>().load(widget.groupId),
              isError: true,
            );
          }

          final info = state.groupInfo!;
          final isOwner = info.myRole == GroupRole.owner;
          final isSupervisor = info.myRole == GroupRole.supervisor;

          return RefreshIndicator(
            onRefresh: () => context.read<GroupInfoCubit>().refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.screen,
              child: Align(
                alignment: AlignmentDirectional.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      AppCard(
                        padding: AppSpacing.card,
                        child: Column(
                          children: [
                            Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                GroupAvatar(
                                  name: info.name,
                                  photoPath: info.photoPath,
                                  size: 96,
                                  radius: 24,
                                ),
                                if (isOwner)
                                  Material(
                                    color: colors.primary,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () =>
                                          _showPhotoOptions(context, info),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.camera_alt,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    info.name,
                                    style: AppTypography.headline,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (isOwner) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    tooltip: ArabicStrings.editGroupDetails,
                                    onPressed: () =>
                                        _showEditDetailsDialog(context, info),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              info.description != null &&
                                      info.description!.trim().isNotEmpty
                                  ? info.description!
                                  : ArabicStrings.noDescription,
                              style: AppTypography.body.copyWith(
                                color:
                                    info.description != null &&
                                        info.description!.trim().isNotEmpty
                                    ? colors.ink
                                    : colors.inkMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Stats Card
                      AppCard(
                        padding: AppSpacing.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppSectionHeader(
                              title: ArabicStrings.groupStats,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: AppSpacing.xs,
                              spacing: AppSpacing.sm,
                              children: [
                                Text(
                                  ArabicStrings.portionSelectorTitle,
                                  style: AppTypography.label,
                                ),
                                PortionUnitChip(
                                  unit: info.portionUnit,
                                  metadataRepository: _metadataRepository,
                                ),
                              ],
                            ),
                            const Divider(height: AppSpacing.lg),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: AppSpacing.xs,
                              spacing: AppSpacing.sm,
                              children: [
                                Text(
                                  ArabicStrings.createdDate,
                                  style: AppTypography.label,
                                ),
                                Text(
                                  '${ArabicNumerals.format(info.createdAt.year)}/${ArabicNumerals.format(info.createdAt.month)}/${ArabicNumerals.format(info.createdAt.day)}',
                                  style: AppTypography.body,
                                ),
                              ],
                            ),
                            const Divider(height: AppSpacing.lg),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: AppSpacing.xs,
                              spacing: AppSpacing.sm,
                              children: [
                                Text(
                                  ArabicStrings.groupMembers,
                                  style: AppTypography.label,
                                ),
                                Text(
                                  ArabicStrings.groupMembersRatio(
                                    info.memberCount,
                                    info.seatCapacity,
                                  ),
                                  style: AppTypography.body,
                                ),
                              ],
                            ),
                            const Divider(height: AppSpacing.lg),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: AppSpacing.xs,
                              spacing: AppSpacing.sm,
                              children: [
                                Text(
                                  ArabicStrings.completedKhatmas,
                                  style: AppTypography.label,
                                ),
                                Text(
                                  ArabicNumerals.format(info.khatmaCount),
                                  style: AppTypography.title,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Invite Code Card (Owner/Supervisor only)
                      if ((isOwner || isSupervisor) &&
                          info.inviteCode != null) ...[
                        AppCard(
                          padding: AppSpacing.card,
                          child: Row(
                            children: [
                              const Icon(Icons.link, size: 28),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ArabicStrings.inviteCodeLabel,
                                      style: AppTypography.caption.copyWith(
                                        color: colors.inkMuted,
                                      ),
                                    ),
                                    Text(
                                      info.inviteCode!,
                                      style: AppTypography.title,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: ArabicStrings.copyInviteCode,
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: info.inviteCode!),
                                  );
                                  AppSnackBar.show(
                                    context,
                                    ArabicStrings.copiedToClipboard,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Members List Section
                      AppSectionHeader(
                        title:
                            '${ArabicStrings.groupMembers} (${ArabicNumerals.format(info.members.length)})',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      for (final member in info.members) ...[
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.memberProfile,
                              arguments: MemberProfileArgs(
                                userId: member.userId,
                                groupId: info.groupId,
                              ),
                            );
                          },
                          borderRadius: AppRadius.smBR,
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(
                              bottom: AppSpacing.xs,
                            ),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: AppRadius.smBR,
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                UserAvatar(
                                  initials:
                                      member.initials ??
                                      displayInitials(member.displayName),
                                  avatarKey: member.avatarKey,
                                  size: 36,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.displayName,
                                        style: AppTypography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (member.seatNumber != null) ...[
                                        const SizedBox(height: AppSpacing.xxs),
                                        Text(
                                          ArabicStrings.historySeat(
                                            ArabicNumerals.format(
                                              member.seatNumber!,
                                            ),
                                          ),
                                          style: AppTypography.caption.copyWith(
                                            color: colors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: member.role == GroupRole.owner
                                        ? colors.primaryContainer
                                        : colors.surfaceMuted,
                                    borderRadius: AppRadius.smBR,
                                  ),
                                  child: Text(
                                    _memberRoleString(member.role),
                                    style: AppTypography.caption.copyWith(
                                      color: member.role == GroupRole.owner
                                          ? colors.primary
                                          : colors.inkMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
