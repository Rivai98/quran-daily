import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/quran/mushaf/qpc_v2_repository.dart';

enum MushafFontDownloadStatus { idle, downloading, complete, error }

class MushafFontDownloadState extends Equatable {
  const MushafFontDownloadState({
    this.status = MushafFontDownloadStatus.idle,
    this.completedPages = 0,
    this.totalBytes = 0,
    this.cachedBytes = 0,
    this.error,
  });

  final MushafFontDownloadStatus status;
  final int completedPages;
  final int totalBytes;
  final int cachedBytes;
  final Object? error;

  MushafFontDownloadState copyWith({
    MushafFontDownloadStatus? status,
    int? completedPages,
    int? totalBytes,
    int? cachedBytes,
    Object? error,
  }) => MushafFontDownloadState(
    status: status ?? this.status,
    completedPages: completedPages ?? this.completedPages,
    totalBytes: totalBytes ?? this.totalBytes,
    cachedBytes: cachedBytes ?? this.cachedBytes,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    completedPages,
    totalBytes,
    cachedBytes,
    error,
  ];
}

class MushafFontDownloadCubit extends Cubit<MushafFontDownloadState> {
  MushafFontDownloadCubit(this._manager)
    : super(const MushafFontDownloadState());

  final QpcFontManager _manager;

  Future<void> load() async {
    try {
      emit(
        state.copyWith(
          totalBytes: await _manager.totalBytes(),
          cachedBytes: await _manager.cachedBytes(),
        ),
      );
    } on Object catch (error) {
      emit(
        state.copyWith(status: MushafFontDownloadStatus.error, error: error),
      );
    }
  }

  Future<void> downloadAll() async {
    emit(
      state.copyWith(
        status: MushafFontDownloadStatus.downloading,
        completedPages: 0,
        error: null,
      ),
    );
    try {
      await _manager.downloadAll(
        onProgress: (completed, _) {
          if (!isClosed) emit(state.copyWith(completedPages: completed));
        },
      );
      if (_manager.isCancelled) {
        emit(
          state.copyWith(
            status: MushafFontDownloadStatus.idle,
            cachedBytes: await _manager.cachedBytes(),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: MushafFontDownloadStatus.complete,
            completedPages: 604,
            cachedBytes: await _manager.cachedBytes(),
          ),
        );
      }
    } on Object catch (error) {
      if (_manager.isCancelled) {
        emit(
          state.copyWith(
            status: MushafFontDownloadStatus.idle,
            cachedBytes: await _manager.cachedBytes(),
          ),
        );
      } else {
        emit(
          state.copyWith(status: MushafFontDownloadStatus.error, error: error),
        );
      }
    }
  }

  void cancel() {
    _manager.cancelDownload();
    emit(state.copyWith(status: MushafFontDownloadStatus.idle));
  }

  Future<void> deleteCache() async {
    await _manager.deleteCache();
    emit(
      state.copyWith(
        status: MushafFontDownloadStatus.idle,
        completedPages: 0,
        cachedBytes: 0,
      ),
    );
  }
}
