import 'package:supabase_flutter/supabase_flutter.dart';

import 'reader_storage.dart';

/// The server refused a write permanently (constraint or data error);
/// retrying the same payload can never succeed.
class MushafRemoteRejected implements Exception {
  const MushafRemoteRejected(this.reason);

  final String reason;

  @override
  String toString() => 'MushafRemoteRejected: $reason';
}

/// Remote side of last position and bookmarks (tables `reading_positions`
/// and `bookmarks`, owner-only RLS). Transient failures are rethrown as-is;
/// permanent rejections surface as [MushafRemoteRejected].
abstract interface class MushafRemoteDataSource {
  Future<void> upsertPosition({
    required String userId,
    required int page,
    required DateTime updatedAt,
  });
  Future<void> upsertBookmark({
    required String userId,
    required ReaderBookmark bookmark,
  });
  Future<void> deleteBookmark(String id);
  Future<RemoteReaderSnapshot> fetch(String userId);
}

class SupabaseMushafRemoteDataSource implements MushafRemoteDataSource {
  SupabaseMushafRemoteDataSource(this._client);

  final SupabaseClient Function() _client;

  @override
  Future<void> upsertPosition({
    required String userId,
    required int page,
    required DateTime updatedAt,
  }) => _guard(
    () => _client().from('reading_positions').upsert({
      'user_id': userId,
      'last_page': page,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    }),
  );

  @override
  Future<void> upsertBookmark({
    required String userId,
    required ReaderBookmark bookmark,
  }) => _guard(
    () => _client().from('bookmarks').upsert({
      'id': bookmark.id,
      'user_id': userId,
      'surah': bookmark.surah,
      'ayah': bookmark.ayah,
      'page': bookmark.page,
      'note': bookmark.note,
      if (bookmark.createdAt != null)
        'created_at': bookmark.createdAt!.toUtc().toIso8601String(),
    }),
  );

  @override
  Future<void> deleteBookmark(String id) =>
      _guard(() => _client().from('bookmarks').delete().eq('id', id));

  @override
  Future<RemoteReaderSnapshot> fetch(String userId) async {
    final client = _client();
    final position = await client
        .from('reading_positions')
        .select('last_page, updated_at')
        .eq('user_id', userId)
        .maybeSingle();
    final rows = await client
        .from('bookmarks')
        .select('id, surah, ayah, page, note, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return RemoteReaderSnapshot(
      position: position == null
          ? null
          : RemoteReadingPosition(
              page: position['last_page'] as int,
              updatedAt: DateTime.parse(position['updated_at'] as String),
            ),
      bookmarks: rows
          .map(
            (row) => ReaderBookmark(
              id: row['id'] as String,
              page: row['page'] as int,
              surah: row['surah'] as int?,
              ayah: row['ayah'] as int?,
              note: row['note'] as String?,
              createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> _guard(Future<Object?> Function() write) async {
    try {
      await write();
    } on PostgrestException catch (error) {
      final code = error.code ?? '';
      // SQLSTATE class 22 (data exception) and 23 (integrity violation).
      if (code.startsWith('22') || code.startsWith('23')) {
        throw MushafRemoteRejected('${error.code}: ${error.message}');
      }
      rethrow;
    }
  }
}
