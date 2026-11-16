import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../di/service_locator.dart';
import '../../localization/arabic_formatting.dart';
import '../../localization/arabic_numerals.dart';
import '../../localization/arabic_strings.dart';
import '../../quran/mushaf/mushaf_repository.dart';
import '../../quran/quran_metadata_repository.dart';
import '../../../features/mushaf/data/reader_storage.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Quiet shortcut to the last locally saved Mushaf page.
class ContinueReadingCard extends StatefulWidget {
  const ContinueReadingCard({
    super.key,
    required this.repository,
    required this.metadata,
    required this.onOpenPage,
  });

  final MushafRepository repository;
  final QuranMetadataRepository? metadata;
  final ValueChanged<int> onOpenPage;

  @override
  State<ContinueReadingCard> createState() => _ContinueReadingCardState();
}

class _ContinueReadingCardState extends State<ContinueReadingCard> {
  late Future<int?> _lastPage = _load();
  StreamSubscription<int>? _positionChanges;

  @override
  void initState() {
    super.initState();
    _positionChanges = ReaderStorage.positionChanges.listen((_) {
      if (mounted) {
        setState(() {
          _lastPage = _load();
        });
      }
    });
  }

  @override
  void dispose() {
    _positionChanges?.cancel();
    super.dispose();
  }

  Future<int?> _load() async {
    if (!serviceLocator.isRegistered<ReaderStorage>()) return null;
    try {
      return await serviceLocator<ReaderStorage>().lastPage();
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return FutureBuilder<int?>(
      future: _lastPage,
      builder: (context, snapshot) {
        final page = snapshot.data;
        if (page == null) return const SizedBox.shrink();
        final mushafPage = widget.repository.page(page);
        String? surah;
        try {
          surah = widget.metadata?.suraName(mushafPage.firstSurah);
        } on Object {
          surah = null;
        }
        final isolatedPage = ArabicFormatting.isolate(
          ArabicNumerals.format(page),
        );
        final subtitle = surah == null
            ? '${ArabicStrings.pageNumberLabel} $isolatedPage'
            : '${ArabicStrings.surahWord} $surah، ${ArabicStrings.pageNumberLabel} $isolatedPage';
        return Material(
          color: colors.primaryContainer,
          borderRadius: AppRadius.lgBR,
          child: InkWell(
            borderRadius: AppRadius.lgBR,
            onTap: () => widget.onOpenPage(page),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ArabicStrings.continueReadingTitle,
                          style: AppTypography.title.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onPrimaryContainer,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
