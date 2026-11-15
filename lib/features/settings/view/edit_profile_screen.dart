import 'package:flutter/material.dart';

import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/widgets/app_card.dart';
import '../../../core/design_system/widgets/app_page_content.dart';
import '../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../core/design_system/widgets/app_text_field.dart';
import '../../../core/design_system/widgets/illustrated_avatar.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/localization/arabic_strings.dart';
import '../../../core/auth/session_gateway.dart';
import '../../quran_groups/data/repositories/groups_repository.dart';
import '../../profile/data/repositories/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.initialDisplayName,
    this.initialBio,
    this.repository,
    this.profileRepository,
  });

  final String? initialDisplayName;
  final String? initialBio;
  final GroupsRepository? repository;
  final ProfileRepository? profileRepository;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  String? _nameError;
  String? _bioError;
  bool _isSaving = false;
  String _originalName = '';
  String _originalBio = '';
  bool _edited = false;
  bool _nameTouched = false;
  bool _bioTouched = false;
  String _avatarKey = 'ornament';
  String _originalAvatarKey = 'ornament';
  bool _avatarTouched = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialDisplayName ?? '',
    );
    _bioController = TextEditingController(text: widget.initialBio ?? '');
    _originalName = _nameController.text.trim();
    _originalBio = _bioController.text.trim();
    _nameController.addListener(() {
      _nameTouched = true;
      _onChanged();
    });
    _bioController.addListener(() {
      _bioTouched = true;
      _onChanged();
    });
    if (widget.initialDisplayName == null || widget.initialBio == null) {
      _loadCurrentProfile();
    }
  }

  Future<void> _loadCurrentProfile() async {
    final profileRepo =
        widget.profileRepository ??
        (serviceLocator.isRegistered<ProfileRepository>()
            ? serviceLocator<ProfileRepository>()
            : null);
    final groupsRepo =
        widget.repository ??
        (serviceLocator.isRegistered<GroupsRepository>()
            ? serviceLocator<GroupsRepository>()
            : null);
    if (profileRepo != null) {
      final result = await profileRepo.getProfile();
      if (mounted) {
        result.when(
          success: (profile) {
            if (widget.initialDisplayName == null && !_nameTouched) {
              _originalName = profile.displayName.trim();
              _nameController.text = profile.displayName;
            }
            _originalAvatarKey = profile.avatarKey;
            if (!_avatarTouched) _avatarKey = profile.avatarKey;
            _onChanged();
          },
          failure: (_) {},
        );
      }
    }
    if (groupsRepo == null ||
        widget.initialBio != null ||
        !serviceLocator.isRegistered<SessionGateway>()) {
      return;
    }
    final userId = serviceLocator<SessionGateway>().currentUserId;
    if (userId == null) return;
    final groupsResult = await groupsRepo.getMyGroups();
    if (!mounted || _bioTouched) return;
    groupsResult.when(
      success: (overview) async {
        if (overview.groups.isEmpty) return;
        final profileResult = await groupsRepo.getMemberProfile(
          userId,
          overview.groups.first.groupId,
        );
        if (!mounted || _bioTouched) return;
        profileResult.when(
          success: (profile) {
            _originalBio = profile.bio?.trim() ?? '';
            _bioController.text = profile.bio ?? '';
          },
          failure: (_) {},
        );
      },
      failure: (_) {},
    );
  }

  void _onChanged() {
    final edited =
        _nameController.text.trim() != _originalName ||
        _bioController.text.trim() != _originalBio ||
        _avatarKey != _originalAvatarKey;
    if (edited != _edited && mounted) setState(() => _edited = edited);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    String? nameError;
    String? bioError;

    if (name.length < 2 || name.length > 50) {
      nameError = ArabicStrings.invalidDisplayName;
    }

    if (bio.length > 120) {
      bioError = ArabicStrings.invalidBio;
    }

    setState(() {
      _nameError = nameError;
      _bioError = bioError;
    });

    return nameError == null && bioError == null;
  }

  Future<void> _onSave() async {
    if (!_validate()) return;

    setState(() => _isSaving = true);
    final repo = widget.repository ?? serviceLocator<GroupsRepository>();
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    final result = await repo.updateMyProfile(
      name,
      bio: bio.isEmpty ? null : bio,
      avatarKey: _avatarKey,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.when(
      success: (_) {
        AppSnackBar.show(context, ArabicStrings.profileUpdated);
        Navigator.of(context).pop(true);
      },
      failure: (f) {
        AppSnackBar.show(context, ArabicStrings.authError(f.code));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ArabicStrings.editProfile)),
      body: AppPageContent(
        child: SingleChildScrollView(
          padding: AppSpacing.screenContent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: AppSpacing.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      ArabicStrings.avatarPickerTitle,
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final option in const [
                          ('ornament', ArabicStrings.avatarOrnament),
                          ('man_kufi', ArabicStrings.avatarManKufi),
                          ('woman_hijab', ArabicStrings.avatarWomanHijab),
                        ])
                          SizedBox(
                            width: 92,
                            child: Semantics(
                              button: true,
                              selected: _avatarKey == option.$1,
                              label: option.$2,
                              child: InkWell(
                                borderRadius: AppRadius.mdBR,
                                onTap: () {
                                  _avatarTouched = true;
                                  setState(() {
                                    _avatarKey = option.$1;
                                    _edited =
                                        _nameController.text.trim() !=
                                            _originalName ||
                                        _bioController.text.trim() !=
                                            _originalBio ||
                                        _avatarKey != _originalAvatarKey;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  child: Column(
                                    children: [
                                      IllustratedAvatar(
                                        avatarKey: option.$1,
                                        size: 56,
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        option.$2,
                                        textAlign: TextAlign.center,
                                        style: AppTypography.caption,
                                      ),
                                      if (_avatarKey == option.$1)
                                        const Icon(
                                          Icons.check_circle,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: ArabicStrings.displayName,
                      hint: ArabicStrings.displayNameHint,
                      prefixIcon: Icons.badge_outlined,
                      controller: _nameController,
                      errorText: _nameError,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: ArabicStrings.bio,
                      hint: ArabicStrings.bioHint,
                      prefixIcon: Icons.edit_note_outlined,
                      controller: _bioController,
                      errorText: _bioError,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: ArabicStrings.saveChanges,
                icon: const Icon(Icons.check),
                variant: AppButtonVariant.primary,
                expanded: true,
                loading: _isSaving,
                onPressed: _isSaving || !_edited ? null : _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
