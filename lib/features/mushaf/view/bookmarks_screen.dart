import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_card.dart';
import '../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../core/design_system/widgets/state_panel.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_strings.dart';
import '../../../core/quran/quran_metadata_repository.dart';
import '../data/reader_storage.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({
    super.key,
    required this.storage,
    required this.onOpenPage,
    this.metadata,
  });

  final ReaderStorage storage;
  final ValueChanged<int> onOpenPage;
  final QuranMetadataRepository? metadata;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late Future<List<ReaderBookmark>> _bookmarks = widget.storage.bookmarks();
  QuranMetadataRepository? _metadata;

  @override
  void initState() {
    super.initState();
    _metadata =
        widget.metadata ??
        (serviceLocator.isRegistered<QuranMetadataRepository>()
            ? serviceLocator<QuranMetadataRepository>()
            : null);
    _metadata?.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  String? _surahName(int? surah) {
    if (surah == null || _metadata == null) return null;
    try {
      return _metadata!.suraName(surah);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime dt) {
    final day = ArabicNumerals.format(dt.day);
    final month = ArabicNumerals.format(dt.month);
    final year = ArabicNumerals.format(dt.year);
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.bookmarksTitle)),
      body: FutureBuilder<List<ReaderBookmark>>(
        future: _bookmarks,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <ReaderBookmark>[];
          if (items.isEmpty) {
            return const StatePanel(
              icon: Icons.bookmark_border_outlined,
              title: ArabicStrings.bookmarksEmpty,
              message: ArabicStrings.bookmarksEmptyHint,
            );
          }
          return ListView.separated(
            padding: AppSpacing.screenContent,
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                Divider(color: colors.border, height: 1),
            itemBuilder: (context, index) {
              final bookmark = items[index];
              final surahName = _surahName(bookmark.surah);

              final String titleText;
              final String? subtitleText;

              if (surahName != null) {
                if (bookmark.ayah != null) {
                  titleText =
                      '${ArabicStrings.surahWord} $surahName، ${ArabicStrings.ayahWord} ${ArabicNumerals.format(bookmark.ayah!)}';
                } else {
                  titleText = '${ArabicStrings.surahWord} $surahName';
                }
                final pageStr =
                    '${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(bookmark.page)}';
                if (bookmark.createdAt != null) {
                  subtitleText =
                      '$pageStr، ${_formatDate(bookmark.createdAt!)}';
                } else {
                  subtitleText = pageStr;
                }
              } else {
                titleText =
                    '${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(bookmark.page)}';
                subtitleText = bookmark.createdAt != null
                    ? _formatDate(bookmark.createdAt!)
                    : null;
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bookmark, color: colors.primary, size: 20),
                ),
                title: Text(
                  titleText,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitleText != null)
                      Text(
                        subtitleText,
                        style: AppTypography.caption.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    if (bookmark.note != null && bookmark.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Text(
                          bookmark.note!,
                          style: AppTypography.body.copyWith(color: colors.ink),
                        ),
                      ),
                  ],
                ),
                onTap: () => widget.onOpenPage(bookmark.page),
                trailing: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.inkMuted),
                  tooltip: ArabicStrings.bookmarkOptions,
                  onSelected: (value) async {
                    if (value == 'delete') {
                      await widget.storage.removeBookmark(bookmark.id);
                      if (mounted) {
                        setState(() => _bookmarks = widget.storage.bookmarks());
                        AppSnackBar.show(
                          this.context,
                          ArabicStrings.bookmarkDeleted,
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: colors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            ArabicStrings.deleteBookmarkAction,
                            style: AppTypography.body.copyWith(
                              color: colors.danger,
                            ),
                          ),
                        ],
                      ),
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

class MushafLicensesScreen extends StatelessWidget {
  const MushafLicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.mushafLicensesTitle)),
      body: ListView(
        padding: AppSpacing.screenContent,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories, color: colors.primary, size: 24),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        ArabicStrings.kfgqpcSourceName,
                        style: AppTypography.title,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: AppRadius.smBR,
                      ),
                      child: Text(
                        ArabicStrings.kfgqpcVersion,
                        style: AppTypography.caption.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  ArabicStrings.kfgqpcAttribution,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${ArabicStrings.licenseLabel}: ${ArabicStrings.kfgqpcLicense}',
                  style: AppTypography.caption.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.link, size: 16, color: colors.primary),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        ArabicStrings.kfgqpcLink,
                        textDirection: TextDirection.ltr,
                        style: AppTypography.caption.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book, color: colors.primary, size: 24),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        ArabicStrings.tanzilSourceName,
                        style: AppTypography.title,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: AppRadius.smBR,
                      ),
                      child: Text(
                        ArabicStrings.tanzilVersion,
                        style: AppTypography.caption.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  ArabicStrings.tanzilAttribution,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${ArabicStrings.licenseLabel}: ${ArabicStrings.tanzilLicense}',
                  style: AppTypography.caption.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.link, size: 16, color: colors.primary),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        ArabicStrings.tanzilLink,
                        textDirection: TextDirection.ltr,
                        style: AppTypography.caption.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
