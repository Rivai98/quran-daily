import 'package:flutter/material.dart';

import 'assignment_status.dart';

/// Color tokens from constitution Principle VI (v2.4.0).
///
/// The exact values are binding; feature code must never introduce raw
/// colors and must read these through `Theme.of(context).extension<AppColors>()!`
/// (or the Material colorScheme wired in [AppTheme]). `available` and
/// `unread` reuse the named tokens; they have no dedicated hex values.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.border,
    required this.danger,
    required this.completedFg,
    required this.completedBg,
    required this.pendingFg,
    required this.pendingBg,
    required this.missedFg,
    required this.missedBg,
    required this.lateFg,
    required this.lateBg,
  });

  /// Brand, primary buttons, active state.
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  /// Decorative highlights only, never body text.
  final Color accent;

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color ink;
  final Color inkMuted;
  final Color border;
  final Color danger;

  // Status pairs (foreground / background), light and dark variants differ.
  final Color completedFg;
  final Color completedBg;
  final Color pendingFg;
  final Color pendingBg;
  final Color missedFg;
  final Color missedBg;
  final Color lateFg;
  final Color lateBg;

  static const AppColors light = AppColors(
    primary: Color(0xFF0E5E4E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD7EDE6),
    onPrimaryContainer: Color(0xFF08392F),
    accent: Color(0xFFB07D2B),
    background: Color(0xFFF7F5EF),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF0EDE4),
    ink: Color(0xFF1B2420),
    inkMuted: Color(0xFF5A6560),
    border: Color(0xFFE2DED3),
    danger: Color(0xFFB3261E),
    completedFg: Color(0xFF1B7A47),
    completedBg: Color(0xFFE3F3EA),
    pendingFg: Color(0xFF8A5A00),
    pendingBg: Color(0xFFFBF0D9),
    missedFg: Color(0xFFB3261E),
    missedBg: Color(0xFFFBE6E4),
    lateFg: Color(0xFF5B47B5),
    lateBg: Color(0xFFECE8FA),
  );

  static const AppColors dark = AppColors(
    primary: Color(0xFF5CC4A8),
    onPrimary: Color(0xFF00382D),
    primaryContainer: Color(0xFF123F35),
    onPrimaryContainer: Color(0xFFBFEADC),
    accent: Color(0xFFE2B866),
    background: Color(0xFF0F1513),
    surface: Color(0xFF171F1C),
    surfaceMuted: Color(0xFF1F2925),
    ink: Color(0xFFE7ECE9),
    inkMuted: Color(0xFFA3AFA9),
    border: Color(0xFF2C3833),
    danger: Color(0xFFFF8A80),
    completedFg: Color(0xFF6FD39C),
    completedBg: Color(0xFF173A28),
    pendingFg: Color(0xFFF2C063),
    pendingBg: Color(0xFF3A2E12),
    missedFg: Color(0xFFFF8A80),
    missedBg: Color(0xFF3D1A18),
    lateFg: Color(0xFFB4A6FF),
    lateBg: Color(0xFF2A2448),
  );

  /// Foreground color for [status] following the constitution status table.
  ///
  /// `available` and `unread` deliberately resolve to the named tokens
  /// ([primary]/[primaryContainer] and [inkMuted]/[surfaceMuted]).
  Color statusFg(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.completed:
        return completedFg;
      case AssignmentStatus.pending:
        return pendingFg;
      case AssignmentStatus.missed:
        return missedFg;
      case AssignmentStatus.late:
        return lateFg;
      case AssignmentStatus.available:
        return primary;
      case AssignmentStatus.unread:
        return inkMuted;
    }
  }

  /// Background color for [status] following the constitution status table.
  Color statusBg(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.completed:
        return completedBg;
      case AssignmentStatus.pending:
        return pendingBg;
      case AssignmentStatus.missed:
        return missedBg;
      case AssignmentStatus.late:
        return lateBg;
      case AssignmentStatus.available:
        return primaryContainer;
      case AssignmentStatus.unread:
        return surfaceMuted;
    }
  }

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? ink,
    Color? inkMuted,
    Color? border,
    Color? danger,
    Color? completedFg,
    Color? completedBg,
    Color? pendingFg,
    Color? pendingBg,
    Color? missedFg,
    Color? missedBg,
    Color? lateFg,
    Color? lateBg,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      border: border ?? this.border,
      danger: danger ?? this.danger,
      completedFg: completedFg ?? this.completedFg,
      completedBg: completedBg ?? this.completedBg,
      pendingFg: pendingFg ?? this.pendingFg,
      pendingBg: pendingBg ?? this.pendingBg,
      missedFg: missedFg ?? this.missedFg,
      missedBg: missedBg ?? this.missedBg,
      lateFg: lateFg ?? this.lateFg,
      lateBg: lateBg ?? this.lateBg,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer:
          Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      completedFg: Color.lerp(completedFg, other.completedFg, t)!,
      completedBg: Color.lerp(completedBg, other.completedBg, t)!,
      pendingFg: Color.lerp(pendingFg, other.pendingFg, t)!,
      pendingBg: Color.lerp(pendingBg, other.pendingBg, t)!,
      missedFg: Color.lerp(missedFg, other.missedFg, t)!,
      missedBg: Color.lerp(missedBg, other.missedBg, t)!,
      lateFg: Color.lerp(lateFg, other.lateFg, t)!,
      lateBg: Color.lerp(lateBg, other.lateBg, t)!,
    );
  }
}
