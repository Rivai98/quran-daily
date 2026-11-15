import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/models/models.dart';

void main() {
  group('Spec 007 Reader and Profiles Data Models (T008)', () {
    test('ReaderInfo round-trip and parsing', () {
      final json = {
        'user_id': 'u-123',
        'display_name': 'محمد عبد الله',
        'initials': 'م ع',
      };
      final reader = readerInfoFromJson(json);
      expect(reader.userId, 'u-123');
      expect(reader.displayName, 'محمد عبد الله');
      expect(reader.initials, 'م ع');

      final serialized = readerInfoToJson(reader);
      expect(serialized, json);
      expect(readerInfoFromJson(serialized), reader);
    });

    test('Assignment parses reader field when present', () {
      final json = {
        'assignment_id': 'a-1',
        'juz': 5,
        'portion_index': 5,
        'seat_number': 3,
        'kind': 'seat',
        'status': 'completed',
        'reader_display_name': 'أحمد علي',
        'reader': {
          'user_id': 'u-456',
          'display_name': 'أحمد علي',
          'initials': 'أ ع',
        },
        'is_me': false,
        'completed_at': '2026-11-15T10:30:00.000Z',
      };

      final assignment = assignmentFromJson(json);
      expect(assignment.reader, isNotNull);
      expect(assignment.reader!.userId, 'u-456');
      expect(assignment.reader!.displayName, 'أحمد علي');
      expect(assignment.reader!.initials, 'أ ع');
      expect(assignment.completedAt, DateTime.parse('2026-11-15T10:30:00.000Z'));

      final serialized = assignmentToJson(assignment);
      expect(serialized['reader'], json['reader']);
      final restored = assignmentFromJson(serialized);
      expect(restored.reader, assignment.reader);
    });

    test('Assignment parses null reader when hidden (privacy rule)', () {
      final json = {
        'assignment_id': 'a-2',
        'juz': 6,
        'portion_index': 6,
        'seat_number': 4,
        'kind': 'seat',
        'status': 'unread',
        'reader_display_name': null,
        'reader': null,
        'is_me': false,
        'completed_at': null,
      };

      final assignment = assignmentFromJson(json);
      expect(assignment.reader, isNull);
      expect(assignment.readerDisplayName, isNull);
      expect(assignment.status, AssignmentStatusEnum.unread);

      final serialized = assignmentToJson(assignment);
      expect(serialized.containsKey('reader'), isFalse);
    });

    test('HistoryDaySummary parses and serializes portions array', () {
      final json = {
        'group_date': '2026-11-14',
        'completed_count': 25,
        'late_count': 2,
        'missed_count': 3,
        'unread_count': 0,
        'full_khatma': false,
        'cycle_number': 1,
        'cycle_day': 14,
        'portion_unit': 'juz',
        'my_result': {
          'assignment_id': 'a-mine',
          'juz': 14,
          'seat_number': 14,
          'kind': 'seat',
          'status': 'completed',
          'reader': {
            'user_id': 'u-me',
            'display_name': 'عمر',
            'initials': 'ع',
          },
          'is_me': true,
        },
        'portions': [
          {
            'assignment_id': 'a-1',
            'juz': 1,
            'portion_index': 1,
            'seat_number': 1,
            'kind': 'seat',
            'status': 'completed',
            'reader': {
              'user_id': 'u-1',
              'display_name': 'خالد',
              'initials': 'خ',
            },
            'is_me': false,
          },
          {
            'assignment_id': 'a-2',
            'juz': 2,
            'portion_index': 2,
            'seat_number': 2,
            'kind': 'seat',
            'status': 'unread',
            'reader': null,
            'is_me': false,
          },
        ],
      };

      final daySummary = historyDaySummaryFromJson(json);
      expect(daySummary.portions, isNotNull);
      expect(daySummary.portions!.length, 2);
      expect(daySummary.portions![0].reader?.displayName, 'خالد');
      expect(daySummary.portions![1].reader, isNull);
      expect(daySummary.portions![1].status, AssignmentStatusEnum.unread);

      final serialized = historyDaySummaryToJson(daySummary);
      expect(serialized['portions'], isA<List>());
      final restored = historyDaySummaryFromJson(serialized);
      expect(restored.portions!.length, 2);
      expect(restored.portions![0].reader, daySummary.portions![0].reader);
    });

    test('MemberGroupProfile parses and round-trips correctly', () {
      final json = {
        'user_id': 'u-target',
        'group_id': 'g-main',
        'display_name': 'إبراهيم حسن',
        'initials': 'إ ح',
        'bio': 'طالب علم ومحب للقرآن',
        'role': 'member',
        'seat_number': 12,
        'member_since': '2026-10-01T08:00:00.000Z',
        'is_me': false,
        'current_streak': 7,
        'completion_rate': 93,
        'portions_read': 28,
        'recent_days': [
          {
            'group_date': '2026-11-14',
            'portion_index': 12,
            'juz': 12,
            'kind': 'seat',
            'status': 'completed',
            'completed_at': '2026-11-14T18:00:00.000Z',
          },
          {
            'group_date': '2026-11-13',
            'portion_index': 12,
            'juz': 12,
            'kind': 'seat',
            'status': 'late',
            'completed_at': '2026-11-14T01:00:00.000Z',
          },
        ],
      };

      final profile = memberGroupProfileFromJson(json);
      expect(profile.userId, 'u-target');
      expect(profile.groupId, 'g-main');
      expect(profile.displayName, 'إبراهيم حسن');
      expect(profile.initials, 'إ ح');
      expect(profile.bio, 'طالب علم ومحب للقرآن');
      expect(profile.role, 'member');
      expect(profile.seatNumber, 12);
      expect(profile.memberSince, DateTime.parse('2026-10-01T08:00:00.000Z'));
      expect(profile.isMe, isFalse);
      expect(profile.currentStreak, 7);
      expect(profile.completionRate, 93);
      expect(profile.portionsRead, 28);
      expect(profile.recentDays.length, 2);
      expect(profile.recentDays[0].status, AssignmentStatusEnum.completed);
      expect(profile.recentDays[1].status, AssignmentStatusEnum.late);

      final serialized = memberGroupProfileToJson(profile);
      expect(serialized['display_name'], 'إبراهيم حسن');
      expect(serialized['bio'], 'طالب علم ومحب للقرآن');
      expect(serialized['current_streak'], 7);
      final restored = memberGroupProfileFromJson(serialized);
      expect(restored.userId, profile.userId);
      expect(restored.recentDays.length, 2);
    });

    test('GroupInfo parses and round-trips correctly', () {
      final json = {
        'group_id': 'g-789',
        'name': 'مجموعة الفجر',
        'description': 'ختمة يومية مستمرة بعد صلاة الفجر',
        'photo_path': 'g-789/photo.jpg',
        'status': 'active',
        'visibility': 'public',
        'join_mode': 'auto_accept',
        'portion_unit': 'juz',
        'timezone': 'Asia/Riyadh',
        'day_start_time': '04:30:00',
        'created_at': '2026-09-01T00:00:00.000Z',
        'start_date': '2026-09-01',
        'my_role': 'owner',
        'member_count': 30,
        'seat_capacity': 30,
        'khatma_count': 4,
        'invite_code': 'FAJR2026',
        'members': [
          {
            'user_id': 'u-owner',
            'membership_id': 'm-1',
            'display_name': 'عبد الرحمن أحمد',
            'initials': 'ع أ',
            'role': 'owner',
            'seat_number': 1,
            'joined_at': '2026-09-01T00:00:00.000Z',
            'is_me': true,
          },
          {
            'user_id': 'u-member',
            'membership_id': 'm-2',
            'display_name': 'ياسين محمود',
            'initials': 'ي م',
            'role': 'member',
            'seat_number': 2,
            'joined_at': '2026-09-02T00:00:00.000Z',
            'is_me': false,
          },
        ],
      };

      final groupInfo = groupInfoFromJson(json);
      expect(groupInfo.groupId, 'g-789');
      expect(groupInfo.name, 'مجموعة الفجر');
      expect(groupInfo.description, 'ختمة يومية مستمرة بعد صلاة الفجر');
      expect(groupInfo.photoPath, 'g-789/photo.jpg');
      expect(groupInfo.status, GroupStatus.active);
      expect(groupInfo.visibility, GroupVisibility.public);
      expect(groupInfo.joinMode, JoinMode.autoAccept);
      expect(groupInfo.portionUnit, PortionUnit.juz);
      expect(groupInfo.memberCount, 30);
      expect(groupInfo.khatmaCount, 4);
      expect(groupInfo.inviteCode, 'FAJR2026');
      expect(groupInfo.members.length, 2);
      expect(groupInfo.members[0].initials, 'ع أ');
      expect(groupInfo.members[0].isMe, isTrue);

      final serialized = groupInfoToJson(groupInfo);
      expect(serialized['name'], 'مجموعة الفجر');
      expect(serialized['photo_path'], 'g-789/photo.jpg');
      final restored = groupInfoFromJson(serialized);
      expect(restored.groupId, groupInfo.groupId);
      expect(restored.members.length, 2);
    });

    test('UserProfile parses update_my_profile response', () {
      final json = {
        'user_id': 'u-me',
        'display_name': 'زيد بن ثابت',
        'avatar_key': 'man_kufi',
        'initials': 'ز ث',
        'bio': 'حفظ القرآن وتدبره',
        'updated_at': '2026-11-15T12:00:00.000Z',
      };

      final profile = userProfileFromJson(json);
      expect(profile.userId, 'u-me');
      expect(profile.displayName, 'زيد بن ثابت');
      expect(profile.avatarKey, 'man_kufi');
      expect(profile.initials, 'ز ث');
      expect(profile.bio, 'حفظ القرآن وتدبره');
      expect(profile.updatedAt, DateTime.parse('2026-11-15T12:00:00.000Z'));

      final serialized = userProfileToJson(profile);
      expect(serialized['display_name'], 'زيد بن ثابت');
      expect(serialized['avatar_key'], 'man_kufi');
      final restored = userProfileFromJson(serialized);
      expect(restored, profile);
    });
  });
}
