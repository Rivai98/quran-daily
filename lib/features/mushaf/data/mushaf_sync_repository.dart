import 'dart:async';

import 'mushaf_remote_data_source.dart';
import 'reader_storage.dart';

/// Outcome of one sync pass.
class MushafSyncReport {
  const MushafSyncReport({
    this.pushed = 0,
    this.dropped = 0,
    this.pulled = false,
    this.skipped = false,
  });

  /// Queued operations the server accepted.
  final int pushed;

  /// Queued operations the server rejected permanently (removed locally).
  final int dropped;

  /// True when the server state was fetched and merged into the device.
  final bool pulled;

  /// True when no user was signed in or another pass was already running.
  final bool skipped;
}

/// Local-first sync for last position and bookmarks: pushes the device
/// queue (`mushaf_sync_queue`) in order, then pulls the server state.
/// Transient failures stop the pass and keep the queue for the next one.
class MushafSyncRepository {
  MushafSyncRepository({
    required MushafRemoteDataSource remote,
    required ReaderSyncStore Function(String userId) storeFor,
    required String? Function() currentUserId,
    Duration debounce = const Duration(seconds: 2),
  }) : _remote = remote,
       _storeFor = storeFor,
       _currentUserId = currentUserId,
       _debounce = debounce;

  static const positionUpsert = 'position_upsert';
  static const bookmarkUpsert = 'bookmark_upsert';
  static const bookmarkDelete = 'bookmark_delete';

  final MushafRemoteDataSource _remote;
  final ReaderSyncStore Function(String userId) _storeFor;
  final String? Function() _currentUserId;
  final Duration _debounce;
  Future<MushafSyncReport>? _running;
  Timer? _scheduled;

  /// Coalesces bursts of local writes (page turns) into one background pass.
  void schedule() {
    _scheduled?.cancel();
    _scheduled = Timer(_debounce, () => unawaited(_syncQuietly()));
  }

  /// Runs one push-then-pull pass; concurrent callers share the same pass.
  Future<MushafSyncReport> sync() {
    final running = _running;
    if (running != null) return running;
    final pass = _sync().whenComplete(() => _running = null);
    _running = pass;
    return pass;
  }

  void dispose() => _scheduled?.cancel();

  Future<void> _syncQuietly() async {
    try {
      await sync();
    } on Object {
      // Background sync retries on the next write, resume, or sign-in.
    }
  }

  Future<MushafSyncReport> _sync() async {
    final userId = _currentUserId();
    if (userId == null) return const MushafSyncReport(skipped: true);
    final store = _storeFor(userId);

    final pending = (await store.pendingSyncOperations())
        .where((op) => op.payload['user_id'] == userId)
        .toList(growable: false);
    // Only the newest position matters; older ones are superseded.
    final latestPosition = pending.lastWhereOrNull(
      (op) => op.operation == positionUpsert,
    );

    var pushed = 0;
    var dropped = 0;
    for (final op in pending) {
      if (op.operation == positionUpsert && op != latestPosition) {
        await store.markSyncOperationComplete(op.id);
        continue;
      }
      try {
        await _push(userId, op);
        pushed++;
      } on MushafRemoteRejected {
        dropped++;
      } on Object {
        return MushafSyncReport(pushed: pushed, dropped: dropped);
      }
      await store.markSyncOperationComplete(op.id);
    }

    final RemoteReaderSnapshot snapshot;
    try {
      snapshot = await _remote.fetch(userId);
    } on Object {
      return MushafSyncReport(pushed: pushed, dropped: dropped);
    }
    await store.applyRemote(snapshot);
    return MushafSyncReport(pushed: pushed, dropped: dropped, pulled: true);
  }

  Future<void> _push(String userId, ReaderSyncOperation op) {
    final payload = op.payload;
    switch (op.operation) {
      case positionUpsert:
        return _remote.upsertPosition(
          userId: userId,
          page: payload['page']! as int,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            payload['updated_at']! as int,
          ),
        );
      case bookmarkUpsert:
        return _remote.upsertBookmark(
          userId: userId,
          bookmark: ReaderBookmark(
            id: payload['id']! as String,
            page: payload['page']! as int,
            surah: payload['surah'] as int?,
            ayah: payload['ayah'] as int?,
            note: payload['note'] as String?,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              payload['created_at']! as int,
            ),
          ),
        );
      case bookmarkDelete:
        return _remote.deleteBookmark(payload['id']! as String);
      default:
        throw MushafRemoteRejected('unknown operation ${op.operation}');
    }
  }
}

/// [ReaderStorage] that schedules a background sync after each local write.
class SyncingReaderStorage implements ReaderStorage {
  SyncingReaderStorage(this._inner, {required void Function() onLocalChange})
    : _onLocalChange = onLocalChange;

  final ReaderStorage _inner;
  final void Function() _onLocalChange;

  @override
  Future<int?> lastPage() => _inner.lastPage();

  @override
  Future<List<ReaderBookmark>> bookmarks() => _inner.bookmarks();

  @override
  Future<void> savePage(int page) async {
    await _inner.savePage(page);
    _onLocalChange();
  }

  @override
  Future<void> addBookmark(ReaderBookmark bookmark) async {
    await _inner.addBookmark(bookmark);
    _onLocalChange();
  }

  @override
  Future<void> removeBookmark(String id) async {
    await _inner.removeBookmark(id);
    _onLocalChange();
  }

  @override
  Future<List<ReaderSyncOperation>> pendingSyncOperations() =>
      _inner.pendingSyncOperations();

  @override
  Future<void> markSyncOperationComplete(String id) =>
      _inner.markSyncOperationComplete(id);
}

extension<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}
