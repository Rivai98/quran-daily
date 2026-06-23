import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';

void main() {
  test('uses canonical Arabic status labels', () {
    expect(
      ArabicStrings.pending,
      '\u{642}\u{64a}\u{62f} \u{627}\u{644}\u{627}\u{646}\u{62a}\u{638}\u{627}\u{631}',
    );
    expect(
      ArabicStrings.completed,
      '\u{645}\u{643}\u{62a}\u{645}\u{644}',
    );
    expect(ArabicStrings.missed, '\u{641}\u{627}\u{626}\u{62a}');
    expect(
      ArabicStrings.late,
      '\u{645}\u{643}\u{62a}\u{645}\u{644} \u{645}\u{62a}\u{623}\u{62e}\u{631}',
    );
  });

  test('keeps critical user-facing copy valid UTF-8 Arabic', () {
    final criticalCopy = [
      ArabicStrings.appName,
      ArabicStrings.signInWithGoogle,
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
