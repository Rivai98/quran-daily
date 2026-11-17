import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';

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
import '../../../core/design_system/widgets/offline_banner.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_strings.dart';
import '../../../core/quran/mushaf/mushaf_repository.dart';
import '../../../core/quran/mushaf/qpc_v2_repository.dart';
import '../../../core/quran/quran_metadata_repository.dart';
import '../cubit/reader_cubit.dart';
import '../data/reader_storage.dart';
import 'widgets/ayah_flow_paragraph.dart';
import 'widgets/qpc_page_view.dart';
import 'widgets/reader_completion_page.dart';
import 'widgets/snappy_mushaf_scroll_physics.dart';
import 'widgets/surah_title_band.dart';

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
  int? _settledPageIndex;
  int _prefetchGeneration = 0;
  late final ReaderCubit _reader;

  @override
  void initState() {
    super.initState();
    _reader = context.read<ReaderCubit>();
    unawaited(WakelockPlus.enable());
    _loadDua();
    widget.metadata.load().then((_) {
      if (mounted) setState(() {});
    });
    _schedulePrefetch(_reader.state.page?.number);
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
    _prefetchGeneration++;
    _reader.pageTurnStarted();
    _pages?.dispose();
    unawaited(WakelockPlus.disable());
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  bool _onPageScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.horizontal) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      _prefetchGeneration++;
      _reader.pageTurnStarted();
    } else if (notification is ScrollEndNotification) {
      _schedulePrefetch(_reader.state.page?.number);
    }
    return false;
  }

  void _schedulePrefetch(int? page) {
    if (page == null) return;
    final generation = ++_prefetchGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queueIdlePrefetch(page, generation);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _queueIdlePrefetch(int page, int generation) {
    if (!mounted || generation != _prefetchGeneration) return;
    // Wait on frames rather than polling idle tasks during route/scroll animations.
    if (SchedulerBinding.instance.transientCallbackCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _queueIdlePrefetch(page, generation);
      });
      return;
    }
    unawaited(
      SchedulerBinding.instance.scheduleTask<void>(
        () {
          if (!mounted ||
              generation != _prefetchGeneration ||
              _pages?.position.isScrollingNotifier.value == true) {
            return;
          }
          unawaited(_reader.prefetchSettledPage(page));
        },
        Priority.idle,
        debugLabel: 'mushaf-page-prefetch',
      ),
    );
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
        if (_pages == null) _schedulePrefetch(page);
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
                        child: NotificationListener<ScrollNotification>(
                          onNotification: _onPageScroll,
                          child: PageView.builder(
                            key: const ValueKey('mushaf-page-view'),
                            controller: _pages ??= PageController(
                              initialPage:
                                  page!.number - (state.startPage ?? 1),
                            ),
                            dragStartBehavior: DragStartBehavior.down,
                            physics: SnappyMushafScrollPhysics(
                              settledPageGetter: () =>
                                  (_settledPageIndex ??
                                          page?.number ??
                                          1 - (state.startPage ?? 1))
                                      .toDouble(),
                            ),
                            padEnds: false,
                            // The app is RTL, so a non-reversed horizontal PageView
                            // already places the next page on the left, like a
                            // printed Mushaf.
                            itemCount: state.isPortion
                                ? state.portionPageCount + 1
                                : widget.repository.pageCount,
                            onPageChanged: (index) {
                              _settledPageIndex = index;
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
                                return ReaderCompletionPage(
                                  completed: state.isCompleted,
                                );
                              }
                              final mushafPage = widget.repository.page(
                                (state.startPage ?? 1) + index,
                              );
                              final qpcFonts = _qpcFonts();
                              if (widget.qpcLayout != null &&
                                  qpcFonts != null) {
                                return Column(
                                  children: [
                                    Expanded(
                                      child: QpcPageView(
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
                                        ArabicNumerals.format(
                                          mushafPage.number,
                                        ),
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
                                      key: PageStorageKey<int>(
                                        mushafPage.number,
                                      ),
                                      padding: const EdgeInsetsDirectional.only(
                                        start: AppSpacing.md,
                                        top: AppSpacing.xs,
                                        end: AppSpacing.md,
                                        bottom: AppSpacing.xs,
                                      ),
                                      children: [
                                        for (final segment in groupAyahs(
                                          mushafPage.ayahs,
                                        )) ...[
                                          if (segment.first.ref.ayah == 1)
                                            SurahTitleBand(
                                              surahName: _surahName(
                                                segment.first.ref.surah,
                                              ),
                                            ),
                                          AyahFlowParagraph(
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
                                                      ayah.ref ==
                                                      state.startAyah,
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
                                        ArabicNumerals.format(
                                          mushafPage.number,
                                        ),
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
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _stepPrevious() {
    final pages = _pages;
    if (pages?.hasClients == true) {
      pages!.previousPage(
        duration: const Duration(milliseconds: 130),
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
