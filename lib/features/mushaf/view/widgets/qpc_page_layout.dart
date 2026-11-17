import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/quran/mushaf/qpc_v2_repository.dart';

class QpcPageData {
  const QpcPageData(this.lines, this.family, this.basmalaFamily, this.basmala);
  final List<QpcLine> lines;
  final String family;
  final String? basmalaFamily;
  final List<QpcWord> basmala;
}

/// Inputs that affect shaping. Highlights and callbacks never invalidate layout.
typedef QpcLayoutSpec = ({
  QpcPageData data,
  Size size,
  TextStyle inheritedStyle,
  TextScaler textScaler,
  Locale? locale,
});

class QpcPaintedWord {
  const QpcPaintedWord(this.word, this.painter, this.placement);

  final QpcWord word;
  final TextPainter painter;
  final ({Rect rect, double scale, int readingOrder}) placement;
  Rect get rect => placement.rect;
  double get scale => placement.scale;
  int get readingOrder => placement.readingOrder;
}

/// Owns native paragraphs until the page leaves its cache. Repaints and hit tests
/// use the same geometry; neither reshapes text nor constructs per-word widgets.
class QpcPageLayout {
  QpcPageLayout(this.spec) {
    _prepare();
  }

  final QpcLayoutSpec spec;
  final words = <QpcPaintedWord>[];
  final titles = <({int surah, Rect rect, int readingOrder})>[];
  int _nextReadingOrder = 0;
  static const _measureSize = 100.0;
  static final _naturalWidths = <String, double>{};

  QpcWord? wordAt(Offset position) {
    for (final painted in words) {
      if (painted.rect.contains(position)) return painted.word;
    }
    return null;
  }

  void dispose() {
    for (final word in words) {
      word.painter.dispose();
    }
  }

  double _widestLine() => _naturalWidths.putIfAbsent(spec.data.family, () {
    var widest = 0.0;
    for (final line in spec.data.lines) {
      if (line.lineType != QpcLineType.ayah) continue;
      final measurement = TextPainter(
        textDirection: TextDirection.rtl,
        text: TextSpan(
          text: line.words.map((word) => word.text).join(' '),
          style: AppTypography.mushafPage(
            fontFamily: spec.data.family,
            size: _measureSize,
          ),
        ),
      )..layout();
      widest = math.max(widest, measurement.width);
      measurement.dispose();
    }
    return widest;
  });

  void _prepare() {
    final width = math.max(0.0, spec.size.width - 2 * AppSpacing.sm);
    final lineHeight = spec.size.height / 15;
    if (width == 0 || lineHeight <= 0) return;
    final centered = spec.data.lines
        .where((line) => line.lineType == QpcLineType.ayah)
        .every((line) => line.isCentered);
    final widest = _widestLine();
    final blockWidth = centered ? width * 0.82 : width;
    final byWidth = widest <= 0
        ? lineHeight * 0.6
        : _measureSize * blockWidth / widest;
    final fontSize = byWidth.clamp(8.0, lineHeight * 0.7).toDouble();
    final visible = spec.data.lines
        .where((line) => !(centered && line.lineType == QpcLineType.blank))
        .toList(growable: false);
    var top = centered
        ? (spec.size.height - visible.length * lineHeight) / 2
        : 0.0;
    for (final line in visible) {
      final bounds = Rect.fromLTWH(AppSpacing.sm, top, width, lineHeight);
      _prepareLine(line, bounds, fontSize);
      top += lineHeight;
    }
  }

  void _prepareLine(QpcLine line, Rect bounds, double fontSize) {
    switch (line.lineType) {
      case QpcLineType.surahName:
        titles.add((
          surah: line.surahNumber ?? 1,
          rect: bounds,
          readingOrder: _nextReadingOrder++,
        ));
      case QpcLineType.blank:
        break;
      case QpcLineType.basmallah:
        _shapeLine(
          spec.data.basmala,
          spec.data.basmalaFamily ?? spec.data.family,
          (bounds: bounds, size: fontSize, centered: true),
        );
      case QpcLineType.ayah:
        _shapeLine(line.words, spec.data.family, (
          bounds: bounds,
          size: fontSize,
          centered: line.isCentered,
        ));
    }
  }

  void _shapeLine(
    List<QpcWord> source,
    String family,
    ({Rect bounds, double size, bool centered}) line,
  ) {
    if (source.isEmpty) return;
    final painters = [
      for (final word in source)
        TextPainter(
          text: TextSpan(
            text: word.text,
            style: spec.inheritedStyle.merge(
              AppTypography.mushafPage(fontFamily: family, size: line.size),
            ),
          ),
          textDirection: TextDirection.rtl,
          textScaler: spec.textScaler,
          locale: spec.locale,
        )..layout(),
    ];
    final height = painters.map((painter) => painter.height).reduce(math.max);
    final wordWidth = painters.fold(0.0, (sum, painter) => sum + painter.width);
    final geometry = _lineGeometry(line, (
      wordWidth: wordWidth,
      height: height,
      count: source.length,
    ));
    var end = geometry.origin.dx + geometry.width;
    for (var i = 0; i < source.length; i++) {
      final painter = painters[i];
      final width = painter.width * geometry.scale;
      end -= width;
      words.add(
        QpcPaintedWord(source[i], painter, (
          rect: Rect.fromLTWH(
            end,
            geometry.origin.dy + (height - painter.height) * geometry.scale / 2,
            width,
            painter.height * geometry.scale,
          ),
          scale: geometry.scale,
          readingOrder: _nextReadingOrder++,
        )),
      );
      end -= geometry.gap;
    }
  }

  ({Offset origin, double width, double gap, double scale}) _lineGeometry(
    ({Rect bounds, double size, bool centered}) line,
    ({double wordWidth, double height, int count}) row,
  ) {
    final bounds = line.bounds;
    final gap = line.centered ? line.size * 0.25 : 0.0;
    final naturalWidth = row.wordWidth + gap * (row.count - 1);
    final innerScale = line.centered
        ? math.min(1.0, bounds.width / naturalWidth)
        : math.min(1.0, bounds.width / row.wordWidth);
    // scaleDown loosens the inner box before constraining it: a short centered
    // row keeps its natural height even when its parent fills the page width.
    final innerHeight = line.centered ? row.height * innerScale : row.height;
    final outerScale = math.min(1.0, bounds.height / innerHeight);
    final scale = innerScale * outerScale;
    final width = line.centered
        ? naturalWidth * scale
        : bounds.width * outerScale;
    final spacing = line.centered
        ? gap * scale
        : row.count > 1
        ? math.max(0.0, (width - row.wordWidth * scale) / (row.count - 1))
        : 0.0;
    return (
      origin: Offset(
        bounds.center.dx - width / 2,
        bounds.center.dy - row.height * scale / 2,
      ),
      width: width,
      gap: spacing,
      scale: scale,
    );
  }
}
