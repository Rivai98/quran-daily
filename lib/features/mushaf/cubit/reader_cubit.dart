import 'dart:async';

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
    required MushafRepository repository,
    required ReaderStorage storage,
    SettingsRepository? settings,
    Future<bool> Function()? onComplete,
    QpcV2Repository? qpcLayout,
    QpcFontManager? qpcFonts,
  }) : _repository = repository,
       _storage = storage,
       _settings = settings,
       _onComplete = onComplete,
       _qpcLayout = qpcLayout,
       _qpcFonts = qpcFonts,
       super(const ReaderState());

  final MushafRepository _repository;
  final ReaderStorage _storage;
  final SettingsRepository? _settings;
  final Future<bool> Function()? _onComplete;
  final QpcV2Repository? _qpcLayout;
  final QpcFontManager? _qpcFonts;

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
      final fonts = _qpcFonts;
      final layout = _qpcLayout;
      if (fonts != null && layout != null) {
        for (var page = range.startPage + 1; page <= range.endPage; page++) {
          unawaited(fonts.ensureLoaded(page).catchError((_) => ''));
        }
      }
    } catch (error) {
      emit(ReaderState(status: ReaderStatus.error, error: error));
    }
  }

  Future<void> turnTo(int number) async {
    final minimum = state.isPortion ? state.startPage! : 1;
    final maximum = state.isPortion ? state.endPage! : _repository.pageCount;
    if (number < minimum || number > maximum) return;
    try {
      emit(
        state.copyWith(
          page: _repository.page(number),
          status: ReaderStatus.content,
          isCompletionPage: false,
        ),
      );
      final exact = await _loadExactPage(number);
      if (exact.$1.isNotEmpty || exact.$3) {
        emit(
          state.copyWith(
            qpcLines: exact.$1,
            qpcFontFamily: exact.$2,
            isFontFallback: exact.$3,
          ),
        );
      }
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
