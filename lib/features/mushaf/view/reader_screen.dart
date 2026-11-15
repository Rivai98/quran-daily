import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/assignment_status.dart' as ds;
import '../../../core/design_system/widgets/offline_banner.dart';
import '../../../core/design_system/widgets/status_chip.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_strings.dart';
import '../../../core/quran/mushaf/mushaf_repository.dart';
import '../../../core/quran/quran_metadata_repository.dart';
import '../cubit/reader_cubit.dart';
import '../data/reader_storage.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.repository,
    required this.storage,
    required this.metadata,
  });

  final MushafRepository repository;
  final ReaderStorage storage;
  final QuranMetadataRepository metadata;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final PageController _pages;
  final GlobalKey _startAyahKey = GlobalKey();
  String? _dua;

  @override
  void initState() {
    super.initState();
    _pages = PageController(
      initialPage: (context.read<ReaderCubit>().state.page?.number ?? 1) - 1,
    );
    _loadDua();
    widget.metadata.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadDua() async {
    try {
      final text = await rootBundle.loadString('assets/text/khatm_dua.txt');
      if (mounted && text.trim().isNotEmpty) {
        setState(() => _dua = text);
      }
    } on FlutterError {
      // The owner-provided asset is optional. No placeholder is shown.
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReaderCubit, ReaderState>(
      listenWhen: (previous, current) =>
          current.status == ReaderStatus.content &&
          previous.page?.number != current.page?.number,
      listener: (context, state) {
        final page = state.page?.number;
        if (page != null && _pages.hasClients) _pages.jumpToPage(page - 1);
        if (state.isStartPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ayahContext = _startAyahKey.currentContext;
            if (ayahContext != null) {
              Scrollable.ensureVisible(
                ayahContext,
                alignment: 0.3,
                duration: Duration.zero,
              );
            }
          });
        }
      },
      child: BlocBuilder<ReaderCubit, ReaderState>(
        builder: (context, state) {
          final colors = Theme.of(context).extension<AppColors>()!;
          final page = state.page;
          return Scaffold(
            appBar: AppBar(
              title: Text(ArabicStrings.mushafTitle),
              actions: [
                IconButton(
                  tooltip: ArabicStrings.mushafIndexAction,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.mushafIndex),
                  icon: const Icon(Icons.list),
                ),
                IconButton(
                  tooltip: ArabicStrings.bookmarksTitle,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.mushafBookmarks,
                    arguments: widget.storage,
                  ),
                  icon: const Icon(Icons.bookmark_outline),
                ),
                IconButton(
                  tooltip: ArabicStrings.mushafLicensesTitle,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.mushafLicenses),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            body: switch (state.status) {
              ReaderStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              ReaderStatus.error => Center(
                child: Padding(
                  padding: AppSpacing.screen,
                  child: Text(
                    ArabicStrings.mushafLoadError,
                    style: AppTypography.body,
                  ),
                ),
              ),
              ReaderStatus.content => Column(
                children: [
                  _PageHeader(
                    pageNumber: page!.number,
                    surahName: _surahName(page.firstSurah),
                    juz: page.juz,
                    onBookmark: () =>
                        _addBookmark(context, page.number, null, null),
                  ),
                  if (state.isPortion)
                    Padding(
                      padding: AppSpacing.screenH,
                      child: Container(
                        width: double.infinity,
                        padding: AppSpacing.card,
                        decoration: ShapeDecoration(
                          color: colors.primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.mdBR,
                          ),
                        ),
                        child: Text(
                          ArabicStrings.portionName(
                            state.portionUnit!,
                            state.portionIndex!,
                          ),
                          style: AppTypography.body,
                        ),
                      ),
                    ),
                  if (state.isOffline)
                    const Padding(
                      padding: AppSpacing.screenH,
                      child: OfflineBanner(message: ArabicStrings.syncQueued),
                    ),
                  if (state.isCompleted && state.isPortion)
                    const Padding(
                      padding: AppSpacing.screenH,
                      child: StatusChip(status: ds.AssignmentStatus.completed),
                    ),
                  Expanded(
                    child: PageView.builder(
                      key: const ValueKey('mushaf-page-view'),
                      controller: _pages,
                      reverse: true,
                      itemCount: widget.repository.pageCount,
                      onPageChanged: (index) =>
                          context.read<ReaderCubit>().turnTo(index + 1),
                      itemBuilder: (context, index) {
                        final mushafPage = widget.repository.page(index + 1);
                        return ListView(
                          key: PageStorageKey<int>(mushafPage.number),
                          padding: AppSpacing.screenContent,
                          children: [
                            for (final ayah in mushafPage.ayahs)
                              GestureDetector(
                                key: ayah.ref == state.startAyah
                                    ? _startAyahKey
                                    : null,
                                onLongPress: () => _addBookmark(
                                  context,
                                  mushafPage.number,
                                  ayah.ref.surah,
                                  ayah.ref.ayah,
                                ),
                                child: Container(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                        vertical: AppSpacing.xxs,
                                        horizontal: AppSpacing.xs,
                                      ),
                                  decoration: BoxDecoration(
                                    color:
                                        ayah.ref == state.startAyah ||
                                            ayah.ref == state.endAyah
                                        ? colors.primaryContainer
                                        : null,
                                    borderRadius: AppRadius.smBR,
                                  ),
                                  child: Text(
                                    key: const ValueKey('mushaf-ayah'),
                                    ayah.text,
                                    textAlign: TextAlign.justify,
                                    textDirection: TextDirection.rtl,
                                    style: AppTypography.quranLabel.copyWith(
                                      fontFamily: 'KfgqpcHafs',
                                    ),
                                    textScaler: TextScaler.linear(
                                      state.quranTextScale *
                                          MediaQuery.textScalerOf(
                                            context,
                                          ).scale(1),
                                    ),
                                  ),
                                ),
                              ),
                            if (mushafPage.number ==
                                    widget.repository.pageCount &&
                                _dua != null)
                              TextButton(
                                onPressed: () => _showDua(context),
                                child: const Text(ArabicStrings.khatmDuaTitle),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            },
            bottomNavigationBar: state.canComplete
                ? SafeArea(
                    child: Padding(
                      padding: AppSpacing.screen,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.read<ReaderCubit>().completePortion(),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(ArabicStrings.completeReadingAction),
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  String _surahName(int index) {
    try {
      return widget.metadata.suraName(index);
    } on Object {
      return ArabicStrings.mushafTitle;
    }
  }

  Future<void> _addBookmark(
    BuildContext context,
    int page,
    int? surah,
    int? ayah,
  ) async {
    final note = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(ArabicStrings.addBookmarkAction),
        content: TextField(
          controller: note,
          decoration: const InputDecoration(
            hintText: ArabicStrings.bookmarkNoteHint,
          ),
          minLines: 1,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(ArabicStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(ArabicStrings.save),
          ),
        ],
      ),
    );
    if (save == true) {
      await widget.storage.addBookmark(
        ReaderBookmark(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          page: page,
          surah: surah,
          ayah: ayah,
          note: note.text.isEmpty ? null : note.text,
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(ArabicStrings.bookmarkSaved)),
        );
      }
    }
    note.dispose();
  }

  void _showDua(BuildContext context) {
    if (_dua == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: AppSpacing.screenContent,
          child: SingleChildScrollView(
            child: Text(_dua!, style: AppTypography.bodyLarge),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.pageNumber,
    required this.surahName,
    required this.juz,
    required this.onBookmark,
  });

  final int pageNumber;
  final String surahName;
  final int juz;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.screen,
    child: Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              Text(surahName, style: AppTypography.quranLabel),
              Text(
                '${ArabicStrings.juzLabel} ${ArabicNumerals.format(juz)} · ${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(pageNumber)}',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: ArabicStrings.addBookmarkAction,
          onPressed: onBookmark,
          icon: const Icon(Icons.bookmark_add_outlined),
        ),
      ],
    ),
  );
}
