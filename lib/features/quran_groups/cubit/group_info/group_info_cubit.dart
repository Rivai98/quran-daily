import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/entities/entities.dart';
import '../../data/repositories/groups_repository.dart';

enum GroupInfoStatus { initial, loading, success, offline, failure }

class GroupInfoState extends Equatable {
  const GroupInfoState({
    this.status = GroupInfoStatus.initial,
    this.groupInfo,
    this.failure,
    this.isUpdatingDetails = false,
    this.isUploadingPhoto = false,
    this.actionError,
  });

  final GroupInfoStatus status;
  final GroupInfo? groupInfo;
  final AppFailure? failure;
  final bool isUpdatingDetails;
  final bool isUploadingPhoto;
  final String? actionError;

  GroupInfoState copyWith({
    GroupInfoStatus? status,
    GroupInfo? groupInfo,
    AppFailure? failure,
    bool? isUpdatingDetails,
    bool? isUploadingPhoto,
    String? actionError,
  }) {
    return GroupInfoState(
      status: status ?? this.status,
      groupInfo: groupInfo ?? this.groupInfo,
      failure: failure ?? this.failure,
      isUpdatingDetails: isUpdatingDetails ?? this.isUpdatingDetails,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    groupInfo,
    failure,
    isUpdatingDetails,
    isUploadingPhoto,
    actionError,
  ];
}

class GroupInfoCubit extends Cubit<GroupInfoState> {
  GroupInfoCubit(this._repository) : super(const GroupInfoState());

  final GroupsRepository _repository;
  String? _groupId;

  Future<void> load(String groupId) async {
    _groupId = groupId;
    emit(state.copyWith(status: GroupInfoStatus.loading));
    final result = await _repository.getGroupInfo(groupId);
    result.when(
      success: (info) => emit(
        state.copyWith(
          status: GroupInfoStatus.success,
          groupInfo: info,
          failure: null,
        ),
      ),
      failure: (failure) => emit(
        state.copyWith(
          status: failure.kind == FailureKind.network
              ? GroupInfoStatus.offline
              : GroupInfoStatus.failure,
          failure: failure,
        ),
      ),
    );
  }

  Future<void> refresh() async {
    if (_groupId != null) {
      await load(_groupId!);
    }
  }

  Future<bool> updateDetails({
    required String name,
    String? description,
  }) async {
    if (_groupId == null) return false;
    emit(state.copyWith(isUpdatingDetails: true, actionError: null));
    final result = await _repository.updateGroupDetails(
      _groupId!,
      name,
      description: description,
    );
    return result.when(
      success: (_) {
        if (state.groupInfo != null) {
          emit(
            state.copyWith(
              isUpdatingDetails: false,
              groupInfo: state.groupInfo!.copyWith(
                name: name,
                description: description,
                clearDescription: description == null || description.isEmpty,
              ),
            ),
          );
        } else {
          emit(state.copyWith(isUpdatingDetails: false));
        }
        return true;
      },
      failure: (failure) {
        emit(
          state.copyWith(
            isUpdatingDetails: false,
            actionError: failure.message,
          ),
        );
        return false;
      },
    );
  }

  Future<bool> uploadPhotoBytes(
    Uint8List bytes, {
    String extension = 'jpg',
  }) async {
    if (_groupId == null) return false;
    emit(state.copyWith(isUploadingPhoto: true, actionError: null));
    final uploadResult = await _repository.uploadGroupPhoto(
      _groupId!,
      bytes,
      extension,
    );
    return await uploadResult.when(
      success: (storagePath) async {
        final setResult = await _repository.setGroupPhoto(
          _groupId!,
          storagePath,
        );
        return setResult.when(
          success: (_) {
            if (state.groupInfo != null) {
              emit(
                state.copyWith(
                  isUploadingPhoto: false,
                  groupInfo: state.groupInfo!.copyWith(photoPath: storagePath),
                ),
              );
            } else {
              emit(state.copyWith(isUploadingPhoto: false));
            }
            return true;
          },
          failure: (f) {
            emit(
              state.copyWith(isUploadingPhoto: false, actionError: f.message),
            );
            return false;
          },
        );
      },
      failure: (f) {
        emit(state.copyWith(isUploadingPhoto: false, actionError: f.message));
        return false;
      },
    );
  }

  Future<bool> removePhoto() async {
    if (_groupId == null) return false;
    emit(state.copyWith(isUploadingPhoto: true, actionError: null));
    final result = await _repository.setGroupPhoto(_groupId!, null);
    return result.when(
      success: (_) {
        if (state.groupInfo != null) {
          emit(
            state.copyWith(
              isUploadingPhoto: false,
              groupInfo: state.groupInfo!.copyWith(clearPhotoPath: true),
            ),
          );
        } else {
          emit(state.copyWith(isUploadingPhoto: false));
        }
        return true;
      },
      failure: (f) {
        emit(state.copyWith(isUploadingPhoto: false, actionError: f.message));
        return false;
      },
    );
  }
}
