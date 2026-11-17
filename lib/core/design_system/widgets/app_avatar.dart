import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/group_photo_cubit.dart';

import 'package:material_ui/material_ui.dart';

import '../../localization/arabic_initials.dart';
import '../../di/service_locator.dart';
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
class GroupAvatar extends StatefulWidget {
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
  State<GroupAvatar> createState() => _GroupAvatarState();
}

class _GroupAvatarState extends State<GroupAvatar> {
  late final GroupPhotoCubit _photo =
      serviceLocator.isRegistered<GroupPhotoCubit>()
      ? serviceLocator<GroupPhotoCubit>()
      : GroupPhotoCubit();
  double get size => widget.size;

  @override
  void initState() {
    super.initState();
    _photo.show(bytes: widget.photoBytes, path: widget.photoPath);
  }

  @override
  void didUpdateWidget(covariant GroupAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.photoBytes, oldWidget.photoBytes) ||
        widget.photoPath != oldWidget.photoPath) {
      _photo.show(bytes: widget.photoBytes, path: widget.photoPath);
    }
  }

  @override
  void dispose() {
    _photo.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final borderRadius = BorderRadius.circular(widget.radius ?? AppRadius.md);
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return BlocProvider.value(
      value: _photo,
      child: BlocBuilder<GroupPhotoCubit, GroupPhotoState>(
        builder: (context, state) {
          final bytes = state.bytes;
          if (bytes == null || bytes.isEmpty) {
            return _buildGeneratedAvatar(
              colors,
              borderRadius,
              groupInitials(widget.name),
            );
          }
          return ClipRRect(
            borderRadius: borderRadius,
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              cacheWidth: pixels,
              cacheHeight: pixels,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
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
