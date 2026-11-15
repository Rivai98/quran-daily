import 'package:flutter/material.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_strings.dart';
import '../../../core/quran/mushaf/mushaf_repository.dart';
import '../../../core/quran/portion_unit.dart';
import '../../../core/quran/quran_metadata_repository.dart';

class MushafIndexScreen extends StatefulWidget {
  const MushafIndexScreen({
    super.key,
    required this.repository,
    required this.onOpenPage,
    this.metadata,
  });

  final MushafRepository repository;
  final ValueChanged<int> onOpenPage;
  final QuranMetadataRepository? metadata;

  @override
  State<MushafIndexScreen> createState() => _MushafIndexScreenState();
}

class _MushafIndexScreenState extends State<MushafIndexScreen> {
  final _search = TextEditingController();
  final _pageSearch = TextEditingController();
  String _query = '';
  QuranMetadataRepository? _metadata;

  @override
  void initState() {
    super.initState();
    _metadata = widget.metadata ??
        (serviceLocator.isRegistered<QuranMetadataRepository>()
            ? serviceLocator<QuranMetadataRepository>()
            : null);
    _metadata?.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _pageSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        title: const Text(ArabicStrings.mushafIndexAction),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: ArabicStrings.surahsTab),
            Tab(text: ArabicStrings.ajzaaTab),
            Tab(text: ArabicStrings.ahzabTab),
            Tab(text: ArabicStrings.pagesTab),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: widget.repository.load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                ArabicStrings.mushafLoadError,
                style: AppTypography.body,
              ),
            );
          }
          return TabBarView(
            children: [
              _surahs(),
              _juzList(),
              _hizbList(),
              _pages(),
            ],
          );
        },
      ),
    ),
  );

  Widget _indexBadge(BuildContext context, int number) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: Text(
        ArabicNumerals.format(number),
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.primary,
        ),
      ),
    );
  }

  Widget _surahs() {
    final colors = Theme.of(context).extension<AppColors>()!;
    final all = widget.repository.surahIndex();
    final filtered = all.where((item) => item.name.contains(_query)).toList();
    return Column(
      children: [
        Padding(
          padding: AppSpacing.screen,
          child: TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: const InputDecoration(
              hintText: ArabicStrings.surahSearchHint,
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            itemCount: filtered.length,
            separatorBuilder: (context, index) =>
                Divider(color: colors.border, height: 1),
            itemBuilder: (context, index) {
              final surah = filtered[index];
              return ListTile(
                leading: _indexBadge(context, surah.surah),
                title: Text(
                  surah.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  ArabicStrings.surahAyahMeta(surah.startPage, surah.ayahs),
                  style: AppTypography.caption.copyWith(color: colors.inkMuted),
                ),
                trailing: Icon(
                  Icons.chevron_left,
                  color: colors.inkMuted,
                  size: 20,
                ),
                onTap: () => widget.onOpenPage(surah.startPage),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _juzList() {
    final colors = Theme.of(context).extension<AppColors>()!;
    final rows = widget.repository.juzIndex();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: rows.length,
      separatorBuilder: (context, index) =>
          Divider(color: colors.border, height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];
        String? surahName;
        if (_metadata != null) {
          try {
            final startSura = _metadata!.juz(row.juz).startSura;
            surahName = _metadata!.suraName(startSura);
          } catch (_) {}
        }

        final subtitle = surahName != null
            ? ArabicStrings.juzHizbMeta(surahName, row.startPage)
            : '${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(row.startPage)}';

        return ListTile(
          leading: _indexBadge(context, row.juz),
          title: Text(
            '${ArabicStrings.juzLabel} ${ArabicNumerals.format(row.juz)}',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: colors.inkMuted),
          ),
          trailing: Icon(
            Icons.chevron_left,
            color: colors.inkMuted,
            size: 20,
          ),
          onTap: () => widget.onOpenPage(row.startPage),
        );
      },
    );
  }

  Widget _hizbList() {
    final colors = Theme.of(context).extension<AppColors>()!;
    final rows = widget.repository.hizbIndex();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: rows.length,
      separatorBuilder: (context, index) =>
          Divider(color: colors.border, height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];
        String? surahName;
        if (_metadata != null) {
          try {
            final portion = _metadata!.portion(PortionUnit.hizb, row.hizb);
            surahName = _metadata!.suraName(portion.startSura);
          } catch (_) {}
        }

        final subtitle = surahName != null
            ? ArabicStrings.juzHizbMeta(surahName, row.startPage)
            : '${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(row.startPage)}';

        return ListTile(
          leading: _indexBadge(context, row.hizb),
          title: Text(
            '${ArabicStrings.portionUnitHizb} ${ArabicNumerals.format(row.hizb)}',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: colors.inkMuted),
          ),
          trailing: Icon(
            Icons.chevron_left,
            color: colors.inkMuted,
            size: 20,
          ),
          onTap: () => widget.onOpenPage(row.startPage),
        );
      },
    );
  }

  Widget _pages() {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      children: [
        Padding(
          padding: AppSpacing.screen,
          child: TextField(
            controller: _pageSearch,
            keyboardType: TextInputType.number,
            onSubmitted: (value) {
              final latin = String.fromCharCodes(
                value.runes.map((rune) {
                  if (rune >= 0x0660 && rune <= 0x0669) {
                    return rune - 0x0660 + 48;
                  }
                  return rune;
                }),
              );
              final page = int.tryParse(latin);
              if (page != null &&
                  page >= 1 &&
                  page <= widget.repository.pageCount) {
                widget.onOpenPage(page);
              }
            },
            decoration: const InputDecoration(
              hintText: ArabicStrings.pageNumberLabel,
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            itemCount: widget.repository.pageCount,
            separatorBuilder: (context, index) =>
                Divider(color: colors.border, height: 1),
            itemBuilder: (context, index) {
              final page = index + 1;
              return ListTile(
                leading: _indexBadge(context, page),
                title: Text(
                  '${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(page)}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_left,
                  color: colors.inkMuted,
                  size: 20,
                ),
                onTap: () => widget.onOpenPage(page),
              );
            },
          ),
        ),
      ],
    );
  }
}
