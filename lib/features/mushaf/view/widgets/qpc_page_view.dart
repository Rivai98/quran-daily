import 'package:material_ui/material_ui.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/quran/mushaf/mushaf_models.dart';
import '../../../../core/quran/mushaf/qpc_v2_repository.dart';
import 'surah_title_band.dart';

class QpcPageData {
  const QpcPageData(this.lines, this.family, this.basmalaFamily, this.basmala);
  final List<QpcLine> lines;
  final String family;
  final String? basmalaFamily;
  final List<QpcWord> basmala;
}

/// One printed Madinah Mushaf page: the 15 lines of the KFGQPC V2 layout, each
/// line drawn word by word in that page's own verified font and justified to
/// the full width, like the printed page.
class QpcPageView extends StatefulWidget {
  const QpcPageView({
    super.key,
    required this.pageNumber,
    required this.layout,
    required this.fonts,
    required this.startAyah,
    required this.endAyah,
    required this.onLongPress,
    required this.surahName,
  });

  final int pageNumber;
  final QpcV2Repository layout;
  final QpcFontManager fonts;
  final AyahRef? startAyah;
  final AyahRef? endAyah;
  final ValueChanged<QpcWord> onLongPress;
  final String Function(int) surahName;

  @override
  State<QpcPageView> createState() => _QpcPageViewState();
}

class _QpcPageViewState extends State<QpcPageView>
    with AutomaticKeepAliveClientMixin {
  late Future<QpcPageData> _data;
  QpcPageData? _syncData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _syncData = _tryLoadSync();
    _data = _syncData != null ? Future.value(_syncData) : _load();
  }

  QpcPageData? _tryLoadSync() {
    try {
      if (!widget.layout.isLoaded || !widget.fonts.isLoaded(widget.pageNumber)) {
        return null;
      }
      final lines = widget.layout.linesForPage(widget.pageNumber);
      final hasBasmallah =
          lines.any((line) => line.lineType == QpcLineType.basmallah);
      if (hasBasmallah && !widget.fonts.isLoaded(1)) {
        return null;
      }
      final family = 'qpcv2_p${widget.pageNumber}';
      final basmalaFamily = hasBasmallah ? 'qpcv2_p1' : null;
      final basmala =
          hasBasmallah ? widget.layout.basmallahWords : const <QpcWord>[];
      return QpcPageData(lines, family, basmalaFamily, basmala);
    } catch (_) {
      return null;
    }
  }

  Future<QpcPageData> _load() async {
    try {
      await widget.layout.load();
      final lines = widget.layout.linesForPage(widget.pageNumber);
      final family = await widget.fonts.ensureLoaded(widget.pageNumber);
      String? basmalaFamily;
      var basmala = const <QpcWord>[];
      if (lines.any((line) => line.lineType == QpcLineType.basmallah)) {
        // The basmala glyphs are the words of 1:1, encoded for page 1's font.
        basmalaFamily = await widget.fonts.ensureLoaded(1);
        basmala = widget.layout.basmallahWords;
      }
      final result = QpcPageData(lines, family, basmalaFamily, basmala);
      if (mounted) setState(() => _syncData = result);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).extension<AppColors>()!;
    if (_syncData != null) {
      return _QpcPageBody(
        data: _syncData!,
        startAyah: widget.startAyah,
        endAyah: widget.endAyah,
        onLongPress: widget.onLongPress,
        surahName: widget.surahName,
      );
    }
    return FutureBuilder<QpcPageData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, color: colors.inkMuted),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'تعذّر تجهيز الصفحة. تحقّق من الاتصال لتنزيلها أول مرة.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: colors.inkMuted),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _data = _load()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'جارٍ تجهيز الصفحة',
                  style: AppTypography.caption.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          );
        }
        return _QpcPageBody(
          data: data,
          startAyah: widget.startAyah,
          endAyah: widget.endAyah,
          onLongPress: widget.onLongPress,
          surahName: widget.surahName,
        );
      },
    );
  }
}

class _QpcPageBody extends StatelessWidget {
  const _QpcPageBody({
    required this.data,
    required this.startAyah,
    required this.endAyah,
    required this.onLongPress,
    required this.surahName,
  });

  final QpcPageData data;
  final AyahRef? startAyah;
  final AyahRef? endAyah;
  final ValueChanged<QpcWord> onLongPress;
  final String Function(int) surahName;

  static const _measureSize = 100.0;
  static final Map<String, double> _naturalWidthCache = {};

  double _naturalWidth(List<QpcWord> words, String family) {
    final painter = TextPainter(
      textDirection: TextDirection.rtl,
      maxLines: 1,
      text: TextSpan(
        text: words.map((w) => w.text).join(' '),
        style: AppTypography.mushafPage(fontFamily: family, size: _measureSize),
      ),
    )..layout();
    return painter.width;
  }

  bool _highlighted(QpcWord word) =>
      (startAyah?.surah == word.surah && startAyah?.ayah == word.ayah) ||
      (endAyah?.surah == word.surah && endAyah?.ayah == word.ayah);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontal = AppSpacing.sm;
        final width = constraints.maxWidth - 2 * horizontal;
        final lineHeight = constraints.maxHeight / 15;
        final maxNatural = _naturalWidthCache.putIfAbsent(data.family, () {
          var widest = 0.0;
          for (final line in data.lines) {
            if (line.lineType == QpcLineType.ayah) {
              final w = _naturalWidth(line.words, data.family);
              if (w > widest) widest = w;
            }
          }
          return widest;
        });
        final allCentered = data.lines
            .where((l) => l.lineType == QpcLineType.ayah)
            .every((l) => l.isCentered);
        final blockWidth = allCentered ? width * 0.82 : width;
        final byWidth = maxNatural <= 0
            ? lineHeight * 0.6
            : _measureSize * blockWidth / maxNatural;
        final fontSize = byWidth.clamp(8.0, lineHeight * 0.7).toDouble();
        final gap = fontSize * 0.25;

        Widget wordWidget(QpcWord word, String family) {
          final text = Text(
            word.text,
            textDirection: TextDirection.rtl,
            style: AppTypography.mushafPage(
              fontFamily: family,
              size: fontSize,
              color: colors.ink,
            ),
          );
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () => onLongPress(word),
            child: _highlighted(word)
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: AppRadius.smBR,
                    ),
                    child: text,
                  )
                : text,
          );
        }

        Widget centeredRow(List<Widget> children) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                children[i],
              ],
            ],
          ),
        );

        Widget lineWidget(QpcLine line) {
          switch (line.lineType) {
            case QpcLineType.surahName:
              return SurahTitleBand(
                surahName: surahName(line.surahNumber ?? 1),
              );
            case QpcLineType.blank:
              return const SizedBox.shrink();
            case QpcLineType.basmallah:
              final family = data.basmalaFamily ?? data.family;
              return centeredRow([
                for (final word in data.basmala) wordWidget(word, family),
              ]);
            case QpcLineType.ayah:
              final children = [
                for (final word in line.words) wordWidget(word, data.family),
              ];
              if (line.isCentered) return centeredRow(children);
              return Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: children,
              );
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontal),
          child: Column(
            mainAxisAlignment: allCentered
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              for (final line in data.lines)
                if (!(allCentered && line.lineType == QpcLineType.blank))
                  SizedBox(
                    height: lineHeight,
                    width: width,
                    child: line.lineType == QpcLineType.surahName
                        ? FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: width,
                              height: AppSpacing.xxl + 2 * AppSpacing.sm,
                              child: lineWidget(line),
                            ),
                          )
                        : Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: width,
                                child: lineWidget(line),
                              ),
                            ),
                          ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
