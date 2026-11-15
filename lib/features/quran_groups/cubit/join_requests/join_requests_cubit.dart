import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/repositories/groups_repository.dart';

enum JoinRequestsStatus {
  initial,
  loading,
  success,
  empty,
  submitting,
  failure,
  offline,
  groupFull,
  membershipLimit,
}

class JoinRequestsState extends Equatable {
  const JoinRequestsState({
    this.status = JoinRequestsStatus.initial,
    this.requests = const [],
    this.failure,
  });
  final JoinRequestsStatus status;
  final List<PublicJoinRequestInfo> requests;
  final AppFailure? failure;
  @override
  List<Object?> get props => [status, requests, failure];
}

class JoinRequestsCubit extends Cubit<JoinRequestsState> {
  JoinRequestsCubit(this._repository) : super(const JoinRequestsState());
  final GroupsRepository _repository;
  String? _groupId;

  Future<void> load(String groupId) async {
    _groupId = groupId;
    emit(const JoinRequestsState(status: JoinRequestsStatus.loading));
    final result = await _repository.listJoinRequests(groupId);
    result.when(
      success: (items) => emit(
        JoinRequestsState(
          status: items.isEmpty
              ? JoinRequestsStatus.empty
              : JoinRequestsStatus.success,
          requests: items,
        ),
      ),
      failure: (failure) => emit(
        JoinRequestsState(
          status: failure.kind == FailureKind.network
              ? JoinRequestsStatus.offline
              : JoinRequestsStatus.failure,
          failure: failure,
        ),
      ),
    );
  }

  Future<void> review(String requestId, {required bool approve}) async {
    if (_groupId == null || state.status == JoinRequestsStatus.submitting) {
      return;
    }
    emit(
      JoinRequestsState(
        status: JoinRequestsStatus.submitting,
        requests: state.requests,
      ),
    );
    final result = await _repository.reviewJoinRequest(requestId, approve);
    result.when(
      success: (_) => load(_groupId!),
      failure: (failure) => emit(
        JoinRequestsState(
          status: failure.code == 'membership_limit'
              ? JoinRequestsStatus.membershipLimit
              : failure.code == 'group_full'
              ? JoinRequestsStatus.groupFull
              : failure.kind == FailureKind.network
              ? JoinRequestsStatus.offline
              : JoinRequestsStatus.failure,
          requests: state.requests,
          failure: failure,
        ),
      ),
    );
  }
}
