import 'package:flutter/material.dart';
import '../../../../app/router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/assignment_status.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/status_chip.dart';
import '../../../../core/design_system/widgets/skeleton.dart';
import '../../../../core/design_system/widgets/state_panel.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/portion_unit.dart';
import '../../../../core/quran/quran_metadata_repository.dart';
import '../data/entities/log_entities.dart';

class LogDayDetailScreen extends StatefulWidget {
  const LogDayDetailScreen({
    super.key,
    required this.day,
    this.metadataRepository,
  });
  final LogDay day;
  final QuranMetadataRepository? metadataRepository;
  @override
  State<LogDayDetailScreen> createState() => _LogDayDetailScreenState();
}

class _LogDayDetailScreenState extends State<LogDayDetailScreen> {
  late final QuranMetadataRepository _metadata =
      widget.metadataRepository ??
      (serviceLocator.isRegistered<QuranMetadataRepository>()
          ? serviceLocator<QuranMetadataRepository>()
          : QuranMetadataRepository());
  late Future<void> _load = _metadata.load();

  void _retryLoad() => setState(() => _load = _metadata.load());

  PortionUnit _unit(String value) => switch (value) {
    'half_juz' => PortionUnit.halfJuz,
    'hizb' => PortionUnit.hizb,
    'quarter' => PortionUnit.quarter,
    'page' => PortionUnit.page,
    _ => PortionUnit.juz,
  };

  AssignmentStatus _status(LogItemStatus status) => switch (status) {
    LogItemStatus.completed => AssignmentStatus.completed,
    LogItemStatus.late => AssignmentStatus.late,
    LogItemStatus.missed => AssignmentStatus.missed,
    LogItemStatus.pending => AssignmentStatus.pending,
    LogItemStatus.unread => AssignmentStatus.unread,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(ArabicStrings.logDayDetails)),
    body: FutureBuilder<void>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ListView(
            padding: AppSpacing.screenContent,
            children: const [
              SkeletonBox(height: 144),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(height: 144),
            ],
          );
        }
        if (snapshot.hasError) {
          return StatePanel(
            icon: Icons.error_outline_rounded,
            title: ArabicStrings.logErrorTitle,
            message: ArabicStrings.logErrorMessage,
            actionLabel: ArabicStrings.retryAction,
            onAction: _retryLoad,
            isError: true,
          );
        }
        return ListView(
          padding: AppSpacing.screenContent,
          children: [
            for (final item in widget.day.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        item.groupName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Builder(
                        builder: (_) {
                          final unit = _unit(item.portionUnit);
                          final portion = _metadata.portion(
                            unit,
                            item.portionIndex,
                          );
                          final name = ArabicStrings.portionName(
                            unit,
                            item.portionIndex,
                          );
                          final range = ArabicStrings.portionRange(
                            _metadata.suraName(portion.startSura),
                            portion.startAya,
                            _metadata.suraName(portion.endSura),
                            portion.endAya,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                name,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                range,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          StatusChip(status: _status(item.status)),
                          if (item.kind == LogItemKind.volunteer)
                            Chip(
                              avatar: const Icon(Icons.volunteer_activism),
                              label: const Text(ArabicStrings.logVolunteered),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppButton(
                        label: ArabicStrings.logGroupHistoryAction,
                        variant: AppButtonVariant.text,
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.history,
                          arguments: {
                            'groupId': item.groupId,
                            'date': widget.day.date.toIso8601String().substring(
                              0,
                              10,
                            ),
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
