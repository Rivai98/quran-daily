import 'qpc_page_layout.dart';

/// Owns one speculative layout. Displayed layouts transfer to their page body;
/// mounted entries only prevent duplicate preparation and never share ownership.
class QpcPageLayoutCache {
  QpcPageLayout? _prepared;
  QpcLayoutSpec? _viewport;
  final _mounted = <QpcPageLayout>{};
  bool _disposed = false;

  bool _sameViewport(QpcLayoutSpec first, QpcLayoutSpec second) =>
      first.size == second.size &&
      first.inheritedStyle == second.inheritedStyle &&
      first.textScaler == second.textScaler &&
      first.locale == second.locale;

  QpcLayoutSpec? specFor(QpcPageData data) {
    final viewport = _viewport;
    if (_disposed || viewport == null) return null;
    final spec = (
      data: data,
      size: viewport.size,
      inheritedStyle: viewport.inheritedStyle,
      textScaler: viewport.textScaler,
      locale: viewport.locale,
    );
    if (_prepared?.spec == spec || _mounted.any((page) => page.spec == spec)) {
      return null;
    }
    return spec;
  }

  /// Takes ownership even when a late preparation no longer fits the viewport.
  void store(QpcPageLayout layout) {
    final viewport = _viewport;
    if (_disposed ||
        viewport == null ||
        !_sameViewport(viewport, layout.spec)) {
      layout.dispose();
      return;
    }
    _prepared?.dispose();
    _prepared = layout;
  }

  QpcPageLayout acquire(QpcLayoutSpec spec) {
    assert(!_disposed);
    if (_viewport != null && !_sameViewport(_viewport!, spec)) {
      _prepared?.dispose();
      _prepared = null;
    }
    _viewport = spec;
    final prepared = _prepared?.spec == spec ? _prepared : null;
    if (prepared != null) _prepared = null;
    final displayed = prepared ?? QpcPageLayout(spec);
    _mounted.add(displayed);
    return displayed;
  }

  void release(QpcPageLayout layout) {
    _mounted.remove(layout);
    layout.dispose();
  }

  void dispose() {
    _disposed = true;
    _prepared?.dispose();
    _prepared = null;
    _mounted.clear();
    _viewport = null;
  }
}
