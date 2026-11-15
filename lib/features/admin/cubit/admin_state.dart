import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../data/admin_repository.dart';

enum AdminStatus {
  initial,
  loading,
  content,
  empty,
  error,
  offline,
  actionRunning,
}

class AdminState extends Equatable {
  const AdminState({
    this.status = AdminStatus.initial,
    this.data,
    this.failure,
  });
  final AdminStatus status;
  final AdminJson? data;
  final AppFailure? failure;

  AdminState copyWith({
    AdminStatus? status,
    AdminJson? data,
    AppFailure? failure,
  }) => AdminState(
    status: status ?? this.status,
    data: data ?? this.data,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, data, failure];
}
