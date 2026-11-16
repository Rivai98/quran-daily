import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/entities/profile_entities.dart';
import '../data/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required this._repository}) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load({bool forceRefresh = false}) async {
    emit(state.copyWith(status: ProfileStatus.loading, clearFailure: true));
    final result = await _repository.getProfile(forceRefresh: forceRefresh);
    result.when(
      success: (UserProfile profile) {
        emit(
          state.copyWith(
            status: profile.isStale
                ? ProfileStatus.offline
                : ProfileStatus.success,
            profile: profile,
          ),
        );
      },
      failure: (failure) {
        emit(state.copyWith(status: ProfileStatus.failure, failure: failure));
      },
    );
  }

  Future<void> refresh() => load(forceRefresh: true);
}
