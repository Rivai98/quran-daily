import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../data/entities/entities.dart';
import '../../data/models/models.dart';
import '../../data/repositories/groups_repository.dart';

enum JoinStatus { initial, loading, success, pending, joined, failure }

class JoinState extends Equatable {
  const JoinState({
    this.status = JoinStatus.initial,
    this.inviteCode = '',
    this.preview,
    this.outcome,
    this.failure,
  });

  final JoinStatus status;
  final String inviteCode;
  final PublicGroupProfile? preview;
  final JoinOutcome? outcome;
  final AppFailure? failure;

  @override
  List<Object?> get props => [status, inviteCode, preview, outcome, failure];
}

/// S3 invite join and one-tap matching view model.
class JoinCubit extends Cubit<JoinState> {
  JoinCubit({required this._repository}) : super(const JoinState());

  final GroupsRepository _repository;

  Future<void> previewInvite(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (!RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{8}$').hasMatch(code)) {
      emit(
        JoinState(
          status: JoinStatus.failure,
          inviteCode: code,
          failure: const ValidationFailure(
            message: 'invalid invite code',
            code: 'validation_failed',
          ),
        ),
      );
      return;
    }
    emit(JoinState(status: JoinStatus.loading, inviteCode: code));
    final result = await _repository.getInvitePreview(code);
    if (isClosed) return;
    result.when(
      success: (profile) => emit(
        JoinState(
          status: JoinStatus.success,
          inviteCode: code,
          preview: profile,
        ),
      ),
      failure: (failure) => emit(
        JoinState(
          status: JoinStatus.failure,
          inviteCode: code,
          failure: failure,
        ),
      ),
    );
  }

  Future<void> joinInvite() async {
    if (state.preview == null || state.status == JoinStatus.loading) return;
    emit(
      JoinState(
        status: JoinStatus.loading,
        inviteCode: state.inviteCode,
        preview: state.preview,
      ),
    );
    final result = await _repository.joinGroup(
      inviteCode: state.inviteCode,
      source: JoinSource.invite,
    );
    _emitOutcome(result, state.preview);
  }

  Future<void> joinAny(String deviceTimezone) async {
    emit(const JoinState(status: JoinStatus.loading));
    final result = await _repository.joinAnyGroup(deviceTimezone);
    _emitOutcome(result, null);
  }

  void _emitOutcome(Result<JoinOutcome> result, PublicGroupProfile? preview) {
    if (isClosed) return;
    result.when(
      success: (JoinOutcome outcome) => emit(
        JoinState(
          status: outcome.joined ? JoinStatus.joined : JoinStatus.pending,
          inviteCode: state.inviteCode,
          preview: preview,
          outcome: outcome,
        ),
      ),
      failure: (AppFailure failure) => emit(
        JoinState(
          status: JoinStatus.failure,
          inviteCode: state.inviteCode,
          preview: preview,
          failure: failure,
        ),
      ),
    );
  }
}
