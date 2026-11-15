import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/router.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/assignment_status.dart' as ds;
import '../../../core/design_system/widgets/islamic_ornament.dart';
import '../../../core/design_system/widgets/offline_banner.dart';
import '../../../core/design_system/widgets/status_chip.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_strings.dart';
import '../../../core/quran/mushaf/mushaf_models.dart';
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
  PageController? _pages;
  final GlobalKey _startAyahKey = GlobalKey();
  String? _dua;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
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
    _pages?.dispose();
    unawaited(WakelockPlus.disable());
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  void _toggleChrome() {
    final showChrome = !_chromeVisible;
    setState(() => _chromeVisible = showChrome);
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        showChrome ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
      ),
    );
  }

  int _hizbForPage(int pageNumber) {
    try {
      final hizbs = widget.repository.hizbIndex();
      var current = 1;
      for (final h in hizbs) {
        if (h.startPage <= pageNumber) {
          current = h.hizb;
        } else {
          break;
        }
      }
      return current;
    } catch (_) {
      return 1;
    }
  }

  String _surahName(int index) {
    try {
      return widget.metadata.suraName(index);
    } on Object {
      return ArabicStrings.mushafTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReaderCubit, ReaderState>(
      listenWhen: (previous, current) =>
          current.status == ReaderStatus.content &&
          previous.page?.number != current.page?.number,
      listener: (context, state) {
        final page = state.page?.number;
        if (page != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final pages = _pages;
            if (pages != null &&
                pages.hasClients &&
                pages.page?.round() != page - 1) {
              pages.jumpToPage(page - 1);
            }
          });
        }
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
            appBar: _chromeVisible
                ? AppBar(
                    title: const Text(ArabicStrings.mushafTitle),
                    actions: [
                      if (page != null)
                        IconButton(
                          tooltip: ArabicStrings.addBookmarkAction,
                          onPressed: () => _addBookmark(
                            context,
                            page.number,
                            page.firstSurah,
                            null,
                          ),
                          icon: const Icon(Icons.bookmark_add_outlined),
                        ),
                      IconButton(
                        tooltip: ArabicStrings.bookmarksTitle,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.mushafBookmarks,
                          arguments: widget.storage,
                        ),
                        icon: const Icon(Icons.bookmarks_outlined),
                      ),
                      IconButton(
                        tooltip: ArabicStrings.mushafIndexAction,
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.mushafIndex),
                        icon: const Icon(Icons.menu_book_outlined),
                      ),
                      IconButton(
                        tooltip: ArabicStrings.mushafLicensesTitle,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.mushafLicenses,
                        ),
                        icon: const Icon(Icons.info_outline),
                      ),
                    ],
                  )
                : null,
            body: SafeArea(
              top: !_chromeVisible,
              child: switch (state.status) {
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
                    if (_chromeVisible && state.isPortion)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xxs,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: AppRadius.mdBR,
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xxs,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_stories,
                                    size: 18,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    ArabicStrings.portionName(
                                      state.portionUnit!,
                                      state.portionIndex!,
                                    ),
                                    style: AppTypography.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colors.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                              if (state.startPage != null &&
                                  state.endPage != null &&
                                  page != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: AppSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surface.withValues(
                                      alpha: 0.8,
                                    ),
                                    borderRadius: AppRadius.smBR,
                                  ),
                                  child: Text(
                                    ArabicStrings.portionPageProgress(
                                      (page.number - state.startPage! + 1)
                                          .clamp(
                                            1,
                                            state.endPage! -
                                                state.startPage! +
                                                1,
                                          ),
                                      state.endPage! - state.startPage! + 1,
                                    ),
                                    style: AppTypography.caption.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (_chromeVisible && state.isOffline)
                      const Padding(
                        padding: AppSpacing.screenH,
                        child: OfflineBanner(message: ArabicStrings.syncQueued),
                      ),
                    if (_chromeVisible && state.isCompleted && state.isPortion)
                      const Padding(
                        padding: AppSpacing.screenH,
                        child: StatusChip(
                          status: ds.AssignmentStatus.completed,
                        ),
                      ),
                    Expanded(
                      child: GestureDetector(
                        key: const ValueKey('reader-page-tap-area'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleChrome,
                        child: PageView.builder(
                          key: const ValueKey('mushaf-page-view'),
                          controller: _pages ??= PageController(
                            initialPage: page!.number - 1,
                          ),
                          reverse: true,
                          itemCount: widget.repository.pageCount,
                          onPageChanged: (index) =>
                              context.read<ReaderCubit>().turnTo(index + 1),
                          itemBuilder: (context, index) {
                            final mushafPage = widget.repository.page(
                              index + 1,
                            );
                            final hizb = _hizbForPage(mushafPage.number);
                            final surahTitle = _surahName(
                              mushafPage.firstSurah,
                            );
                            return Column(
                              children: [
                                if (_chromeVisible)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.xxs,
                                    ),
                                    child: Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: AppSpacing.xs,
                                      runSpacing: AppSpacing.xxs,
                                      children: [
                                        Text(
                                          surahTitle,
                                          style: AppTypography.quranLabel
                                              .copyWith(color: colors.primary),
                                        ),
                                        Text(
                                          '${ArabicStrings.juzLabel} ${ArabicNumerals.format(mushafPage.juz)} · ${ArabicStrings.portionUnitHizb} ${ArabicNumerals.format(hizb)}',
                                          style: AppTypography.caption.copyWith(
                                            color: colors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Divider(color: colors.border, height: 1),
                                Expanded(
                                  child: ListView(
                                    key: PageStorageKey<int>(mushafPage.number),
                                    padding: AppSpacing.screenContent,
                                    children: [
                                      for (final ayah in mushafPage.ayahs) ...[
                                        if (ayah.ref.ayah == 1)
                                          _SurahTitleBand(
                                            surahName: _surahName(
                                              ayah.ref.surah,
                                            ),
                                          ),
                                        _AyahRow(
                                          key: ayah.ref == state.startAyah
                                              ? _startAyahKey
                                              : null,
                                          ayah: ayah,
                                          isStart: ayah.ref == state.startAyah,
                                          isEnd: ayah.ref == state.endAyah,
                                          textScale: state.quranTextScale,
                                          onLongPress: () => _addBookmark(
                                            context,
                                            mushafPage.number,
                                            ayah.ref.surah,
                                            ayah.ref.ayah,
                                          ),
                                        ),
                                      ],
                                      if (mushafPage.number == state.endPage &&
                                          state.isPortion) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        if (state.isCompleted)
                                          const Center(
                                            child: StatusChip(
                                              status:
                                                  ds.AssignmentStatus.completed,
                                            ),
                                          )
                                        else if (state.canComplete)
                                          Center(
                                            child: OutlinedButton.icon(
                                              onPressed: () => context
                                                  .read<ReaderCubit>()
                                                  .completePortion(),
                                              icon: const Icon(
                                                Icons.check_circle,
                                              ),
                                              label: const Text(
                                                ArabicStrings
                                                    .completeReadingAction,
                                              ),
                                            ),
                                          ),
                                      ],
                                      if (mushafPage.number ==
                                              widget.repository.pageCount &&
                                          _dua != null)
                                        TextButton(
                                          onPressed: () => _showDua(context),
                                          child: const Text(
                                            ArabicStrings.khatmDuaTitle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Divider(color: colors.border, height: 1),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xxs,
                                  ),
                                  child: Center(
                                    child: Text(
                                      ArabicNumerals.format(mushafPage.number),
                                      style: AppTypography.caption.copyWith(
                                        color: colors.inkMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              },
            ),
            bottomNavigationBar:
                state.canComplete && page?.number == state.endPage
                ? SafeArea(
                    child: Padding(
                      padding: AppSpacing.screen,
                      child: FilledButton.icon(
                        key: const ValueKey('complete-reading-button'),
                        onPressed: () =>
                            context.read<ReaderCubit>().completePortion(),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(ArabicStrings.completeReadingAction),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.mdBR,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
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
          maxLength: 200,
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
          id: ReaderBookmark.newId(),
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

class _SurahTitleBand extends StatelessWidget {
  const _SurahTitleBand({required this.surahName});

  final String surahName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      height: 52,
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: AppRadius.mdBR,
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: AppRadius.mdBR,
              child: CustomPaint(
                painter: GirihPainter(colors.accent.withValues(alpha: 0.08)),
              ),
            ),
          ),
          PositionedDirectional(
            start: AppSpacing.md,
            child: Icon(Icons.star, size: 12, color: colors.accent),
          ),
          PositionedDirectional(
            end: AppSpacing.md,
            child: Icon(Icons.star, size: 12, color: colors.accent),
          ),
          Text(
            '${ArabicStrings.surahWord} $surahName',
            style: AppTypography.quranLabel.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahRow extends StatelessWidget {
  const _AyahRow({
    super.key,
    required this.ayah,
    required this.isStart,
    required this.isEnd,
    required this.textScale,
    required this.onLongPress,
  });

  final MushafAyah ayah;
  final bool isStart;
  final bool isEnd;
  final double textScale;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isHighlighted = isStart || isEnd;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isHighlighted
              ? colors.primaryContainer.withValues(alpha: 0.5)
              : null,
          borderRadius: AppRadius.smBR,
          border: isHighlighted
              ? BorderDirectional(
                  start: BorderSide(color: colors.primary, width: 3.5),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isStart)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: AppRadius.smBR,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow,
                            size: 12,
                            color: colors.onPrimary,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            'بداية الورد',
                            style: AppTypography.caption.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              key: const ValueKey('mushaf-ayah'),
              ayah.text,
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              style: AppTypography.quranLabel.copyWith(
                fontFamily: 'KfgqpcHafs',
              ),
              textScaler: TextScaler.linear(
                textScale * MediaQuery.textScalerOf(context).scale(1),
              ),
            ),
            if (isEnd)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: AppRadius.smBR,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag, size: 12, color: colors.onPrimary),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            'نهاية الورد',
                            style: AppTypography.caption.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
