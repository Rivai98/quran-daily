import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/app_colors.dart';
import 'package:quran_daily/core/design_system/assignment_status.dart';

/// Constitution Principle VI (v2.4.0) color tables are binding tokens.
/// These tests pin the exact light/dark values, including the status
/// foreground/background pairs; `available` and `unread` MUST reuse the
/// named tokens (no dedicated hex values).
void main() {
  group('AppColors.light core tokens', () {
    const c = AppColors.light;

    test('matches the constitution light column', () {
      expect(c.primary, const Color(0xFF0E5E4E));
      expect(c.onPrimary, const Color(0xFFFFFFFF));
      expect(c.primaryContainer, const Color(0xFFD7EDE6));
      expect(c.onPrimaryContainer, const Color(0xFF08392F));
      expect(c.accent, const Color(0xFFB07D2B));
      expect(c.background, const Color(0xFFF7F5EF));
      expect(c.surface, const Color(0xFFFFFFFF));
      expect(c.surfaceMuted, const Color(0xFFF0EDE4));
      expect(c.ink, const Color(0xFF1B2420));
      expect(c.inkMuted, const Color(0xFF5A6560));
      expect(c.border, const Color(0xFFE2DED3));
      expect(c.danger, const Color(0xFFB3261E));
    });
  });

  group('AppColors.dark core tokens', () {
    const c = AppColors.dark;

    test('matches the constitution dark column', () {
      expect(c.primary, const Color(0xFF5CC4A8));
      expect(c.onPrimary, const Color(0xFF00382D));
      expect(c.primaryContainer, const Color(0xFF123F35));
      expect(c.onPrimaryContainer, const Color(0xFFBFEADC));
      expect(c.accent, const Color(0xFFE2B866));
      expect(c.background, const Color(0xFF0F1513));
      expect(c.surface, const Color(0xFF171F1C));
      expect(c.surfaceMuted, const Color(0xFF1F2925));
      expect(c.ink, const Color(0xFFE7ECE9));
      expect(c.inkMuted, const Color(0xFFA3AFA9));
      expect(c.border, const Color(0xFF2C3833));
      expect(c.danger, const Color(0xFFFF8A80));
    });
  });

  group('status colors', () {
    test('light fg/bg pairs match the constitution status table', () {
      const c = AppColors.light;
      expect(c.statusFg(AssignmentStatus.completed), const Color(0xFF1B7A47));
      expect(c.statusBg(AssignmentStatus.completed), const Color(0xFFE3F3EA));
      expect(c.statusFg(AssignmentStatus.pending), c.infoFg);
      expect(c.statusBg(AssignmentStatus.pending), c.infoBg);
      expect(c.statusFg(AssignmentStatus.missed), const Color(0xFFB3261E));
      expect(c.statusBg(AssignmentStatus.missed), const Color(0xFFFBE6E4));
      expect(c.statusFg(AssignmentStatus.late), const Color(0xFF5B47B5));
      expect(c.statusBg(AssignmentStatus.late), const Color(0xFFECE8FA));
    });

    test('dark fg/bg pairs match the constitution status table', () {
      const c = AppColors.dark;
      expect(c.statusFg(AssignmentStatus.completed), const Color(0xFF6FD39C));
      expect(c.statusBg(AssignmentStatus.completed), const Color(0xFF173A28));
      expect(c.statusFg(AssignmentStatus.pending), c.infoFg);
      expect(c.statusBg(AssignmentStatus.pending), c.infoBg);
      expect(c.statusFg(AssignmentStatus.missed), const Color(0xFFFF8A80));
      expect(c.statusBg(AssignmentStatus.missed), const Color(0xFF3D1A18));
      expect(c.statusFg(AssignmentStatus.late), const Color(0xFFB4A6FF));
      expect(c.statusBg(AssignmentStatus.late), const Color(0xFF2A2448));
    });

    test('available reuses primary / primaryContainer in both themes', () {
      expect(
        AppColors.light.statusFg(AssignmentStatus.available),
        AppColors.light.primary,
      );
      expect(
        AppColors.light.statusBg(AssignmentStatus.available),
        AppColors.light.primaryContainer,
      );
      expect(
        AppColors.dark.statusFg(AssignmentStatus.available),
        AppColors.dark.primary,
      );
      expect(
        AppColors.dark.statusBg(AssignmentStatus.available),
        AppColors.dark.primaryContainer,
      );
    });

    test('unread reuses inkMuted / surfaceMuted in both themes', () {
      expect(
        AppColors.light.statusFg(AssignmentStatus.unread),
        AppColors.light.inkMuted,
      );
      expect(
        AppColors.light.statusBg(AssignmentStatus.unread),
        AppColors.light.surfaceMuted,
      );
      expect(
        AppColors.dark.statusFg(AssignmentStatus.unread),
        AppColors.dark.inkMuted,
      );
      expect(
        AppColors.dark.statusBg(AssignmentStatus.unread),
        AppColors.dark.surfaceMuted,
      );
    });
  });

  test('is a ThemeExtension usable in ThemeData.extensions', () {
    expect(AppColors.light, isA<ThemeExtension<AppColors>>());
    expect(AppColors.dark, isA<ThemeExtension<AppColors>>());
  });
}
