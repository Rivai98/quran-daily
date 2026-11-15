import 'package:flutter/material.dart';

import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_strings.dart';
import '../../../core/quran/mushaf/mushaf_repository.dart';

class MushafIndexScreen extends StatefulWidget {
  const MushafIndexScreen({
    super.key,
    required this.repository,
    required this.onOpenPage,
  });

  final MushafRepository repository;
  final ValueChanged<int> onOpenPage;

  @override
  State<MushafIndexScreen> createState() => _MushafIndexScreenState();
}

class _MushafIndexScreenState extends State<MushafIndexScreen> {
  final _search = TextEditingController();
  final _pageSearch = TextEditingController();
  String _query = '';

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
              _rows(
                widget.repository.juzIndex().map(
                  (e) => (
                    label:
                        '${ArabicStrings.juzLabel} ${ArabicNumerals.format(e.juz)}',
                    page: e.startPage,
                  ),
                ),
              ),
              _rows(
                widget.repository.hizbIndex().map(
                  (e) => (
                    label:
                        '${ArabicStrings.portionUnitHizb} ${ArabicNumerals.format(e.hizb)}',
                    page: e.startPage,
                  ),
                ),
              ),
              _pages(),
            ],
          );
        },
      ),
    ),
  );

  Widget _surahs() {
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
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final surah = filtered[index];
              return ListTile(
                title: Text(surah.name, style: AppTypography.body),
                subtitle: Text(
                  '${ArabicNumerals.format(surah.ayahs)} · ${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(surah.startPage)}',
                  style: AppTypography.caption,
                ),
                onTap: () => widget.onOpenPage(surah.startPage),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _rows(Iterable<({String label, int page})> rows) => ListView(
    children: [
      for (final row in rows)
        ListTile(
          title: Text(row.label, style: AppTypography.body),
          onTap: () => widget.onOpenPage(row.page),
        ),
    ],
  );

  Widget _pages() => Column(
    children: [
      Padding(
        padding: AppSpacing.screen,
        child: TextField(
          controller: _pageSearch,
          keyboardType: TextInputType.number,
          onSubmitted: (value) {
            final latin = String.fromCharCodes(
              value.runes.map((rune) {
                if (rune >= 0x0660 && rune <= 0x0669) return rune - 0x0660 + 48;
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
        child: _rows(
          Iterable<int>.generate(widget.repository.pageCount, (i) => i + 1).map(
            (page) => (
              label:
                  '${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(page)}',
              page: page,
            ),
          ),
        ),
      ),
    ],
  );
}
