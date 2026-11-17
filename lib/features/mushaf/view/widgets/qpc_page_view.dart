import 'package:material_ui/material_ui.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/quran/mushaf/mushaf_models.dart';
import '../../../../core/quran/mushaf/qpc_v2_repository.dart';
import 'qpc_page_layout.dart';
import 'qpc_page_painter.dart';
import 'surah_title_band.dart';

export 'qpc_page_layout.dart' show QpcPageData;

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
      if (!widget.layout.isLoaded ||
          !widget.fonts.isLoaded(widget.pageNumber)) {
        return null;
      }
      final lines = widget.layout.linesForPage(widget.pageNumber);
      final hasBasmallah = lines.any(
        (line) => line.lineType == QpcLineType.basmallah,
      );
      if (hasBasmallah && !widget.fonts.isLoaded(1)) {
        return null;
      }
      final family = 'qpcv2_p${widget.pageNumber}';
      final basmalaFamily = hasBasmallah ? 'qpcv2_p1' : null;
      final basmala = hasBasmallah
          ? widget.layout.basmallahWords
          : const <QpcWord>[];
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

class _QpcPageBody extends StatefulWidget {
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

  @override
  State<_QpcPageBody> createState() => _QpcPageBodyState();
}

class _QpcPageBodyState extends State<_QpcPageBody> {
  QpcPageLayout? _layout;

  @override
  void dispose() {
    _layout?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final inheritedStyle = DefaultTextStyle.of(context).style
        .copyWith(color: colors.ink);
    final scaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.maybeLocaleOf(context);
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spec = (
            data: widget.data,
            size: constraints.biggest,
            inheritedStyle: inheritedStyle,
            textScaler: scaler,
            locale: locale,
          );
          if (_layout?.spec != spec) {
            _layout?.dispose();
            _layout = QpcPageLayout(spec);
          }
          final layout = _layout!;
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onLongPressStart: (details) {
                  final word = layout.wordAt(details.localPosition);
                  if (word != null) widget.onLongPress(word);
                },
                child: CustomPaint(
                  key: const ValueKey('qpc-page-canvas'),
                  painter: QpcPagePainter(
                    layout: layout,
                    colors: colors,
                    startAyah: widget.startAyah,
                    endAyah: widget.endAyah,
                    onLongPress: widget.onLongPress,
                    surahName: widget.surahName,
                  ),
                ),
              ),
              for (final title in layout.titles)
                Positioned.fromRect(
                  rect: title.rect,
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: title.rect.width,
                        height: AppSpacing.xxl + 2 * AppSpacing.sm,
                        child: SurahTitleBand(
                          surahName: widget.surahName(title.surah),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
