import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../localization/arabic_initials.dart';
import '../../errors/result.dart';
import '../../di/service_locator.dart';
import '../../../features/quran_groups/data/repositories/groups_repository.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_typography.dart';
import 'islamic_ornament.dart';
import 'illustrated_avatar.dart';

/// User initials avatar (Constitution Principle VI & Spec 007).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.initials,
    this.displayName,
    this.size = 36,
    this.isVacant = false,
    this.avatarKey = 'ornament',
  });

  final String? initials;
  final String? displayName;
  final double size;
  final bool isVacant;
  final String avatarKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    if (isVacant) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.event_seat_rounded,
            size: size * 0.55,
            color: colors.inkMuted,
          ),
        ),
      );
    }

    return IllustratedAvatar(avatarKey: avatarKey, size: size);
  }
}

/// Group avatar: photo if available, or generated avatar (initials over geometric ornament, T019).
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({
    super.key,
    required this.name,
    this.photoBytes,
    this.photoPath,
    this.size = 40,
    this.radius,
  });

  final String name;
  final List<int>? photoBytes;
  final String? photoPath;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final borderRadius = BorderRadius.circular(radius ?? AppRadius.md);

    if (photoBytes != null && photoBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.memory(
          Uint8List.fromList(photoBytes!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final initials = groupInitials(name);

    if (photoPath != null &&
        photoPath!.isNotEmpty &&
        serviceLocator.isRegistered<GroupsRepository>()) {
      return FutureBuilder<Result<List<int>>>(
        future: serviceLocator<GroupsRepository>().getGroupPhotoBytes(
          photoPath!,
        ),
        builder: (context, snapshot) {
          final bytes = snapshot.data?.when(
            success: (b) => b,
            failure: (_) => null,
          );
          if (bytes != null && bytes.isNotEmpty) {
            return ClipRRect(
              borderRadius: borderRadius,
              child: Image.memory(
                Uint8List.fromList(bytes),
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            );
          }
          return _buildGeneratedAvatar(colors, borderRadius, initials);
        },
      );
    }

    return _buildGeneratedAvatar(colors, borderRadius, initials);
  }

  Widget _buildGeneratedAvatar(
    AppColors colors,
    BorderRadius borderRadius,
    String initials,
  ) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: size,
        height: size,
        color: colors.primaryContainer,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: GirihPainter(colors.accent.withValues(alpha: 0.18)),
              ),
            ),
            Center(
              child: Text(
                initials,
                style: AppTypography.label.copyWith(
                  color: colors.onPrimaryContainer,
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation('wght', 700)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
