import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShellState extends Equatable {
  const ShellState(this.index, {this.mountedTabs = const {0}});
  final int index;
  final Set<int> mountedTabs;
  @override
  List<Object?> get props => [index, mountedTabs];
}

class ShellCubit extends Cubit<ShellState> {
  ShellCubit() : super(const ShellState(0));
  void select(int index) {
    if (index >= 0 && index < 4) {
      emit(
        ShellState(
          index,
          mountedTabs: Set.unmodifiable({...state.mountedTabs, index}),
        ),
      );
    }
  }
}

/// App-wide requests to the HomeShell from outside the widget tree, such as
/// a tapped reminder notification that must open الرئيسية.
abstract final class ShellNavigation {
  static final StreamController<int> _requests =
      StreamController<int>.broadcast();

  static Stream<int> get tabRequests => _requests.stream;

  static void showTab(int index) => _requests.add(index);

  static void showHome() => showTab(0);
}
