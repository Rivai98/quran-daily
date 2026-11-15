import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/quran/portion_unit.dart';
import '../../data/entities/entities.dart';
import '../../data/repositories/groups_repository.dart';

enum CreateGroupStatus { initial, submitting, success, failure }

class CreateGroupState extends Equatable {
  const CreateGroupState({
    this.status = CreateGroupStatus.initial,
    this.portionUnit = PortionUnit.juz,
    this.created,
    this.failure,
  });

  final CreateGroupStatus status;
  final PortionUnit portionUnit;
  final CreatedGroup? created;
  final AppFailure? failure;

  CreateGroupState copyWith({
    CreateGroupStatus? status,
    PortionUnit? portionUnit,
    CreatedGroup? created,
    AppFailure? failure,
    bool clearCreated = false,
    bool clearFailure = false,
  }) {
    return CreateGroupState(
      status: status ?? this.status,
      portionUnit: portionUnit ?? this.portionUnit,
      created: clearCreated ? null : (created ?? this.created),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, portionUnit, created, failure];
}

/// S4 create group: client-side validation (3-60 name, ≤200 description),
/// submit guard, limit error, success.
class CreateGroupCubit extends Cubit<CreateGroupState> {
  CreateGroupCubit({required GroupsRepository repository})
    : _repository = repository,
      super(const CreateGroupState());

  final GroupsRepository _repository;

  void selectPortionUnit(PortionUnit unit) {
    if (state.status == CreateGroupStatus.submitting) return;
    emit(state.copyWith(portionUnit: unit, clearFailure: true));
  }

  Future<void> submit({
    required String name,
    String? shortDescription,
    required String timezone,
    String dayStartTime = '00:00',
    required GroupVisibility visibility,
    required JoinMode joinMode,
    PortionUnit? portionUnit,
  }) async {
    if (state.status == CreateGroupStatus.submitting) return;

    final trimmedName = name.trim();
    if (trimmedName.length < 3 ||
        trimmedName.length > 60 ||
        (shortDescription != null && shortDescription.trim().length > 200) ||
        timezone.isEmpty) {
      emit(
        state.copyWith(
          status: CreateGroupStatus.failure,
          failure: const ValidationFailure(
            message: 'invalid input',
            code: 'validation_failed',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: CreateGroupStatus.submitting,
        clearCreated: true,
        clearFailure: true,
      ),
    );
    final result = await _repository.createGroup(
      CreateGroupInput(
        name: trimmedName,
        shortDescription: shortDescription?.trim(),
        timezone: timezone,
        dayStartTime: dayStartTime,
        visibility: visibility,
        joinMode: joinMode,
        portionUnit: portionUnit ?? state.portionUnit,
      ),
    );
    result.when(
      success: (CreatedGroup created) => emit(
        state.copyWith(status: CreateGroupStatus.success, created: created),
      ),
      failure: (AppFailure failure) => emit(
        state.copyWith(status: CreateGroupStatus.failure, failure: failure),
      ),
    );
  }

  void reset() => emit(const CreateGroupState());
}
