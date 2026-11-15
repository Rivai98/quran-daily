import '../entities/profile_entities.dart';

class ProfileModel {
  const ProfileModel._();

  static UserProfile fromJson(
    Map<String, Object?> json, {
    bool isStale = false,
  }) {
    final displayName = (json['display_name'] as String?)?.trim() ?? '';
    final memberSinceStr = json['member_since'] as String?;
    final memberSince = memberSinceStr != null && memberSinceStr.isNotEmpty
        ? DateTime.tryParse(memberSinceStr)
        : null;

    final streak = (json['streak'] as num?)?.toInt() ?? 0;
    final bestStreak = (json['best_streak'] as num?)?.toInt() ?? 0;
    final portionsRead = (json['portions_read'] as num?)?.toInt() ?? 0;
    final portionsLate = (json['portions_late'] as num?)?.toInt() ?? 0;

    final rawKhatmas = json['khatmas'] as List<Object?>? ?? const [];
    final khatmas = rawKhatmas.map((item) {
      final map = (item as Map).cast<String, Object?>();
      return ProfileKhatma(
        groupId: map['group_id'] as String? ?? '',
        groupName: map['group_name'] as String? ?? '',
        completed: (map['completed'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    final rawBadges = json['badges'] as List<Object?>? ?? const [];
    final earnedMap = <ProfileBadgeCode, DateTime>{};
    for (final item in rawBadges) {
      final map = (item as Map).cast<String, Object?>();
      final codeStr = map['code'] as String?;
      final code = codeStr != null ? ProfileBadgeCode.fromCode(codeStr) : null;
      if (code != null) {
        final earnedStr = map['earned_at'] as String?;
        final earnedAt = earnedStr != null ? DateTime.tryParse(earnedStr) : null;
        earnedMap[code] = earnedAt ?? DateTime.now();
      }
    }

    // Always provide all 5 badges so the UI can render earned vs locked
    final badges = ProfileBadgeCode.values.map((code) {
      return ProfileBadge(
        code: code,
        earnedAt: earnedMap[code],
      );
    }).toList();

    return UserProfile(
      displayName: displayName,
      memberSince: memberSince,
      streak: streak,
      bestStreak: bestStreak,
      portionsRead: portionsRead,
      portionsLate: portionsLate,
      khatmas: khatmas,
      badges: badges,
      isStale: isStale,
    );
  }

  static Map<String, Object?> toJson(UserProfile profile) {
    return {
      'display_name': profile.displayName,
      'member_since': profile.memberSince != null
          ? _formatDate(profile.memberSince!)
          : null,
      'streak': profile.streak,
      'best_streak': profile.bestStreak,
      'portions_read': profile.portionsRead,
      'portions_late': profile.portionsLate,
      'khatmas': profile.khatmas.map((k) {
        return {
          'group_id': k.groupId,
          'group_name': k.groupName,
          'completed': k.completed,
        };
      }).toList(),
      'badges': profile.badges
          .where((b) => b.isEarned)
          .map((b) {
            return {
              'code': b.code.code,
              'earned_at': b.earnedAt != null ? _formatDate(b.earnedAt!) : null,
            };
          })
          .toList(),
    };
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
