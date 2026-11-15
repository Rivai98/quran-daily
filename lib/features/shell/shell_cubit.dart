import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShellState extends Equatable {
  const ShellState(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class ShellCubit extends Cubit<ShellState> {
  ShellCubit() : super(const ShellState(0));
  void select(int index) {
    if (index >= 0 && index < 4) emit(ShellState(index));
  }
}
