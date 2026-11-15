import 'package:flutter/material.dart';

import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/localization/arabic_numerals.dart';
import '../../../core/localization/arabic_strings.dart';
import '../data/reader_storage.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({
    super.key,
    required this.storage,
    required this.onOpenPage,
  });

  final ReaderStorage storage;
  final ValueChanged<int> onOpenPage;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late Future<List<ReaderBookmark>> _bookmarks = widget.storage.bookmarks();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(ArabicStrings.bookmarksTitle)),
    body: FutureBuilder<List<ReaderBookmark>>(
      future: _bookmarks,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? const <ReaderBookmark>[];
        if (items.isEmpty) {
          return Center(
            child: Text(
              ArabicStrings.bookmarksEmpty,
              style: AppTypography.body,
            ),
          );
        }
        return ListView.separated(
          padding: AppSpacing.screen,
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final bookmark = items[index];
            return ListTile(
              title: Text(
                '${ArabicStrings.pageNumberLabel} ${ArabicNumerals.format(bookmark.page)}',
                style: AppTypography.body,
              ),
              subtitle: bookmark.note == null
                  ? null
                  : Text(bookmark.note!, style: AppTypography.caption),
              onTap: () => widget.onOpenPage(bookmark.page),
              trailing: IconButton(
                tooltip: ArabicStrings.cancel,
                onPressed: () async {
                  await widget.storage.removeBookmark(bookmark.id);
                  if (mounted) {
                    setState(() => _bookmarks = widget.storage.bookmarks());
                  }
                },
                icon: const Icon(Icons.delete_outline),
              ),
            );
          },
        );
      },
    ),
  );
}

class MushafLicensesScreen extends StatelessWidget {
  const MushafLicensesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(ArabicStrings.mushafLicensesTitle)),
    body: ListView(
      padding: AppSpacing.screenContent,
      children: const [
        Text(ArabicStrings.kfgqpcAttribution),
        SizedBox(height: AppSpacing.md),
        Text(ArabicStrings.tanzilAttribution),
      ],
    ),
  );
}
