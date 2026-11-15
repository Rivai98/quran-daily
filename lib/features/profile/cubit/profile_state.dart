import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../data/entities/profile_entities.dart';

enum ProfileStatus { initial, loading, success, failure, offline }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.failure,
  });

  final ProfileStatus status;
  final UserProfile? profile;
  final AppFailure? failure;

  bool get isStale => profile?.isStale ?? false;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    bool clearProfile = false,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, profile, failure];
}
