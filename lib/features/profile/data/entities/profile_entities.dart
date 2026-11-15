import 'package:equatable/equatable.dart';

/// Available badges in the system (FR-011).
enum ProfileBadgeCode {
  firstKhatma('first_khatma'),
  streak7('streak_7'),
  streak30('streak_30'),
  streak100('streak_100'),
  portions100('portions_100');

  const ProfileBadgeCode(this.code);
  final String code;

  static ProfileBadgeCode? fromCode(String code) {
    for (final b in values) {
      if (b.code == code) return b;
    }
    return null;
  }
}

/// Represents an achievement badge with its earned status.
class ProfileBadge extends Equatable {
  const ProfileBadge({required this.code, this.earnedAt});

  final ProfileBadgeCode code;
  final DateTime? earnedAt;

  bool get isEarned => earnedAt != null;

  @override
  List<Object?> get props => [code, earnedAt];
}

/// Completed khatmas per group.
class ProfileKhatma extends Equatable {
  const ProfileKhatma({
    required this.groupId,
    required this.groupName,
    required this.completed,
  });

  final String groupId;
  final String groupName;
  final int completed;

  @override
  List<Object?> get props => [groupId, groupName, completed];
}

/// The user profile entity containing personal reading statistics.
class UserProfile extends Equatable {
  const UserProfile({
    required this.displayName,
    this.avatarKey = 'ornament',
    this.memberSince,
    required this.streak,
    required this.bestStreak,
    required this.portionsRead,
    required this.portionsLate,
    required this.khatmas,
    required this.badges,
    this.isStale = false,
  });

  final String displayName;
  final String avatarKey;
  final DateTime? memberSince;
  final int streak;
  final int bestStreak;
  final int portionsRead;
  final int portionsLate;
  final List<ProfileKhatma> khatmas;
  final List<ProfileBadge> badges;
  final bool isStale;

  UserProfile copyWith({
    String? displayName,
    String? avatarKey,
    DateTime? memberSince,
    int? streak,
    int? bestStreak,
    int? portionsRead,
    int? portionsLate,
    List<ProfileKhatma>? khatmas,
    List<ProfileBadge>? badges,
    bool? isStale,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      avatarKey: avatarKey ?? this.avatarKey,
      memberSince: memberSince ?? this.memberSince,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      portionsRead: portionsRead ?? this.portionsRead,
      portionsLate: portionsLate ?? this.portionsLate,
      khatmas: khatmas ?? this.khatmas,
      badges: badges ?? this.badges,
      isStale: isStale ?? this.isStale,
    );
  }

  @override
  List<Object?> get props => [
    displayName,
    avatarKey,
    memberSince,
    streak,
    bestStreak,
    portionsRead,
    portionsLate,
    khatmas,
    badges,
    isStale,
  ];
}
