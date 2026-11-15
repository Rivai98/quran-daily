import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../data/entities/entities.dart';
import '../../data/repositories/groups_repository.dart';

enum MembersStatus {
  initial,
  loading,
  success,
  empty,
  submitting,
  failure,
  offline,
}

class MembersState extends Equatable {
  const MembersState({
    this.status = MembersStatus.initial,
    this.members,
    this.failure,
  });
  final MembersStatus status;
  final SeatMap? members;
  final AppFailure? failure;
  @override
  List<Object?> get props => [status, members, failure];
}

class MembersCubit extends Cubit<MembersState> {
  MembersCubit(this._repository) : super(const MembersState());
  final GroupsRepository _repository;
  String? _groupId;

  Future<void> load(String groupId) async {
    _groupId = groupId;
    emit(const MembersState(status: MembersStatus.loading));
    final result = await _repository.getMembers(groupId);
    result.when(
      success: (value) async {
        if (value.members.isEmpty) {
          emit(MembersState(status: MembersStatus.empty, members: value));
          return;
        }
        final userIds = <String, String>{};
        final infoResult = await _repository.getGroupInfo(groupId);
        infoResult.when(
          success: (info) {
            for (final member in info.members) {
              userIds[member.membershipId] = member.userId;
            }
          },
          failure: (_) {},
        );
        final enriched = SeatMap(
          groupId: value.groupId,
          members: value.members
              .map((member) => SeatMember(
                    membershipId: member.membershipId,
                    displayName: member.displayName,
                    role: member.role,
                    seatNumber: member.seatNumber,
                    userId: userIds[member.membershipId],
                  ))
              .toList(),
          activeMemberCount: value.activeMemberCount,
          inviteCode: value.inviteCode,
        );
        emit(MembersState(
          status: enriched.members.isEmpty
              ? MembersStatus.empty
              : MembersStatus.success,
          members: enriched,
        ));
      },
      failure: (failure) => emit(
        MembersState(
          status: failure.kind == FailureKind.network
              ? MembersStatus.offline
              : MembersStatus.failure,
          failure: failure,
        ),
      ),
    );
  }

  Future<void> moveSeat(String membershipId, int seat) =>
      _mutate(() => _repository.moveMemberSeat(_groupId!, membershipId, seat));
  Future<void> setRole(String membershipId, GroupRole role) =>
      _mutate(() => _repository.setMemberRole(_groupId!, membershipId, role));
  Future<void> remove(String membershipId) =>
      _mutate(() => _repository.removeMember(_groupId!, membershipId));
  Future<void> leave() => _mutate(() => _repository.leaveGroup(_groupId!));
  Future<void> transfer(String membershipId) =>
      _mutate(() => _repository.transferOwnership(_groupId!, membershipId));

  Future<void> _mutate(Future<Result<void>> Function() action) async {
    if (_groupId == null || state.status == MembersStatus.submitting) return;
    emit(
      MembersState(status: MembersStatus.submitting, members: state.members),
    );
    final result = await action();
    result.when(
      success: (_) => load(_groupId!),
      failure: (failure) => emit(
        MembersState(
          status: failure.kind == FailureKind.network
              ? MembersStatus.offline
              : MembersStatus.failure,
          members: state.members,
          failure: failure,
        ),
      ),
    );
  }
}
