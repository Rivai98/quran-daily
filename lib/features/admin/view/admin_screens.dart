import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_card.dart';
import '../../../core/design_system/widgets/app_page_content.dart';
import '../../../core/design_system/widgets/confirm_sheet.dart';
import '../../../core/design_system/widgets/state_panel.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_formatting.dart';
import '../../../core/localization/arabic_strings.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../data/admin_repository.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => serviceLocator<AdminCubit>()..overview(),
    child: const _AdminOverviewView(),
  );
}

class _AdminOverviewView extends StatelessWidget {
  const _AdminOverviewView();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(ArabicStrings.adminTitle)),
    body: BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        if ((state.status == AdminStatus.loading ||
                state.status == AdminStatus.initial) &&
            state.data == null) {
          return const _AdminLoading();
        }
        if (state.status == AdminStatus.offline ||
            state.status == AdminStatus.error) {
          return StatePanel(
            icon: state.status == AdminStatus.offline
                ? Icons.wifi_off
                : Icons.error_outline,
            title: ArabicStrings.adminLoadError,
            message: state.status == AdminStatus.offline
                ? ArabicStrings.adminOffline
                : ArabicStrings.adminLoadError,
            actionLabel: ArabicStrings.adminRefresh,
            onAction: () => context.read<AdminCubit>().overview(),
            isError: true,
          );
        }
        final data = state.data ?? {};
        final users = (data['users'] as Map?)?.cast<String, Object?>() ?? {};
        final groups = (data['groups'] as Map?)?.cast<String, Object?>() ?? {};
        final today = (data['today'] as Map?)?.cast<String, Object?>() ?? {};
        final khatmas =
            (data['khatmas'] as Map?)?.cast<String, Object?>() ?? {};
        final series = (data['series'] as List?)?.cast<Map>() ?? const [];
        return AppPageContent(
          child: ListView(
            padding: AppSpacing.screenContent,
            children: [
              if (state.status == AdminStatus.loading)
                const LinearProgressIndicator(),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _metric(ArabicStrings.adminTotalUsers, users['total']),
                  _metric(ArabicStrings.adminNewUsers, users['new_7d']),
                  _metric(ArabicStrings.adminNewUsers30, users['new_30d']),
                  _metric(
                    ArabicStrings.adminActiveToday,
                    users['active_today'],
                  ),
                  _metric(ArabicStrings.adminTotalGroups, groups['total']),
                  _metric(ArabicStrings.adminFormingGroups, groups['forming']),
                  _metric(ArabicStrings.adminActiveGroups, groups['active']),
                  _metric(
                    ArabicStrings.adminArchivedGroups,
                    groups['archived'],
                  ),
                  _metric(
                    ArabicStrings.adminTodayRate,
                    today['rate_percent'],
                    suffix: '٪',
                  ),
                  _metric(ArabicStrings.adminKhatmas, khatmas['last_30d']),
                  _metric(ArabicStrings.adminKhatmas7, khatmas['last_7d']),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ArabicStrings.adminLast30Days,
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: AppSpacing.xxl * 3,
                      width: double.infinity,
                      child: CustomPaint(
                        child: Semantics(
                          label: ArabicStrings.adminLast30Days,
                          child: CustomPaint(
                            painter: _CompletionChart(
                              series,
                              Theme.of(context).extension<AppColors>()!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _go(
                context,
                ArabicStrings.adminGroups,
                Icons.groups,
                '/admin/groups',
              ),
              _go(
                context,
                ArabicStrings.adminUsers,
                Icons.people,
                '/admin/users',
              ),
              _go(
                context,
                ArabicStrings.adminAudit,
                Icons.history,
                '/admin/audit',
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _metric(String label, Object? value, {String suffix = ''}) => SizedBox(
    width: AppSpacing.xxl * 5,
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            ArabicFormatting.isolate(
              suffix == '٪'
                  ? ArabicNumerals.percent(int.tryParse('$value') ?? 0)
                  : ArabicNumerals.format(int.tryParse('$value') ?? 0),
            ),
            style: AppTypography.display,
          ),
        ],
      ),
    ),
  );

  Widget _go(BuildContext context, String label, IconData icon, String route) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: AppCard(
          child: ListTile(
            leading: Icon(icon),
            title: Text(label, style: AppTypography.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, route),
          ),
        ),
      );
}

class _CompletionChart extends CustomPainter {
  _CompletionChart(this.rows, this.colors);
  final List<Map> rows;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty) return;
    final values = rows
        .map((row) => int.tryParse('${row['completed']}') ?? 0)
        .toList();
    final maxValue = values.fold<int>(1, (a, b) => a > b ? a : b);
    final paint = Paint()..color = colors.primary;
    final gap = size.width / values.length;
    final barWidth = gap * 0.55;
    for (var i = 0; i < values.length; i++) {
      final height = size.height * values[i] / maxValue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * gap + (gap - barWidth) / 2,
            size.height - height,
            barWidth,
            height,
          ),
          const Radius.circular(AppSpacing.xxs),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompletionChart old) =>
      old.rows != rows || old.colors != colors;
}

class AdminGroupsScreen extends StatelessWidget {
  const AdminGroupsScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => serviceLocator<AdminCubit>()..groups(),
    child: const _AdminListScreen(groups: true),
  );
}

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => serviceLocator<AdminCubit>()..users(),
    child: const _AdminListScreen(groups: false),
  );
}

class _AdminListScreen extends StatefulWidget {
  const _AdminListScreen({required this.groups});
  final bool groups;
  @override
  State<_AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<_AdminListScreen> {
  final _search = TextEditingController();
  Timer? _searchTimer;
  String? _status;
  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _load() => widget.groups
      ? context.read<AdminCubit>().groups(query: _search.text, status: _status)
      : context.read<AdminCubit>().users(query: _search.text, status: _status);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.groups ? ArabicStrings.adminGroups : ArabicStrings.adminUsers,
      ),
      actions: [
        if (!widget.groups)
          IconButton(
            tooltip: ArabicStrings.adminCreateUser,
            onPressed: () => _createUser(context),
            icon: const Icon(Icons.person_add_alt_1),
          ),
      ],
    ),
    body: BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        if ((state.status == AdminStatus.loading ||
                state.status == AdminStatus.initial) &&
            state.data == null) {
          return const _AdminLoading();
        }
        if (state.status == AdminStatus.offline ||
            state.status == AdminStatus.error ||
            state.status == AdminStatus.empty) {
          final offline = state.status == AdminStatus.offline;
          return StatePanel(
            icon: offline ? Icons.wifi_off : Icons.search_off,
            title: state.status == AdminStatus.empty
                ? ArabicStrings.adminEmpty
                : ArabicStrings.adminLoadError,
            message: offline
                ? ArabicStrings.adminOffline
                : ArabicStrings.adminLoadError,
            actionLabel: ArabicStrings.adminRefresh,
            onAction: _load,
            isError: !state.status.toString().contains('empty'),
          );
        }
        final items = (state.data?['items'] as List? ?? const []).cast<Map>();
        return AppPageContent(
          child: ListView(
            padding: AppSpacing.screenContent,
            children: [
              if (state.status == AdminStatus.loading)
                const LinearProgressIndicator(),
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: ArabicStrings.adminSearch,
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) {
                  _searchTimer?.cancel();
                  _searchTimer = Timer(
                    const Duration(milliseconds: 350),
                    _load,
                  );
                },
                onSubmitted: (_) {
                  _searchTimer?.cancel();
                  _load();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: ArabicStrings.adminAllStatuses,
                ),
                items:
                    [
                          null,
                          ...(widget.groups
                              ? ['forming', 'active', 'archived']
                              : ['active', 'suspended', 'admin']),
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_statusLabel(value)),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() => _status = value);
                  _load();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          widget.groups
                              ? Icons.groups_rounded
                              : Icons.person_rounded,
                        ),
                      ),
                      title: Text(
                        '${item[widget.groups ? 'name' : 'display_name'] ?? ''}',
                        style: AppTypography.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: _adminSubtitle(item),
                      trailing: Icon(
                        widget.groups
                            ? Icons.groups_rounded
                            : (item['status'] == 'suspended'
                                  ? Icons.block_rounded
                                  : Icons.person_rounded),
                      ),
                      onTap: () => Navigator.pushNamed(
                        context,
                        widget.groups ? '/admin/group' : '/admin/user',
                        arguments: item['id'],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _createUser(BuildContext context) async {
    final cubit = context.read<AdminCubit>();
    final name = TextEditingController(),
        email = TextEditingController(),
        password = TextEditingController();
    final form = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(ArabicStrings.adminCreateUserTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: ArabicStrings.adminDisplayName,
                ),
              ),
              TextField(
                controller: email,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: ArabicStrings.adminEmail,
                ),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: ArabicStrings.adminPassword,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(ArabicStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(ArabicStrings.adminCreateUser),
          ),
        ],
      ),
    );
    if (form == true && mounted) {
      final ok = await cubit.createUser(
        name: name.text.trim(),
        email: email.text.trim(),
        password: password.text,
      );
      if (ok && mounted) {
        _load();
      }
    }
    name.dispose();
    email.dispose();
    password.dispose();
  }

  String _statusLabel(String? status) => switch (status) {
    'forming' => ArabicStrings.formingLabel,
    'active' => ArabicStrings.activeLabel,
    'archived' => ArabicStrings.groupArchivedLabel,
    'suspended' => ArabicStrings.adminSuspendedStatus,
    'admin' => ArabicStrings.adminEntry,
    _ => ArabicStrings.adminAllStatuses,
  };

  Widget _adminSubtitle(Map item) {
    if (widget.groups) return Text(_groupMeta(item));
    final email = '${item['email'] ?? ''}'.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (email.isNotEmpty)
          Text(
            email,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        Text(_userMeta(item)),
      ],
    );
  }

  String _groupMeta(Map item) {
    final details = <String>[];
    final owner = '${item['owner_name'] ?? ''}'.trim();
    if (owner.isNotEmpty) details.add(owner);
    final members = int.tryParse('${item['member_count']}');
    if (members != null) {
      details.add(ArabicFormatting.membersProgress(members, total: 30));
    }
    final status = _groupStatus(item['status']);
    if (status != null) details.add(status);
    if (item['portion_unit'] != null) {
      details.add(_portionUnit(item['portion_unit']));
    }
    final created = _dateLabel(item['created_at']);
    if (created.isNotEmpty) details.add(created);
    return details.join(' · ');
  }

  String _userMeta(Map item) {
    final details = <String>[];
    final groupCount = int.tryParse('${item['groups_count']}');
    if (groupCount != null) {
      details.add(
        'المجموعات ${ArabicFormatting.isolate(ArabicNumerals.format(groupCount))}',
      );
    }
    details.add(
      _userStatus(item['status'] == 'suspended', item['is_admin'] == true),
    );
    final activity = _dateLabel(item['last_activity_at']);
    if (activity.isNotEmpty) details.add('آخر نشاط $activity');
    return details.join(' · ');
  }

  String _dateLabel(Object? value) {
    final date = DateTime.tryParse('$value');
    if (date == null) return '';
    final formatted = DateFormat('d MMMM yyyy', 'ar').format(date);
    return ArabicNumerals.format(formatted);
  }
}

class AdminGroupDetailScreen extends StatelessWidget {
  const AdminGroupDetailScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => serviceLocator<AdminCubit>()..groupDetail(groupId),
    child: _DetailView(group: true, id: groupId),
  );
}

class AdminUserDetailScreen extends StatelessWidget {
  const AdminUserDetailScreen({super.key, required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => serviceLocator<AdminCubit>()..userDetail(userId),
    child: _DetailView(group: false, id: userId),
  );
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.group, required this.id});
  final bool group;
  final String id;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        group ? ArabicStrings.adminGroupDetail : ArabicStrings.adminUserDetail,
      ),
    ),
    body: BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        if ((state.status == AdminStatus.loading ||
                state.status == AdminStatus.initial) &&
            state.data == null) {
          return const _AdminLoading();
        }
        if (state.status == AdminStatus.offline ||
            state.status == AdminStatus.error) {
          return StatePanel(
            icon: Icons.error_outline,
            title: ArabicStrings.adminLoadError,
            message: state.status == AdminStatus.offline
                ? ArabicStrings.adminOffline
                : ArabicStrings.adminLoadError,
            actionLabel: ArabicStrings.adminRefresh,
            onAction: () => group
                ? context.read<AdminCubit>().groupDetail(id)
                : context.read<AdminCubit>().userDetail(id),
            isError: true,
          );
        }
        final data = state.data ?? {};
        final entity =
            (data[group ? 'group' : 'user'] as Map?)?.cast<String, Object?>() ??
            {};
        final title = '${entity[group ? 'name' : 'display_name'] ?? ''}';
        return AppPageContent(
          child: ListView(
            padding: AppSpacing.screenContent,
            children: [
              if (state.status == AdminStatus.loading)
                const LinearProgressIndicator(),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.title),
                    if (!group) ...[
                      Text(
                        '${entity['email'] ?? ''}',
                        textDirection: TextDirection.ltr,
                      ),
                      Text(
                        _userStatus(
                          entity['status'] == 'suspended',
                          entity['is_admin'] == true,
                        ),
                      ),
                    ],
                    if (!group) ...[
                      Text(
                        '${ArabicStrings.adminNewUsers}: ${entity['created_at'] ?? ''}',
                        style: AppTypography.caption,
                      ),
                      Text(
                        '${ArabicStrings.adminGroups}: ${ArabicNumerals.format(int.tryParse('${entity['groups_count']}') ?? 0)}',
                        style: AppTypography.caption,
                      ),
                    ],
                    if (group) ...[
                      Text('${entity['owner_name'] ?? ''}'),
                      Text(
                        '${_groupStatus(entity['status'])} · ${_portionUnit(entity['portion_unit'])}',
                      ),
                    ],
                    if (group && data['today'] is Map) ...[
                      Text(
                        '${ArabicStrings.adminTodayRate}: ${ArabicNumerals.format(int.tryParse('${(data['today'] as Map)['rate_percent']}') ?? 0)}٪',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (group)
                ..._groupActions(context, entity, data)
              else ...[
                ..._userActions(context, entity),
                ...((data['groups'] as List? ?? const []).cast<Map>().map(
                  (item) => AppCard(
                    child: ListTile(
                      title: Text('${item['group_name'] ?? ''}'),
                      subtitle: Text(
                        '${_groupStatus(item['group_status'])} · ${_role(item['role'])}',
                      ),
                    ),
                  ),
                )),
              ],
            ],
          ),
        );
      },
    ),
  );

  List<Widget> _groupActions(
    BuildContext context,
    AdminJson entity,
    AdminJson data,
  ) {
    final archived = entity['status'] == 'archived';
    final members = (data['members'] as List? ?? const []).cast<Map>();
    return [
      _action(
        context,
        archived ? ArabicStrings.adminRestore : ArabicStrings.adminArchive,
        () => _confirm(
          context,
          archived ? ArabicStrings.adminRestore : ArabicStrings.adminArchive,
          () async {
            final ok = await context.read<AdminCubit>().groupAction(
              archived ? 'restore' : 'archive',
              id,
            );
            if (ok && context.mounted) {
              context.read<AdminCubit>().groupDetail(id);
            }
          },
          destructive: !archived,
        ),
      ),
      _action(context, ArabicStrings.adminRegenerateInvite, () async {
        final ok = await context.read<AdminCubit>().groupAction(
          'regenerate_invite',
          id,
        );
        if (ok && context.mounted) context.read<AdminCubit>().groupDetail(id);
      }),
      _action(
        context,
        ArabicStrings.adminDelete,
        () => _deleteGroup(context, '${entity['name'] ?? ''}'),
      ),
      const SizedBox(height: AppSpacing.sm),
      ...members.map(
        (member) => AppCard(
          child: ListTile(
            title: Text('${member['display_name'] ?? ''}'),
            subtitle: Text(
              '${_role(member['role'])} · ${ArabicNumerals.format(int.tryParse('${member['seat_number']}') ?? 0)}',
            ),
            trailing: Wrap(
              children: [
                if (member['role'] != 'owner')
                  IconButton(
                    tooltip: ArabicStrings.adminTransferOwner,
                    onPressed: () => _confirm(
                      context,
                      ArabicStrings.adminTransferOwner,
                      () async {
                        final ok = await context.read<AdminCubit>().groupAction(
                          'transfer',
                          id,
                          membershipId: '${member['membership_id']}',
                        );
                        if (ok && context.mounted) {
                          context.read<AdminCubit>().groupDetail(id);
                        }
                      },
                      destructive: true,
                    ),
                    icon: const Icon(Icons.swap_horiz),
                  ),
                if (member['role'] != 'owner')
                  IconButton(
                    tooltip: ArabicStrings.adminRemoveMember,
                    onPressed: () => _confirm(
                      context,
                      ArabicStrings.adminRemoveMember,
                      () async {
                        final ok = await context.read<AdminCubit>().groupAction(
                          'remove_member',
                          id,
                          membershipId: '${member['membership_id']}',
                        );
                        if (ok && context.mounted) {
                          context.read<AdminCubit>().groupDetail(id);
                        }
                      },
                    ),
                    icon: const Icon(Icons.person_remove_alt_1),
                  ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _userActions(BuildContext context, AdminJson user) {
    final suspended = user['status'] == 'suspended';
    final admin = user['is_admin'] == true;
    return [
      _action(
        context,
        suspended ? ArabicStrings.adminUnsuspend : ArabicStrings.adminSuspend,
        () => _confirm(
          context,
          suspended ? ArabicStrings.adminUnsuspend : ArabicStrings.adminSuspend,
          () async {
            final ok = await context.read<AdminCubit>().userAction(
              suspended ? 'unsuspend' : 'suspend',
              id,
            );
            if (ok && context.mounted) {
              context.read<AdminCubit>().userDetail(id);
            }
          },
          destructive: !suspended,
        ),
      ),
      _action(
        context,
        admin ? ArabicStrings.adminRevokeAdmin : ArabicStrings.adminGrantAdmin,
        () => _confirm(
          context,
          admin
              ? ArabicStrings.adminRevokeAdmin
              : ArabicStrings.adminGrantAdmin,
          () async {
            final ok = await context.read<AdminCubit>().userAction(
              admin ? 'revoke_admin' : 'grant_admin',
              id,
            );
            if (ok && context.mounted) {
              context.read<AdminCubit>().userDetail(id);
            }
          },
          destructive: admin,
        ),
      ),
      _action(
        context,
        ArabicStrings.adminResetPassword,
        () => _resetPassword(context),
      ),
      _action(
        context,
        ArabicStrings.adminDelete,
        () => _confirm(context, ArabicStrings.adminDeleteUserConfirm, () async {
          final ok = await context.read<AdminCubit>().userAction('delete', id);
          if (ok && context.mounted) Navigator.pop(context);
        }, destructive: true),
      ),
    ];
  }

  Widget _action(BuildContext context, String label, VoidCallback action) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: OutlinedButton(onPressed: action, child: Text(label)),
      );

  Future<void> _confirm(
    BuildContext context,
    String label,
    Future<void> Function() action, {
    bool destructive = false,
  }) async {
    final first = await ConfirmSheet.show(
      context,
      title: label,
      message: label,
      confirmLabel: label,
      destructive: destructive,
      onConfirm: () {},
    );
    if (first != true || !context.mounted) return;
    final second = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: Text(label),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(ArabicStrings.cancel),
          ),
          AppButton(
            label: label,
            variant: destructive
                ? AppButtonVariant.destructive
                : AppButtonVariant.primary,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (second == true && context.mounted) await action();
  }

  Future<void> _deleteGroup(BuildContext context, String name) async {
    final confirmed = await ConfirmSheet.show(
      context,
      title: ArabicStrings.adminDelete,
      message: ArabicStrings.adminDeleteConfirm,
      confirmLabel: ArabicStrings.adminDelete,
      destructive: true,
      onConfirm: () {},
    );
    if (confirmed != true || !context.mounted) return;
    final input = TextEditingController();
    final typed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ArabicStrings.adminDelete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ArabicStrings.adminDeleteConfirm),
            TextField(controller: input),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(ArabicStrings.cancel),
          ),
          AppButton(
            label: ArabicStrings.adminDelete,
            variant: AppButtonVariant.destructive,
            onPressed: () =>
                Navigator.pop(dialogContext, input.text.trim() == name),
          ),
        ],
      ),
    );
    input.dispose();
    if (typed == true && context.mounted) {
      final ok = await context.read<AdminCubit>().groupAction(
        'delete',
        id,
        confirmName: name,
      );
      if (ok && context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    final password = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(ArabicStrings.adminResetPassword),
        content: TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: ArabicStrings.adminPassword,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(ArabicStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(ArabicStrings.adminResetPassword),
          ),
        ],
      ),
    );
    if (submit == true && context.mounted) {
      await context.read<AdminCubit>().resetPassword(id, password.text);
    }
    password.dispose();
  }
}

class AdminAuditScreen extends StatelessWidget {
  const AdminAuditScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => serviceLocator<AdminCubit>()..audit(),
    child: const _AuditView(),
  );
}

class _AuditView extends StatefulWidget {
  const _AuditView();
  @override
  State<_AuditView> createState() => _AuditViewState();
}

class _AuditViewState extends State<_AuditView> {
  String? _action;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(ArabicStrings.adminAudit)),
    body: BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        if ((state.status == AdminStatus.loading ||
                state.status == AdminStatus.initial) &&
            state.data == null) {
          return const _AdminLoading();
        }
        if (state.status == AdminStatus.offline ||
            state.status == AdminStatus.error ||
            state.status == AdminStatus.empty) {
          return StatePanel(
            icon: Icons.history,
            title: state.status == AdminStatus.empty
                ? ArabicStrings.adminEmpty
                : ArabicStrings.adminLoadError,
            message: state.status == AdminStatus.offline
                ? ArabicStrings.adminOffline
                : ArabicStrings.adminLoadError,
            actionLabel: ArabicStrings.adminRefresh,
            onAction: () => context.read<AdminCubit>().audit(action: _action),
          );
        }
        final items = (state.data?['items'] as List? ?? const []).cast<Map>();
        return AppPageContent(
          child: ListView(
            padding: AppSpacing.screenContent,
            children: [
              if (state.status == AdminStatus.loading)
                const LinearProgressIndicator(),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: _action,
                decoration: const InputDecoration(
                  labelText: ArabicStrings.adminAllStatuses,
                ),
                items:
                    [
                          null,
                          'archive_group',
                          'delete_group',
                          'remove_member',
                          'suspend_user',
                          'unsuspend_user',
                          'create_user',
                          'reset_password',
                          'grant_admin',
                          'revoke_admin',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_auditLabel(value)),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() => _action = value);
                  context.read<AdminCubit>().audit(action: value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _auditLabel('${item['action'] ?? ''}'),
                          style: AppTypography.title,
                        ),
                        Text(
                          '${item['actor_name'] ?? ''} · ${item['target_name'] ?? ''}',
                        ),
                        Text(
                          '${item['created_at'] ?? ''} · ${item['result'] == 'succeeded' ? ArabicStrings.adminSuccessResult : ArabicStrings.adminFailureResult}',
                          style: AppTypography.caption,
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

String? _groupStatus(Object? status) => switch (status) {
  'forming' => ArabicStrings.formingLabel,
  'active' => ArabicStrings.activeLabel,
  'archived' => ArabicStrings.groupArchivedLabel,
  _ => null,
};

String _userStatus(bool suspended, bool admin) => suspended
    ? ArabicStrings.adminSuspendedStatus
    : admin
    ? ArabicStrings.adminEntry
    : ArabicStrings.activeLabel;

String _auditLabel(String? action) => switch (action) {
  'archive_group' => ArabicStrings.adminArchive,
  'restore_group' => ArabicStrings.adminRestore,
  'delete_group' => ArabicStrings.adminDelete,
  'remove_member' => ArabicStrings.adminRemoveMember,
  'suspend_user' => ArabicStrings.adminSuspend,
  'unsuspend_user' => ArabicStrings.adminUnsuspend,
  'create_user' => ArabicStrings.adminCreateUser,
  'reset_password' => ArabicStrings.adminResetPassword,
  'grant_admin' => ArabicStrings.adminGrantAdmin,
  'revoke_admin' => ArabicStrings.adminRevokeAdmin,
  _ => ArabicStrings.adminAllStatuses,
};

String _role(Object? role) => switch (role) {
  'owner' => ArabicStrings.adminOwnerRole,
  'supervisor' => ArabicStrings.adminSupervisorRole,
  _ => ArabicStrings.adminMemberRole,
};

String _portionUnit(Object? unit) => unit == 'hizb'
    ? 'حزب'
    : unit == 'rub'
    ? 'ربع حزب'
    : ArabicStrings.adminJuzUnit;

class _AdminLoading extends StatelessWidget {
  const _AdminLoading();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).extension<AppColors>()!.surfaceMuted;
    return AppPageContent(
      child: ListView(
        padding: AppSpacing.screenContent,
        children: [
          ...List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: muted,
                        borderRadius: AppRadius.smBR,
                      ),
                      child: const SizedBox(
                        height: AppSpacing.sm,
                        width: AppSpacing.xxl * 3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: muted,
                        borderRadius: AppRadius.smBR,
                      ),
                      child: const SizedBox(
                        height: AppSpacing.sm,
                        width: AppSpacing.xxl * 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
