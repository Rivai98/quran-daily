import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/entities/entities.dart';
import '../../data/repositories/groups_repository.dart';

enum MemberProfileStatus {
  initial,
  loading,
  success,
  notAccessible,
  failure,
  offline,
}

class MemberProfileState extends Equatable {
  const MemberProfileState({
    this.status = MemberProfileStatus.initial,
    this.profile,
    this.failure,
  });

  final MemberProfileStatus status;
  final MemberGroupProfile? profile;
  final AppFailure? failure;

  @override
  List<Object?> get props => [status, profile, failure];
}

class MemberProfileCubit extends Cubit<MemberProfileState> {
  MemberProfileCubit(this._repository) : super(const MemberProfileState());

  final GroupsRepository _repository;
  String? _userId;
  String? _groupId;

  Future<void> load(String userId, String groupId) async {
    final previousProfile = _userId == userId && _groupId == groupId
        ? state.profile
        : null;
    _userId = userId;
    _groupId = groupId;
    emit(
      MemberProfileState(
        status: MemberProfileStatus.loading,
        profile: previousProfile?.userId == userId ? previousProfile : null,
      ),
    );
    final result = await _repository.getMemberProfile(userId, groupId);
    result.when(
      success: (profile) => emit(
        MemberProfileState(
          status: MemberProfileStatus.success,
          profile: profile,
        ),
      ),
      failure: (failure) {
        if (failure.kind == FailureKind.network ||
            failure.category == FailureCategory.network) {
          emit(
            MemberProfileState(
              status: MemberProfileStatus.offline,
              profile: previousProfile,
              failure: failure,
            ),
          );
        } else if (failure.kind == FailureKind.forbidden ||
            failure.kind == FailureKind.notFound ||
            failure.category == FailureCategory.permission ||
            failure.code == 'not_member' ||
            failure.code == 'group_not_found' ||
            failure.code == 'profile_not_found') {
          emit(
            MemberProfileState(
              status: MemberProfileStatus.notAccessible,
              failure: failure,
            ),
          );
        } else {
          emit(
            MemberProfileState(
              status: MemberProfileStatus.failure,
              profile: previousProfile,
              failure: failure,
            ),
          );
        }
      },
    );
  }

  Future<void> refresh() async {
    if (_userId != null && _groupId != null) {
      await load(_userId!, _groupId!);
    }
  }
}
