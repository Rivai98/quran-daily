import 'dart:async';

import 'package:flutter/gestures.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/router.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/islamic_ornament.dart';
import '../../../core/design_system/widgets/offline_banner.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_strings.dart';
import '../../../core/quran/mushaf/mushaf_models.dart';
import '../../../core/quran/mushaf/mushaf_repository.dart';
import '../../../core/quran/mushaf/qpc_v2_repository.dart';
import '../../../core/quran/quran_metadata_repository.dart';
import '../cubit/reader_cubit.dart';
import '../data/reader_storage.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.repository,
    required this.storage,
    required this.metadata,
    this.qpcLayout,
  });

  final MushafRepository repository;
  final ReaderStorage storage;
  final QuranMetadataRepository metadata;
  final QpcV2Repository? qpcLayout;

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
          (current.status == ReaderStatus.content &&
              previous.page?.number != current.page?.number) ||
          (!previous.isCompleted && current.isCompleted),
      listener: (context, state) {
        final page = state.page?.number;
        if (page != null && !state.isCompletionPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final pages = _pages;
            final firstPage = state.startPage ?? 1;
            if (pages != null &&
                pages.hasClients &&
                pages.page?.round() != page - firstPage) {
              pages.jumpToPage(page - firstPage);
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
        if (state.isCompleted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: BlocBuilder<ReaderCubit, ReaderState>(
        builder: (context, state) {
          final colors = Theme.of(context).extension<AppColors>()!;
          final page = state.page;
          return Scaffold(
            appBar: _chromeVisible && page != null && !state.isCompletionPage
                ? AppBar(
                    titleSpacing: 0,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _surahName(page.firstSurah),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            state.isPortion
                                ? ArabicStrings.portionPageProgress(
                                    page.number - state.startPage! + 1,
                                    state.portionPageCount,
                                  )
                                : '${ArabicStrings.juzLabel} ${ArabicNumerals.format(page.juz)}، ${ArabicStrings.portionUnitHizb} ${ArabicNumerals.format(_hizbForPage(page.number))}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: AppTypography.caption.copyWith(
                              color: colors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      PopupMenuButton<String>(
                        tooltip: ArabicStrings.mushafTitle,
                        onSelected: (action) {
                          switch (action) {
                            case 'bookmark':
                              _addBookmark(
                                context,
                                page.number,
                                page.firstSurah,
                                null,
                              );
                            case 'bookmarks':
                              Navigator.pushNamed(
                                context,
                                AppRoutes.mushafBookmarks,
                                arguments: widget.storage,
                              );
                            case 'index':
                              Navigator.pushNamed(
                                context,
                                AppRoutes.mushafIndex,
                              );
                            case 'info':
                              Navigator.pushNamed(
                                context,
                                AppRoutes.mushafLicenses,
                              );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'bookmark',
                            child: _ReaderMenuItem(
                              icon: Icons.bookmark_add_rounded,
                              label: ArabicStrings.addBookmarkAction,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'bookmarks',
                            child: _ReaderMenuItem(
                              icon: Icons.bookmarks_rounded,
                              label: ArabicStrings.bookmarksTitle,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'index',
                            child: _ReaderMenuItem(
                              icon: Icons.menu_book_rounded,
                              label: ArabicStrings.mushafIndexAction,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'info',
                            child: _ReaderMenuItem(
                              icon: Icons.info_outline_rounded,
                              label: ArabicStrings.mushafLicensesTitle,
                            ),
                          ),
                        ],
                      ),
                    ],
                    bottom:
                        state.isPortion &&
                            state.startPage != null &&
                            state.endPage != null
                        ? PreferredSize(
                            preferredSize: const Size.fromHeight(
                              AppSpacing.xxs,
                            ),
                            child: Padding(
                              padding: AppSpacing.screenH,
                              child: LinearProgressIndicator(
                                key: const ValueKey('reader-portion-progress'),
                                minHeight: AppSpacing.xxs / 2,
                                value:
                                    ((page.number - state.startPage! + 1) /
                                            (state.endPage! -
                                                state.startPage! +
                                                1))
                                        .clamp(0.0, 1.0),
                                backgroundColor: colors.surfaceMuted,
                                color: colors.primary,
                              ),
                            ),
                          )
                        : null,
                  )
                : null,
            body: SafeArea(
              top: !_chromeVisible,
              child: switch (state.status) {
                ReaderStatus.loading => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppSpacing.md),
                      Text(ArabicStrings.mushafPagePreparing),
                    ],
                  ),
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
                    if (_chromeVisible && state.isOffline)
                      const Padding(
                        padding: AppSpacing.screenH,
                        child: OfflineBanner(message: ArabicStrings.syncQueued),
                      ),
                    if (_chromeVisible && state.isFontFallback)
                      const Padding(
                        padding: AppSpacing.screenH,
                        child: OfflineBanner(
                          message: ArabicStrings.mushafFontFallback,
                        ),
                      ),
                    Expanded(
                      child: GestureDetector(
                        key: const ValueKey('reader-page-tap-area'),
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) {
                          final width = MediaQuery.sizeOf(context).width;
                          final dx = details.localPosition.dx;
                          // In RTL Arabic layout:
                          // - Left edge (dx < width * 0.22) steps forward to the next page.
                          // - Right edge (dx > width * 0.78) steps back to the previous page.
                          // - Middle area (width * 0.22 .. 0.78) toggles the reader chrome.
                          if (dx < width * 0.22) {
                            _stepNext();
                          } else if (dx > width * 0.78) {
                            _stepPrevious();
                          } else {
                            _toggleChrome();
                          }
                        },
                        child: PageView.builder(
                          key: const ValueKey('mushaf-page-view'),
                          controller: _pages ??= PageController(
                            initialPage: page!.number - (state.startPage ?? 1),
                          ),
                          // The app is RTL, so a non-reversed horizontal PageView
                          // already places the next page on the left, like a
                          // printed Mushaf.
                          itemCount: state.isPortion
                              ? state.portionPageCount + 1
                              : widget.repository.pageCount,
                          onPageChanged: (index) {
                            final cubit = context.read<ReaderCubit>();
                            if (state.isPortion &&
                                index >= state.portionPageCount) {
                              cubit.showCompletionPage();
                            } else {
                              cubit.turnTo((state.startPage ?? 1) + index);
                            }
                          },
                          itemBuilder: (context, index) {
                            if (state.isPortion &&
                                index == state.portionPageCount) {
                              return _ReaderCompletionPage(
                                completed: state.isCompleted,
                              );
                            }
                            final mushafPage = widget.repository.page(
                              (state.startPage ?? 1) + index,
                            );
                            final qpcFonts = _qpcFonts();
                            if (widget.qpcLayout != null && qpcFonts != null) {
                              return Column(
                                children: [
                                  Expanded(
                                    child: _QpcPageView(
                                      key: ValueKey<int>(mushafPage.number),
                                      pageNumber: mushafPage.number,
                                      layout: widget.qpcLayout!,
                                      fonts: qpcFonts,
                                      startAyah: state.startAyah,
                                      endAyah: state.endAyah,
                                      onLongPress: (word) => _addBookmark(
                                        context,
                                        mushafPage.number,
                                        word.surah,
                                        word.ayah,
                                      ),
                                      surahName: (surah) => _surahName(surah),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.xxs,
                                    ),
                                    child: Text(
                                      ArabicNumerals.format(mushafPage.number),
                                      style: AppTypography.caption.copyWith(
                                        color: colors.inkMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                Expanded(
                                  child: ListView(
                                    key: PageStorageKey<int>(mushafPage.number),
                                    padding: const EdgeInsetsDirectional.only(
                                      start: AppSpacing.md,
                                      top: AppSpacing.xs,
                                      end: AppSpacing.md,
                                      bottom: AppSpacing.xs,
                                    ),
                                    children: [
                                      for (final segment in _groupAyahs(
                                        mushafPage.ayahs,
                                      )) ...[
                                        if (segment.first.ref.ayah == 1)
                                          _SurahTitleBand(
                                            surahName: _surahName(
                                              segment.first.ref.surah,
                                            ),
                                          ),
                                        _AyahFlowParagraph(
                                          ayahs: segment,
                                          startAyah: state.startAyah,
                                          endAyah: state.endAyah,
                                          textScale: state.quranTextScale,
                                          onLongPress: (ayah) => _addBookmark(
                                            context,
                                            mushafPage.number,
                                            ayah.ref.surah,
                                            ayah.ref.ayah,
                                          ),
                                          anchorKey:
                                              segment.any(
                                                (ayah) =>
                                                    ayah.ref == state.startAyah,
                                              )
                                              ? _startAyahKey
                                              : null,
                                        ),
                                      ],
                                      if (!state.isPortion &&
                                          mushafPage.number ==
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
            bottomNavigationBar: state.canComplete
                ? SafeArea(
                    child: Padding(
                      padding: AppSpacing.screen,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.icon(
                            key: const ValueKey('complete-reading-button'),
                            onPressed: () =>
                                context.read<ReaderCubit>().completePortion(),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text(
                              ArabicStrings.completeReadingAction,
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mdBR,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          OutlinedButton(
                            key: const ValueKey('reader-completion-back'),
                            onPressed: () {
                              final pages = _pages;
                              if (pages?.hasClients == true) {
                                pages!.previousPage(
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mdBR,
                              ),
                            ),
                            child: const Text(ArabicStrings.readerBackAction),
                          ),
                        ],
                      ),
                    ),
                  )
                : state.isCompletionPage && state.isCompleted
                ? SafeArea(
                    child: Padding(
                      padding: AppSpacing.screen,
                      child: OutlinedButton(
                        key: const ValueKey('reader-completion-back'),
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.mdBR,
                          ),
                        ),
                        child: const Text(ArabicStrings.readerBackAction),
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  void _stepNext() {
    final pages = _pages;
    if (pages?.hasClients == true) {
      pages!.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _stepPrevious() {
    final pages = _pages;
    if (pages?.hasClients == true) {
      pages!.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
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
      height: AppSpacing.xxl,
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
            child: Icon(Icons.star_rounded, size: 18, color: colors.accent),
          ),
          PositionedDirectional(
            end: AppSpacing.md,
            child: Icon(Icons.star_rounded, size: 18, color: colors.accent),
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

class _ReaderCompletionPage extends StatelessWidget {
  const _ReaderCompletionPage({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SingleChildScrollView(
      key: const ValueKey('reader-completion-page'),
      padding: AppSpacing.screenH,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          IslamicOrnamentBand(
            refined: true,
            child: Center(
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: AppSpacing.xxl,
                color: colors.primary,
                semanticLabel: ArabicStrings.completeReadingAction,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            completed
                ? ArabicStrings.readerCompletionRecorded
                : ArabicStrings.readerCompletionTitle,
            textAlign: TextAlign.center,
            style: AppTypography.headline.copyWith(color: colors.ink),
          ),
          if (!completed) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              ArabicStrings.readerCompletionMessage,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: colors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReaderMenuItem extends StatelessWidget {
  const _ReaderMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.inkMuted),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, style: AppTypography.label)),
      ],
    );
  }
}

QpcFontManager? _qpcFonts() => serviceLocator.isRegistered<QpcFontManager>()
    ? serviceLocator<QpcFontManager>()
    : null;

class _QpcPageData {
  const _QpcPageData(this.lines, this.family, this.basmalaFamily, this.basmala);
  final List<QpcLine> lines;
  final String family;
  final String? basmalaFamily;
  final List<QpcWord> basmala;
}

/// One printed Madinah Mushaf page: the 15 lines of the KFGQPC V2 layout, each
/// line drawn word by word in that page's own verified font and justified to
/// the full width, like the printed page.
class _QpcPageView extends StatefulWidget {
  const _QpcPageView({
    super.key,
    required this.pageNumber,
    required this.layout,
    required this.fonts,
    required this.startAyah,
    required this.endAyah,
    required this.onLongPress,
    required this.surahName,
  });

  final int pageNumber;
  final QpcV2Repository layout;
  final QpcFontManager fonts;
  final AyahRef? startAyah;
  final AyahRef? endAyah;
  final ValueChanged<QpcWord> onLongPress;
  final String Function(int) surahName;

  @override
  State<_QpcPageView> createState() => _QpcPageViewState();
}

class _QpcPageViewState extends State<_QpcPageView>
    with AutomaticKeepAliveClientMixin {
  late Future<_QpcPageData> _data;
  _QpcPageData? _syncData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _syncData = _tryLoadSync();
    _data = _syncData != null ? Future.value(_syncData) : _load();
  }

  _QpcPageData? _tryLoadSync() {
    if (!widget.layout.isLoaded || !widget.fonts.isLoaded(widget.pageNumber)) {
      return null;
    }
    final lines = widget.layout.linesForPage(widget.pageNumber);
    final hasBasmallah =
        lines.any((line) => line.lineType == QpcLineType.basmallah);
    if (hasBasmallah && !widget.fonts.isLoaded(1)) {
      return null;
    }
    final family = 'qpcv2_p${widget.pageNumber}';
    final basmalaFamily = hasBasmallah ? 'qpcv2_p1' : null;
    final basmala =
        hasBasmallah ? widget.layout.basmallahWords : const <QpcWord>[];
    return _QpcPageData(lines, family, basmalaFamily, basmala);
  }

  Future<_QpcPageData> _load() async {
    await widget.layout.load();
    final lines = widget.layout.linesForPage(widget.pageNumber);
    final family = await widget.fonts.ensureLoaded(widget.pageNumber);
    String? basmalaFamily;
    var basmala = const <QpcWord>[];
    if (lines.any((line) => line.lineType == QpcLineType.basmallah)) {
      // The basmala glyphs are the words of 1:1, encoded for page 1's font.
      basmalaFamily = await widget.fonts.ensureLoaded(1);
      basmala = widget.layout.basmallahWords;
    }
    final result = _QpcPageData(lines, family, basmalaFamily, basmala);
    if (mounted) setState(() => _syncData = result);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).extension<AppColors>()!;
    if (_syncData != null) {
      return _QpcPageBody(
        data: _syncData!,
        startAyah: widget.startAyah,
        endAyah: widget.endAyah,
        onLongPress: widget.onLongPress,
        surahName: widget.surahName,
      );
    }
    return FutureBuilder<_QpcPageData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, color: colors.inkMuted),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'تعذّر تجهيز الصفحة. تحقّق من الاتصال لتنزيلها أول مرة.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: colors.inkMuted),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _data = _load()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'جارٍ تجهيز الصفحة',
                  style: AppTypography.caption.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          );
        }
        return _QpcPageBody(
          data: data,
          startAyah: widget.startAyah,
          endAyah: widget.endAyah,
          onLongPress: widget.onLongPress,
          surahName: widget.surahName,
        );
      },
    );
  }
}

class _QpcPageBody extends StatelessWidget {
  const _QpcPageBody({
    required this.data,
    required this.startAyah,
    required this.endAyah,
    required this.onLongPress,
    required this.surahName,
  });

  final _QpcPageData data;
  final AyahRef? startAyah;
  final AyahRef? endAyah;
  final ValueChanged<QpcWord> onLongPress;
  final String Function(int) surahName;

  static const _measureSize = 100.0;
  static final Map<String, double> _naturalWidthCache = {};

  double _naturalWidth(List<QpcWord> words, String family) {
    final painter = TextPainter(
      textDirection: TextDirection.rtl,
      maxLines: 1,
      text: TextSpan(
        text: words.map((w) => w.text).join(' '),
        style: AppTypography.mushafPage(fontFamily: family, size: _measureSize),
      ),
    )..layout();
    return painter.width;
  }

  bool _highlighted(QpcWord word) =>
      (startAyah?.surah == word.surah && startAyah?.ayah == word.ayah) ||
      (endAyah?.surah == word.surah && endAyah?.ayah == word.ayah);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontal = AppSpacing.sm;
        final width = constraints.maxWidth - 2 * horizontal;
        final lineHeight = constraints.maxHeight / 15;
        final maxNatural = _naturalWidthCache.putIfAbsent(data.family, () {
          var widest = 0.0;
          // Measure every ayah line, centered ones included (pages 1-2 are all
          // centered), so no line can ever exceed the screen width.
          for (final line in data.lines) {
            if (line.lineType == QpcLineType.ayah) {
              final w = _naturalWidth(line.words, data.family);
              if (w > widest) widest = w;
            }
          }
          return widest;
        });
        final allCentered = data.lines
            .where((l) => l.lineType == QpcLineType.ayah)
            .every((l) => l.isCentered);
        // Centered pages (Al-Fatiha, start of Al-Baqarah) use a narrower text
        // block in the printed Mushaf.
        final blockWidth = allCentered ? width * 0.82 : width;
        final byWidth = maxNatural <= 0
            ? lineHeight * 0.6
            : _measureSize * blockWidth / maxNatural;
        final fontSize = byWidth.clamp(8.0, lineHeight * 0.7).toDouble();
        final gap = fontSize * 0.25;

        Widget wordWidget(QpcWord word, String family) {
          final text = Text(
            word.text,
            textDirection: TextDirection.rtl,
            style: AppTypography.mushafPage(
              fontFamily: family,
              size: fontSize,
              color: colors.ink,
            ),
          );
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () => onLongPress(word),
            child: _highlighted(word)
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: AppRadius.smBR,
                    ),
                    child: text,
                  )
                : text,
          );
        }

        // Centered lines shrink to fit the width instead of overflowing.
        Widget centeredRow(List<Widget> children) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                children[i],
              ],
            ],
          ),
        );

        Widget lineWidget(QpcLine line) {
          switch (line.lineType) {
            case QpcLineType.surahName:
              return _SurahTitleBand(
                surahName: surahName(line.surahNumber ?? 1),
              );
            case QpcLineType.blank:
              return const SizedBox.shrink();
            case QpcLineType.basmallah:
              final family = data.basmalaFamily ?? data.family;
              return centeredRow([
                for (final word in data.basmala) wordWidget(word, family),
              ]);
            case QpcLineType.ayah:
              final children = [
                for (final word in line.words) wordWidget(word, data.family),
              ];
              if (line.isCentered) return centeredRow(children);
              return Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: children,
              );
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontal),
          child: Column(
            // Short centered pages (Al-Fatiha, start of Al-Baqarah) sit in the
            // middle of the page like the printed Mushaf.
            mainAxisAlignment: allCentered
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              for (final line in data.lines)
                if (!(allCentered && line.lineType == QpcLineType.blank))
                  SizedBox(
                    height: lineHeight,
                    width: width,
                    child: line.lineType == QpcLineType.surahName
                        // The ornamental band has a fixed natural height; scale it
                        // into the line slot so it is never clipped.
                        ? FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: width,
                              height: AppSpacing.xxl + 2 * AppSpacing.sm,
                              child: lineWidget(line),
                            ),
                          )
                        : Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: width,
                                child: lineWidget(line),
                              ),
                            ),
                          ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

List<List<MushafAyah>> _groupAyahs(List<MushafAyah> ayahs) {
  final segments = <List<MushafAyah>>[];
  for (final ayah in ayahs) {
    if (segments.isEmpty || segments.last.last.ref.surah != ayah.ref.surah) {
      segments.add(<MushafAyah>[ayah]);
    } else {
      segments.last.add(ayah);
    }
  }
  return segments;
}

class _AyahFlowParagraph extends StatefulWidget {
  const _AyahFlowParagraph({
    required this.ayahs,
    required this.startAyah,
    required this.endAyah,
    required this.textScale,
    required this.onLongPress,
    this.anchorKey,
  });

  final List<MushafAyah> ayahs;
  final AyahRef? startAyah;
  final AyahRef? endAyah;
  final double textScale;
  final ValueChanged<MushafAyah> onLongPress;
  final Key? anchorKey;

  @override
  State<_AyahFlowParagraph> createState() => _AyahFlowParagraphState();
}

class _AyahFlowParagraphState extends State<_AyahFlowParagraph> {
  final List<GestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final colors = Theme.of(context).extension<AppColors>()!;
    final quranStyle = AppTypography.quranLabel.copyWith(
      fontFamily: 'KfgqpcHafs',
      color: colors.ink,
    );
    final spans = <InlineSpan>[];
    for (final ayah in widget.ayahs) {
      final highlighted =
          ayah.ref == widget.startAyah || ayah.ref == widget.endAyah;
      final recognizer = LongPressGestureRecognizer()
        ..onLongPress = () => widget.onLongPress(ayah);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: ayah.text,
          recognizer: recognizer,
          style: quranStyle.copyWith(
            backgroundColor: highlighted
                ? colors.primaryContainer.withValues(alpha: 0.5)
                : null,
          ),
          children: [const TextSpan(text: ' ')],
        ),
      );
    }

    final paragraph = RichText(
      key: ValueKey('mushaf-surah-segment-${widget.ayahs.first.ref.surah}'),
      text: TextSpan(style: quranStyle, children: spans),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.linear(
        widget.textScale * MediaQuery.textScalerOf(context).scale(1),
      ),
    );
    return widget.anchorKey == null
        ? paragraph
        : KeyedSubtree(key: widget.anchorKey, child: paragraph);
  }
}
