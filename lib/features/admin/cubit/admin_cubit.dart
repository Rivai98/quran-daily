import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../data/admin_repository.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  AdminCubit(this._repository) : super(const AdminState());
  final AdminRepository _repository;

  Future<void> overview() => _load(_repository.overview());
  Future<void> groups({String? query, String? status}) =>
      _load(_repository.groups(query: query, status: status));
  Future<void> groupDetail(String id) => _load(_repository.groupDetail(id));
  Future<void> users({String? query, String? status}) =>
      _load(_repository.users(query: query, status: status));
  Future<void> userDetail(String id) => _load(_repository.userDetail(id));
  Future<void> audit({String? action}) =>
      _load(_repository.audit(action: action));

  Future<void> _load(Future<Result<AdminJson>> future) async {
    emit(state.copyWith(status: AdminStatus.loading, failure: null));
    final result = await future;
    if (result.isSuccess) {
      final data = result.valueOrNull!;
      final items = data['items'];
      emit(
        state.copyWith(
          status: items is List && items.isEmpty
              ? AdminStatus.empty
              : AdminStatus.content,
          data: data,
        ),
      );
      return;
    }
    final failure = result.failureOrNull!;
    emit(
      state.copyWith(
        status: failure.kind == FailureKind.network
            ? AdminStatus.offline
            : AdminStatus.error,
        failure: failure,
      ),
    );
  }

  Future<bool> groupAction(
    String action,
    String id, {
    String? confirmName,
    String? membershipId,
  }) async {
    emit(state.copyWith(status: AdminStatus.actionRunning));
    final result = await _repository.groupAction(
      action,
      id,
      confirmName: confirmName,
      membershipId: membershipId,
    );
    if (result.isFailure) {
      final failure = result.failureOrNull!;
      emit(
        state.copyWith(
          status: failure.kind == FailureKind.network
              ? AdminStatus.offline
              : AdminStatus.error,
          failure: failure,
        ),
      );
      return false;
    }
    return true;
  }

  Future<bool> userAction(String action, String id) async {
    emit(state.copyWith(status: AdminStatus.actionRunning));
    final result = await _repository.userAction(action, id);
    if (result.isFailure) {
      final failure = result.failureOrNull!;
      emit(
        state.copyWith(
          status: failure.kind == FailureKind.network
              ? AdminStatus.offline
              : AdminStatus.error,
          failure: failure,
        ),
      );
      return false;
    }
    return true;
  }

  Future<bool> resetPassword(String id, String password) async {
    emit(state.copyWith(status: AdminStatus.actionRunning));
    final result = await _repository.resetPassword(id, password);
    if (result.isFailure) {
      final failure = result.failureOrNull!;
      emit(
        state.copyWith(
          status: failure.kind == FailureKind.network
              ? AdminStatus.offline
              : AdminStatus.error,
          failure: failure,
        ),
      );
      return false;
    }
    return true;
  }

  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AdminStatus.actionRunning));
    final result = await _repository.createUser(
      name: name,
      email: email,
      password: password,
    );
    if (result.isFailure) {
      final failure = result.failureOrNull!;
      emit(
        state.copyWith(
          status: failure.kind == FailureKind.network
              ? AdminStatus.offline
              : AdminStatus.error,
          failure: failure,
        ),
      );
      return false;
    }
    return true;
  }
}
