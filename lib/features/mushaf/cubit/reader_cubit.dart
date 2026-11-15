import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/quran/mushaf/mushaf_models.dart';
import '../../../core/quran/mushaf/mushaf_repository.dart';
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
    this.isOffline = false,
    this.error,
    this.quranTextScale = 1,
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
  final bool isOffline;
  final Object? error;
  final double quranTextScale;

  bool get isPortion => startAyah != null;
  bool get isStartPage => page?.number == startPage;
  bool get isEndPage => page?.number == endPage;
  bool get canComplete => isPortion && isEndPage && !isCompleted;

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
    bool? isOffline,
    Object? error,
    double? quranTextScale,
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
    isOffline: isOffline ?? this.isOffline,
    error: error,
    quranTextScale: quranTextScale ?? this.quranTextScale,
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
    isOffline,
    quranTextScale,
    error,
  ];
}

class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit({
    required MushafRepository repository,
    required ReaderStorage storage,
    SettingsRepository? settings,
    Future<bool> Function()? onComplete,
  }) : _repository = repository,
       _storage = storage,
       _settings = settings,
       _onComplete = onComplete,
       super(const ReaderState());

  final MushafRepository _repository;
  final ReaderStorage _storage;
  final SettingsRepository? _settings;
  final Future<bool> Function()? _onComplete;

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
      emit(
        ReaderState(
          status: ReaderStatus.content,
          page: page,
          quranTextScale: textScale,
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
        ),
      );
    } catch (error) {
      emit(ReaderState(status: ReaderStatus.error, error: error));
    }
  }

  Future<void> turnTo(int number) async {
    if (number < 1 || number > _repository.pageCount) return;
    try {
      emit(
        state.copyWith(
          page: _repository.page(number),
          status: ReaderStatus.content,
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
}
