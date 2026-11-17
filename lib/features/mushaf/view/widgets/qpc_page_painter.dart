import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/localization/arabic_strings.dart';
import '../../../../core/quran/mushaf/mushaf_models.dart';
import '../../../../core/quran/mushaf/qpc_v2_repository.dart';
import 'qpc_page_layout.dart';

class QpcPagePainter extends CustomPainter {
  QpcPagePainter({
    required this.layout,
    required this.colors,
    required this.startAyah,
    required this.endAyah,
    required this.onLongPress,
    required this.surahName,
  });

  final QpcPageLayout layout;
  final AppColors colors;
  final AyahRef? startAyah;
  final AyahRef? endAyah;
  final ValueChanged<QpcWord> onLongPress;
  final String Function(int) surahName;

  bool _highlighted(QpcWord word) =>
      (startAyah?.surah == word.surah && startAyah?.ayah == word.ayah) ||
      (endAyah?.surah == word.surah && endAyah?.ayah == word.ayah);

  @override
  void paint(Canvas canvas, Size size) {
    final highlight = Paint()
      ..color = colors.primaryContainer.withValues(alpha: 0.55);
    for (final painted in layout.words) {
      canvas.save();
      canvas.translate(painted.rect.left, painted.rect.top);
      canvas.scale(painted.scale);
      if (_highlighted(painted.word)) {
        canvas.drawRRect(
          AppRadius.smBR.toRRect(Offset.zero & painted.painter.size),
          highlight,
        );
      }
      painted.painter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (_) => [
        for (var i = 0; i < layout.words.length; i++)
          CustomPainterSemantics(
            key: ValueKey((i, layout.words[i].word.location)),
            rect: layout.words[i].rect,
            properties: SemanticsProperties(
              label: layout.words[i].word.text,
              textDirection: TextDirection.rtl,
              sortKey: OrdinalSortKey(layout.words[i].readingOrder.toDouble()),
              onLongPress: () => onLongPress(layout.words[i].word),
            ),
          ),
        for (var i = 0; i < layout.titles.length; i++)
          CustomPainterSemantics(
            key: ValueKey(('title', i)),
            rect: layout.titles[i].rect,
            properties: SemanticsProperties(
              label:
                  '${ArabicStrings.surahWord} ${surahName(layout.titles[i].surah)}',
              textDirection: TextDirection.rtl,
              header: true,
              sortKey: OrdinalSortKey(layout.titles[i].readingOrder.toDouble()),
            ),
          ),
      ];

  @override
  bool shouldRepaint(QpcPagePainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.startAyah != startAyah ||
      oldDelegate.endAyah != endAyah ||
      oldDelegate.colors != colors;

  @override
  bool shouldRebuildSemantics(QpcPagePainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.onLongPress != onLongPress ||
      oldDelegate.surahName != surahName;
}
