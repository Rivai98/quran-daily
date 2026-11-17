import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/entities/entities.dart';
import '../../data/repositories/groups_repository.dart';

enum GroupListStatus { initial, loading, success, empty, failure, offline }

class GroupListState extends Equatable {
  const GroupListState({
    this.status = GroupListStatus.initial,
    this.overview,
    this.failure,
    this.isRefreshing = false,
  });

  final GroupListStatus status;
  final MyGroupsOverview? overview;
  final AppFailure? failure;
  final bool isRefreshing;

  bool get isStale => overview?.isStale ?? false;

  GroupListState copyWith({
    GroupListStatus? status,
    bool? isRefreshing,
    MyGroupsOverview? overview,
    bool clearOverview = false,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return GroupListState(
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      overview: clearOverview ? null : (overview ?? this.overview),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, overview, failure, isRefreshing];
}

/// S1 group selection: my groups + pending rows + entry points.
class GroupListCubit extends Cubit<GroupListState> {
  GroupListCubit({required this._repository}) : super(const GroupListState());

  final GroupsRepository _repository;

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    emit(
      state.copyWith(
        status: state.overview == null ? GroupListStatus.loading : state.status,
        isRefreshing: state.overview != null,
        clearFailure: true,
      ),
    );
    final result = await _repository.getMyGroups();
    result.when(
      success: (MyGroupsOverview overview) => emit(
        state.copyWith(
          status: overview.groups.isEmpty && overview.pendingRequests.isEmpty
              ? GroupListStatus.empty
              : (overview.isStale
                    ? GroupListStatus.offline
                    : GroupListStatus.success),
          overview: overview,
          isRefreshing: false,
        ),
      ),
      failure: (AppFailure failure) => emit(
        state.copyWith(
          status: state.overview == null
              ? GroupListStatus.failure
              : state.status,
          failure: failure,
          isRefreshing: false,
        ),
      ),
    );
  }

  Future<void> cancelJoinRequest(String joinRequestId) async {
    emit(state.copyWith(clearFailure: true));
    final result = await _repository.cancelJoinRequest(joinRequestId);
    result.when(
      success: (_) {
        final overview = state.overview;
        if (overview == null) return;
        emit(
          state.copyWith(
            overview: MyGroupsOverview(
              groups: overview.groups,
              pendingRequests: overview.pendingRequests
                  .where((r) => r.joinRequestId != joinRequestId)
                  .toList(),
              isStale: overview.isStale,
              cachedAt: overview.cachedAt,
            ),
          ),
        );
      },
      failure: (AppFailure failure) => emit(state.copyWith(failure: failure)),
    );
  }
}
