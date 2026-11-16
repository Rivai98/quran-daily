import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';

void main() {
  test('uses canonical Arabic status labels (constitution v2.4.0)', () {
    expect(ArabicStrings.completed, 'تمت القراءة');
    expect(ArabicStrings.pending, 'لم يُقرأ بعد');
    expect(ArabicStrings.missed, 'فائت');
    expect(ArabicStrings.late, 'قُرئ متأخرًا');
    expect(ArabicStrings.available, 'متاح');
    expect(ArabicStrings.unread, 'لم يقرأه أحد');
  });

  test('provides 30 ordinal juz names in order', () {
    expect(ArabicStrings.juzOrdinals.length, 30);
    expect(ArabicStrings.juzName(1), 'الجزء الأول');
    expect(ArabicStrings.juzName(5), 'الجزء الخامس');
    expect(ArabicStrings.juzName(20), 'الجزء العشرون');
    expect(ArabicStrings.juzName(30), 'الجزء الثلاثون');
    expect(() => ArabicStrings.juzName(0), throwsRangeError);
    expect(() => ArabicStrings.juzName(31), throwsRangeError);
  });

  test(
    'formats repository-provided reading metadata with Arabic-Indic digits',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final metadata = QuranMetadataRepository();
      await metadata.load();
      final start = metadata.juz(1);
      final end = metadata.juz(1);
      expect(
        ArabicStrings.juzRange(
          startSura: metadata.suraName(start.startSura),
          startAya: start.startAya,
          endSura: metadata.suraName(end.endSura),
          endAya: end.endAya,
        ),
        startsWith('من سورة ${metadata.suraName(start.startSura)} آية '),
      );
      expect(
        ArabicStrings.juzRange(
          startSura: metadata.suraName(start.startSura),
          startAya: start.startAya,
          endSura: metadata.suraName(end.endSura),
          endAya: end.endAya,
        ),
        contains(RegExp('[٠-٩]')),
      );
    },
  );

  test('role markers are Arabic-only', () {
    expect(ArabicStrings.roleOwner, 'المالك');
    expect(ArabicStrings.roleSupervisor, 'مشرف');
    expect(ArabicStrings.roleMember, 'عضو');
  });

  test('counted nouns use Arabic forms for one, two, three through ten, and eleven plus', () {
    expect(
      ArabicStrings.countedNoun(
        1,
        singular: 'عضو',
        dual: 'عضوين',
        plural: 'أعضاء',
        accusative: 'عضوًا',
      ),
      'عضو واحد',
    );
    expect(
      ArabicStrings.countedNoun(
        2,
        singular: 'عضو',
        dual: 'عضوين',
        plural: 'أعضاء',
        accusative: 'عضوًا',
      ),
      'عضوين',
    );
    expect(
      ArabicStrings.countedNoun(
        3,
        singular: 'عضو',
        dual: 'عضوين',
        plural: 'أعضاء',
        accusative: 'عضوًا',
      ),
      allOf(contains('٣'), contains('أعضاء')),
    );
    expect(
      ArabicStrings.countedNoun(
        10,
        singular: 'عضو',
        dual: 'عضوين',
        plural: 'أعضاء',
        accusative: 'عضوًا',
      ),
      allOf(contains('١٠'), contains('أعضاء')),
    );
    expect(
      ArabicStrings.countedNoun(
        11,
        singular: 'عضو',
        dual: 'عضوين',
        plural: 'أعضاء',
        accusative: 'عضوًا',
      ),
      allOf(contains('١١'), contains('عضوًا')),
    );
  });

  test('badge countdown uses the matching Arabic counted noun', () {
    expect(
      ArabicStrings.badgeRemaining(2, 'المداومة', unit: 'day'),
      contains('يومان'),
    );
    expect(
      ArabicStrings.badgeRemaining(3, 'الختمة', unit: 'khatma'),
      contains('ختمات'),
    );
  });

  test('equal range boundaries render once', () {
    expect(ArabicStrings.pageRangeLabel(1, 1), contains('صفحة'));
    expect(ArabicStrings.pageRangeLabel(1, 1), isNot(contains('إلى')));
    expect(
      ArabicStrings.portionRange('الفاتحة', 1, 'الفاتحة', 1),
      isNot(contains('إلى')),
    );
  });

  test('maps a suspended sign-in refusal to calm Arabic guidance', () {
    expect(
      ArabicStrings.authError('suspended'),
      ArabicStrings.adminSuspendedSignIn,
    );
  });

  test('maps join-any no availability to useful Arabic next steps', () {
    expect(
      ArabicStrings.authError('no_group_available'),
      ArabicStrings.noGroupAvailable,
    );
    expect(ArabicStrings.noGroupAvailable, contains('أعد المحاولة'));
  });

  test('maps membership limit to its specific Arabic explanation', () {
    expect(
      ArabicStrings.authError('membership_limit'),
      'أنت في مجموعتين بالفعل (الحد الأقصى).',
    );
  });

  test('keeps critical user-facing copy valid UTF-8 Arabic', () {
    final criticalCopy = [
      ArabicStrings.appName,
      ArabicStrings.pendingApproval,
      ArabicStrings.groupSelectionTitle,
      ArabicStrings.dashboardTitle,
      ArabicStrings.assignmentDetailTitle,
      ArabicStrings.organizerReviewTitle,
      ArabicStrings.joinRequestsTitle,
      ArabicStrings.memberManagementTitle,
      ArabicStrings.historyTitle,
      ArabicStrings.settingsTitle,
      ArabicStrings.offlineStale,
      ArabicStrings.noApprovedGroups,
      ArabicStrings.noPublicGroups,
      ArabicStrings.noJoinRequests,
      ArabicStrings.noPublishedCycle,
      ArabicStrings.emptyHistory,
      ArabicStrings.groupFull,
      ArabicStrings.publishBlocked,
      ArabicStrings.noQuranReader,
      ArabicStrings.syncQueued,
    ];

    for (final copy in criticalCopy) {
      expect(copy.trim(), isNotEmpty);
      expect(copy, isNot(contains(RegExp('[\\u00D8\\u00D9]'))));
    }
  });
}
