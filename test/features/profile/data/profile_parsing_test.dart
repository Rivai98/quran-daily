import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/features/profile/data/entities/profile_entities.dart';
import 'package:quran_daily/features/profile/data/models/profile_model.dart';

void main() {
  group('ProfileModel parsing', () {
    test('parses full get_my_profile contract payload', () {
      final json = <String, Object?>{
        'display_name': 'أحمد السعيد',
        'member_since': '2026-11-01',
        'streak': 7,
        'best_streak': 14,
        'portions_read': 45,
        'portions_late': 3,
        'khatmas': [
          {
            'group_id': 'g-1111',
            'group_name': 'ختمة الفجر',
            'completed': 2,
          },
          {
            'group_id': 'g-2222',
            'group_name': 'ختمة النور',
            'completed': 1,
          },
        ],
        'badges': [
          {
            'code': 'first_khatma',
            'earned_at': '2026-11-05',
          },
          {
            'code': 'streak_7',
            'earned_at': '2026-11-08',
          },
        ],
      };

      final profile = ProfileModel.fromJson(json);

      expect(profile.displayName, 'أحمد السعيد');
      expect(profile.memberSince, DateTime(2026, 11, 1));
      expect(profile.streak, 7);
      expect(profile.bestStreak, 14);
      expect(profile.portionsRead, 45);
      expect(profile.portionsLate, 3);
      expect(profile.isStale, false);

      expect(profile.khatmas.length, 2);
      expect(profile.khatmas[0].groupId, 'g-1111');
      expect(profile.khatmas[0].groupName, 'ختمة الفجر');
      expect(profile.khatmas[0].completed, 2);

      // Badges includes all 5 known badges, with earned status
      expect(profile.badges.length, 5);
      final firstKhatma = profile.badges.firstWhere((b) => b.code == ProfileBadgeCode.firstKhatma);
      expect(firstKhatma.isEarned, true);
      expect(firstKhatma.earnedAt, DateTime(2026, 11, 5));

      final streak7 = profile.badges.firstWhere((b) => b.code == ProfileBadgeCode.streak7);
      expect(streak7.isEarned, true);
      expect(streak7.earnedAt, DateTime(2026, 11, 8));

      final streak30 = profile.badges.firstWhere((b) => b.code == ProfileBadgeCode.streak30);
      expect(streak30.isEarned, false);
      expect(streak30.earnedAt, isNull);

      final streak100 = profile.badges.firstWhere((b) => b.code == ProfileBadgeCode.streak100);
      expect(streak100.isEarned, false);

      final portions100 = profile.badges.firstWhere((b) => b.code == ProfileBadgeCode.portions100);
      expect(portions100.isEarned, false);
    });

    test('parses empty / minimal payload with defaults', () {
      final json = <String, Object?>{
        'display_name': '',
        'member_since': null,
        'streak': 0,
        'best_streak': 0,
        'portions_read': 0,
        'portions_late': 0,
        'khatmas': <Object?>[],
        'badges': <Object?>[],
      };

      final profile = ProfileModel.fromJson(json);

      expect(profile.displayName, '');
      expect(profile.memberSince, isNull);
      expect(profile.streak, 0);
      expect(profile.bestStreak, 0);
      expect(profile.portionsRead, 0);
      expect(profile.portionsLate, 0);
      expect(profile.khatmas, isEmpty);
      expect(profile.badges.every((b) => !b.isEarned), true);
    });

    test('serializes to and from json for cache storage', () {
      final original = UserProfile(
        displayName: 'فاطمة',
        memberSince: DateTime(2026, 10, 15),
        streak: 5,
        bestStreak: 10,
        portionsRead: 30,
        portionsLate: 2,
        khatmas: const [
          ProfileKhatma(groupId: 'g-1', groupName: 'ختمة', completed: 1),
        ],
        badges: [
          ProfileBadge(code: ProfileBadgeCode.firstKhatma, earnedAt: DateTime(2026, 10, 20)),
          const ProfileBadge(code: ProfileBadgeCode.streak7),
          const ProfileBadge(code: ProfileBadgeCode.streak30),
          const ProfileBadge(code: ProfileBadgeCode.streak100),
          const ProfileBadge(code: ProfileBadgeCode.portions100),
        ],
        isStale: true,
      );

      final json = ProfileModel.toJson(original);
      final restored = ProfileModel.fromJson(json, isStale: true);

      expect(restored.displayName, original.displayName);
      expect(restored.memberSince, original.memberSince);
      expect(restored.streak, original.streak);
      expect(restored.bestStreak, original.bestStreak);
      expect(restored.portionsRead, original.portionsRead);
      expect(restored.portionsLate, original.portionsLate);
      expect(restored.khatmas, original.khatmas);
      expect(restored.badges, original.badges);
      expect(restored.isStale, true);
    });
  });
}
