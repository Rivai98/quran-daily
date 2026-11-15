import 'package:flutter/material.dart';

import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/widgets/app_card.dart';
import '../../../core/design_system/widgets/app_page_content.dart';
import '../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../core/design_system/widgets/app_text_field.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/localization/arabic_strings.dart';
import '../../quran_groups/data/repositories/groups_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.initialDisplayName,
    this.initialBio,
    this.repository,
  });

  final String? initialDisplayName;
  final String? initialBio;
  final GroupsRepository? repository;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  String? _nameError;
  String? _bioError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialDisplayName ?? '');
    _bioController = TextEditingController(text: widget.initialBio ?? '');
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
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.when(
      success: (_) {
        AppSnackBar.show(context, ArabicStrings.profileUpdated);
        Navigator.of(context).pop(true);
      },
      failure: (f) {
        AppSnackBar.show(
          context,
          f.message.isNotEmpty ? f.message : ArabicStrings.operationFailed,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ArabicStrings.editProfile),
      ),
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
                onPressed: _isSaving ? null : _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
