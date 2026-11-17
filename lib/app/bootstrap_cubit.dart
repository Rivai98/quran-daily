import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum BootstrapStatus { loading, ready, failure }

class BootstrapState extends Equatable {
  const BootstrapState(this.status);
  final BootstrapStatus status;
  @override
  List<Object?> get props => [status];
}

class BootstrapCubit extends Cubit<BootstrapState> {
  BootstrapCubit(this._initialize)
    : super(const BootstrapState(BootstrapStatus.loading));

  final Future<void> Function() _initialize;
  Future<void>? _initializing;

  Future<void> initialize() {
    if (state.status == BootstrapStatus.ready) return Future.value();
    return _initializing ??= _start().whenComplete(() {
      _initializing = null;
    });
  }

  Future<void> _start() async {
    emit(const BootstrapState(BootstrapStatus.loading));
    try {
      await _initialize();
      if (!isClosed) emit(const BootstrapState(BootstrapStatus.ready));
    } catch (_) {
      if (!isClosed) emit(const BootstrapState(BootstrapStatus.failure));
    }
  }
}
