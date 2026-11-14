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
