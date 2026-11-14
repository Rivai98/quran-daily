import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';

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

  test('formats the reading range with Arabic-Indic digits', () {
    expect(
      ArabicStrings.juzRange(
        startSura: 'النساء',
        startAya: 24,
        endSura: 'النساء',
        endAya: 147,
      ),
      'من سورة النساء آية ٢٤ إلى سورة النساء آية ١٤٧',
    );
    expect(
      ArabicStrings.juzRange(
        startSura: 'البقرة',
        startAya: 142,
        endSura: 'آل عمران',
        endAya: 200,
      ),
      'من سورة البقرة آية ١٤٢ إلى سورة آل عمران آية ٢٠٠',
    );
  });

  test('role markers are Arabic-only', () {
    expect(ArabicStrings.roleOwner, 'المالك');
    expect(ArabicStrings.roleSupervisor, 'مشرف');
    expect(ArabicStrings.roleMember, 'عضو');
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
