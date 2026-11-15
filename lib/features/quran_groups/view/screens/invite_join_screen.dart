import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/widgets/widgets.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../cubit/join/join_cubit.dart';
import '../../data/entities/entities.dart';
import '../widgets/public_group_card.dart';
import '../widgets/join_status_badge.dart';
import '../../../../core/quran/quran_metadata_repository.dart';

class InviteJoinScreen extends StatefulWidget {
  const InviteJoinScreen({
    super.key,
    this.initialCode,
    this.joinAnyMode = false,
    this.metadataRepository,
  });

  final String? initialCode;
  final bool joinAnyMode;
  final QuranMetadataRepository? metadataRepository;

  @override
  State<InviteJoinScreen> createState() => _InviteJoinScreenState();
}

class _InviteJoinScreenState extends State<InviteJoinScreen> {
  final _fallbackMetadataRepository = QuranMetadataRepository();
  QuranMetadataRepository get _metadataRepository =>
      widget.metadataRepository ?? _fallbackMetadataRepository;
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    if ((widget.initialCode ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<JoinCubit>().previewInvite(widget.initialCode!);
        }
      });
    }
    if (widget.joinAnyMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _joinAny());
    }
  }

  Future<void> _joinAny() async {
    var timezone = 'UTC';
    try {
      timezone = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      // UTC is a valid IANA fallback if the device timezone cannot be read.
    }
    if (mounted) context.read<JoinCubit>().joinAny(timezone);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.inviteJoinScreenTitle)),
      body: BlocBuilder<JoinCubit, JoinState>(
        builder: (context, state) {
          final profile = state.preview;
          final canJoin =
              profile != null &&
              profile.status != GroupStatus.archived &&
              profile.activeMemberCount < 30;
          return ListView(
            padding: AppSpacing.screen,
            children: [
              if (!widget.joinAnyMode)
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: ArabicStrings.inviteCodeLabel,
                  ),
                  onSubmitted: context.read<JoinCubit>().previewInvite,
                ),
              if (!widget.joinAnyMode) const SizedBox(height: AppSpacing.sm),
              if (!widget.joinAnyMode)
                AppButton(
                  label: ArabicStrings.previewInviteAction,
                  variant: AppButtonVariant.tonal,
                  expanded: true,
                  loading:
                      state.status == JoinStatus.loading && profile == null,
                  onPressed: state.status == JoinStatus.loading
                      ? null
                      : () => context.read<JoinCubit>().previewInvite(
                          _codeController.text,
                        ),
                ),
              if (!widget.joinAnyMode && state.failure != null) ...[
                const SizedBox(height: AppSpacing.sm),
                StatePanel(
                  icon: Icons.error_outline,
                  title: state.failure!.code == 'validation_failed'
                      ? ArabicStrings.inviteCodeInvalid
                      : ArabicStrings.joinError,
                  message: state.failure!.code == 'invite_invalid'
                      ? ArabicStrings.inviteUnavailable
                      : ArabicStrings.authError(state.failure!.code),
                  isError: true,
                ),
              ],
              if (profile != null) ...[
                const SizedBox(height: AppSpacing.lg),
                PublicGroupCard(
                  group: profile,
                  metadataRepository: _metadataRepository,
                ),
                if (!canJoin) ...[
                  const SizedBox(height: AppSpacing.sm),
                  StatePanel(
                    icon: profile.status == GroupStatus.archived
                        ? Icons.archive_outlined
                        : Icons.group_off_outlined,
                    title: profile.status == GroupStatus.archived
                        ? ArabicStrings.groupArchivedLabel
                        : ArabicStrings.groupFull,
                    message: ArabicStrings.inviteUnavailable,
                  ),
                ],
                if (state.status == JoinStatus.pending) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const JoinStatusBadge(pending: true),
                ],
                if (state.status == JoinStatus.joined) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const JoinStatusBadge(pending: false),
                ],
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: state.status == JoinStatus.pending
                      ? ArabicStrings.pendingApproval
                      : ArabicStrings.joinGroupAction,
                  icon: const Icon(Icons.group_add_outlined),
                  variant: AppButtonVariant.primary,
                  expanded: true,
                  loading: state.status == JoinStatus.loading,
                  onPressed:
                      !canJoin ||
                          state.status == JoinStatus.pending ||
                          state.status == JoinStatus.joined ||
                          state.status == JoinStatus.loading
                      ? null
                      : context.read<JoinCubit>().joinInvite,
                ),
              ],
              if (widget.joinAnyMode && state.status == JoinStatus.joined) ...[
                const SizedBox(height: AppSpacing.lg),
                const JoinStatusBadge(pending: false),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  ArabicStrings.joinGroupAction,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              if (widget.joinAnyMode && state.status == JoinStatus.pending) ...[
                const SizedBox(height: AppSpacing.lg),
                const JoinStatusBadge(pending: true),
              ],
              if (widget.joinAnyMode && state.status == JoinStatus.failure) ...[
                const SizedBox(height: AppSpacing.lg),
                StatePanel(
                  icon: state.failure?.code == 'no_group_available'
                      ? Icons.group_off_outlined
                      : Icons.error_outline,
                  title: state.failure?.code == 'no_group_available'
                      ? ArabicStrings.noPublicGroups
                      : ArabicStrings.joinError,
                  message: ArabicStrings.authError(
                    state.failure?.code ?? 'network',
                  ),
                  actionLabel: ArabicStrings.retry,
                  onAction: _joinAny,
                  isError: state.failure?.code != 'no_group_available',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
