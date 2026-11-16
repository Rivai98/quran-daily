import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/quran/mushaf/mushaf_models.dart';

List<List<MushafAyah>> groupAyahs(List<MushafAyah> ayahs) {
  final segments = <List<MushafAyah>>[];
  for (final ayah in ayahs) {
    if (segments.isEmpty || segments.last.last.ref.surah != ayah.ref.surah) {
      segments.add(<MushafAyah>[ayah]);
    } else {
      segments.last.add(ayah);
    }
  }
  return segments;
}

class AyahFlowParagraph extends StatefulWidget {
  const AyahFlowParagraph({
    super.key,
    required this.ayahs,
    required this.startAyah,
    required this.endAyah,
    required this.textScale,
    required this.onLongPress,
    this.anchorKey,
  });

  final List<MushafAyah> ayahs;
  final AyahRef? startAyah;
  final AyahRef? endAyah;
  final double textScale;
  final ValueChanged<MushafAyah> onLongPress;
  final Key? anchorKey;

  @override
  State<AyahFlowParagraph> createState() => _AyahFlowParagraphState();
}

class _AyahFlowParagraphState extends State<AyahFlowParagraph> {
  final List<GestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final colors = Theme.of(context).extension<AppColors>()!;
    final quranStyle = AppTypography.quranLabel.copyWith(
      fontFamily: 'KfgqpcHafs',
      color: colors.ink,
    );
    final spans = <InlineSpan>[];
    for (final ayah in widget.ayahs) {
      final highlighted =
          ayah.ref == widget.startAyah || ayah.ref == widget.endAyah;
      final recognizer = LongPressGestureRecognizer()
        ..onLongPress = () => widget.onLongPress(ayah);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: ayah.text,
          recognizer: recognizer,
          style: quranStyle.copyWith(
            backgroundColor: highlighted
                ? colors.primaryContainer.withValues(alpha: 0.5)
                : null,
          ),
          children: [const TextSpan(text: ' ')],
        ),
      );
    }

    final paragraph = RichText(
      key: ValueKey('mushaf-surah-segment-${widget.ayahs.first.ref.surah}'),
      text: TextSpan(style: quranStyle, children: spans),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.linear(
        widget.textScale * MediaQuery.textScalerOf(context).scale(1),
      ),
    );
    return widget.anchorKey == null
        ? paragraph
        : KeyedSubtree(key: widget.anchorKey, child: paragraph);
  }
}
