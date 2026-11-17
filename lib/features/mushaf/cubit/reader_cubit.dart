import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/quran/mushaf/mushaf_models.dart';
import '../../../core/quran/mushaf/mushaf_repository.dart';
import '../../../core/quran/mushaf/qpc_v2_repository.dart';
import '../../../core/quran/portion_unit.dart';
import '../../../core/settings/settings_repository.dart';
import '../data/reader_storage.dart';

enum ReaderStatus { loading, content, error }

class ReaderState extends Equatable {
  const ReaderState({
    this.status = ReaderStatus.loading,
    this.page,
    this.startAyah,
    this.endAyah,
    this.startPage,
    this.endPage,
    this.assignmentId,
    this.portionUnit,
    this.portionIndex,
    this.isCompleted = false,
    this.isCompletionPage = false,
    this.isOffline = false,
    this.error,
    this.quranTextScale = 1,
    this.qpcLines = const [],
    this.qpcFontFamily,
    this.isFontFallback = false,
  });

  final ReaderStatus status;
  final MushafPage? page;
  final AyahRef? startAyah;
  final AyahRef? endAyah;
  final int? startPage;
  final int? endPage;
  final String? assignmentId;
  final PortionUnit? portionUnit;
  final int? portionIndex;
  final bool isCompleted;
  final bool isCompletionPage;
  final bool isOffline;
  final Object? error;
  final double quranTextScale;
  final List<QpcLine> qpcLines;
  final String? qpcFontFamily;
  final bool isFontFallback;

  bool get isPortion => startAyah != null;
  bool get isStartPage => page?.number == startPage;
  bool get isEndPage => page?.number == endPage;
  int get portionPageCount => isPortion && startPage != null && endPage != null
      ? endPage! - startPage! + 1
      : 0;
  bool get canComplete => isPortion && isCompletionPage && !isCompleted;

  ReaderState copyWith({
    ReaderStatus? status,
    MushafPage? page,
    AyahRef? startAyah,
    AyahRef? endAyah,
    int? startPage,
    int? endPage,
    String? assignmentId,
    PortionUnit? portionUnit,
    int? portionIndex,
    bool? isCompleted,
    bool? isCompletionPage,
    bool? isOffline,
    Object? error,
    double? quranTextScale,
    List<QpcLine>? qpcLines,
    String? qpcFontFamily,
    bool? isFontFallback,
  }) => ReaderState(
    status: status ?? this.status,
    page: page ?? this.page,
    startAyah: startAyah ?? this.startAyah,
    endAyah: endAyah ?? this.endAyah,
    startPage: startPage ?? this.startPage,
    endPage: endPage ?? this.endPage,
    assignmentId: assignmentId ?? this.assignmentId,
    portionUnit: portionUnit ?? this.portionUnit,
    portionIndex: portionIndex ?? this.portionIndex,
    isCompleted: isCompleted ?? this.isCompleted,
    isCompletionPage: isCompletionPage ?? this.isCompletionPage,
    isOffline: isOffline ?? this.isOffline,
    error: error,
    quranTextScale: quranTextScale ?? this.quranTextScale,
    qpcLines: qpcLines ?? this.qpcLines,
    qpcFontFamily: qpcFontFamily ?? this.qpcFontFamily,
    isFontFallback: isFontFallback ?? this.isFontFallback,
  );

  @override
  List<Object?> get props => [
    status,
    portionUnit,
    portionIndex,
    page,
    startAyah,
    endAyah,
    startPage,
    endPage,
    assignmentId,
    isCompleted,
    isCompletionPage,
    isOffline,
    quranTextScale,
    error,
    qpcLines,
    qpcFontFamily,
    isFontFallback,
  ];
}

class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit({
    required this._repository,
    required this._storage,
    this._settings,
    this._onComplete,
    this._qpcLayout,
    this._qpcFonts,
  }) : super(const ReaderState());

  final MushafRepository _repository;
  final ReaderStorage _storage;
  final SettingsRepository? _settings;
  final Future<bool> Function()? _onComplete;
  final QpcV2Repository? _qpcLayout;
  final QpcFontManager? _qpcFonts;
  int _readingDirection = 1;
  int? _queuedPrefetch;
  bool _prefetchRunning = false;

  void pageTurnStarted() {
    _queuedPrefetch = null;
    _qpcFonts?.cancelPrefetch();
  }

  /// Called only after scroll-end, a painted frame and the scheduler's idle gate.
  /// Speculative font errors never change the visible reader state.
  Future<void> prefetchSettledPage(int page) async {
    final fonts = _qpcFonts;
    if (isClosed ||
        fonts == null ||
        state.page?.number != page ||
        state.isCompletionPage) {
      return;
    }
    final target = page + _readingDirection;
    final minimum = state.startPage ?? 1;
    final maximum = state.endPage ?? _repository.pageCount;
    if (target < minimum || target > maximum) return;
    _queuedPrefetch = target;
    if (_prefetchRunning) return;
    await _drainPrefetch(fonts);
  }

  Future<void> _drainPrefetch(QpcFontManager fonts) async {
    _prefetchRunning = true;
    try {
      while (!isClosed && _queuedPrefetch != null) {
        final next = _queuedPrefetch!;
        _queuedPrefetch = null;
        try {
          await fonts.prefetch(next);
        } on Object {
          // Visible-page loading retries normally if preparation was unavailable.
        }
      }
    } finally {
      _prefetchRunning = false;
    }
  }

  @override
  Future<void> close() {
    pageTurnStarted();
    return super.close();
  }

  Future<void> openLastPosition() async {
    int? saved;
    try {
      saved = await _storage.lastPage();
    } on Object {
      saved = null;
    }
    await openPage(saved ?? 1);
  }

  Future<void> openPage(int number) async {
    pageTurnStarted();
    _readingDirection = 1;
    emit(const ReaderState(status: ReaderStatus.loading));
    try {
      await _repository.load();
      final textScale = await _loadTextScale();
      final page = _repository.page(number);
      final exact = await _loadExactPage(number);
      emit(
        ReaderState(
          status: ReaderStatus.content,
          page: page,
          quranTextScale: textScale,
          qpcLines: exact.$1,
          qpcFontFamily: exact.$2,
          isFontFallback: exact.$3,
        ),
      );
      try {
        await _storage.savePage(number);
      } on Object {
        // Reading remains available if the local position cache is unavailable.
      }
    } catch (error) {
      emit(ReaderState(status: ReaderStatus.error, error: error));
    }
  }

  Future<void> openPortion(
    PortionUnit unit,
    int index, {
    required String assignmentId,
    bool alreadyCompleted = false,
  }) async {
    pageTurnStarted();
    _readingDirection = 1;
    emit(const ReaderState(status: ReaderStatus.loading));
    try {
      await _repository.load();
      final textScale = await _loadTextScale();
      final range = _repository.portionRange(unit, index);
      final exact = await _loadExactPage(range.startPage);
      emit(
        ReaderState(
          status: ReaderStatus.content,
          page: _repository.page(range.startPage),
          startAyah: range.start,
          endAyah: range.end,
          startPage: range.startPage,
          endPage: range.endPage,
          assignmentId: assignmentId,
          portionUnit: unit,
          portionIndex: index,
          isCompleted: alreadyCompleted,
          quranTextScale: textScale,
          qpcLines: exact.$1,
          qpcFontFamily: exact.$2,
          isFontFallback: exact.$3,
        ),
      );
    } catch (error) {
      emit(ReaderState(status: ReaderStatus.error, error: error));
    }
  }

  Future<void> turnTo(int number) async {
    final minimum = state.isPortion ? state.startPage! : 1;
    final maximum = state.isPortion ? state.endPage! : _repository.pageCount;
    if (number < minimum || number > maximum) return;
    final previous = state.page?.number;
    if (previous != null && number != previous) {
      _readingDirection = number > previous ? 1 : -1;
    }
    pageTurnStarted();
    try {
      emit(
        state.copyWith(
          page: _repository.page(number),
          status: ReaderStatus.content,
          isCompletionPage: false,
        ),
      );
      if (!state.isPortion) {
        try {
          await _storage.savePage(number);
        } on Object {
          // A failed position write must not interrupt reading.
        }
      }
    } catch (error) {
      emit(state.copyWith(status: ReaderStatus.error, error: error));
    }
  }

  void showCompletionPage() {
    if (!state.isPortion || state.isCompletionPage) return;
    pageTurnStarted();
    emit(
      state.copyWith(
        page: _repository.page(state.endPage!),
        isCompletionPage: true,
      ),
    );
  }

  Future<void> completePortion() async {
    final completion = _onComplete;
    if (!state.canComplete || completion == null) return;
    try {
      final offline = await completion();
      emit(state.copyWith(isCompleted: true, isOffline: offline));
    } catch (error) {
      emit(state.copyWith(status: ReaderStatus.error, error: error));
    }
  }

  Future<void> stepNext() async {
    if (state.isCompletionPage) return;
    final current = state.page?.number ?? state.startPage ?? 1;
    final max = state.isPortion ? state.endPage! : _repository.pageCount;
    if (state.isPortion && current >= max) {
      showCompletionPage();
    } else if (current < max) {
      await turnTo(current + 1);
    }
  }

  Future<void> stepPrevious() async {
    if (state.isCompletionPage) {
      final end = state.endPage ?? _repository.pageCount;
      await turnTo(end);
      return;
    }
    final current = state.page?.number ?? state.startPage ?? 1;
    final min = state.isPortion ? state.startPage! : 1;
    if (current > min) {
      await turnTo(current - 1);
    }
  }

  Future<double> _loadTextScale() async {
    final settings = _settings;
    if (settings == null) return 1;
    return (await settings.getQuranTextScale()).valueOrNull ?? 1;
  }

  Future<(List<QpcLine>, String?, bool)> _loadExactPage(int number) async {
    final layout = _qpcLayout;
    final fonts = _qpcFonts;
    if (layout == null || fonts == null) {
      return (const <QpcLine>[], null, false);
    }
    try {
      await layout.load();
      final lines = layout.linesForPage(number);
      final family = await fonts.ensureLoaded(number);
      return (lines, family, false);
    } on Object {
      return (const <QpcLine>[], null, true);
    }
  }
}
