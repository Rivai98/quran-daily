import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/auth/session_gateway.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/network/connectivity_service.dart';
import 'package:quran_daily/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:quran_daily/features/profile/data/sources/profile_local_data_source.dart';
import 'package:quran_daily/features/profile/data/sources/profile_remote_data_source.dart';

class _Remote extends Mock implements ProfileRemoteDataSource {}

class _Cache extends Mock implements ProfileLocalDataSource {}

class _Session extends Mock implements SessionGateway {}

class _Connectivity extends Mock implements ConnectivityService {}

void main() {
  test('profile requests share per user, refresh explicitly, invalidate and expire at rollover (#10)', () async {
    final remote = _Remote();
    final cache = _Cache();
    final session = _Session();
    final connectivity = _Connectivity();
    var now = DateTime.utc(2026, 11, 15, 21, 59);
    when(() => session.currentUserId).thenReturn('u');
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => cache.cacheProfile(any(), any())).thenAnswer((_) async {});
    final firstResponse = Completer<Result<dynamic>>();
    when(remote.getMyProfile).thenAnswer((_) => firstResponse.future);
    final repository = ProfileRepositoryImpl(
      remote: remote,
      cache: cache,
      sessionGateway: session,
      connectivity: connectivity,
      now: () => now,
      nextRollover: () async => DateTime.utc(2026, 11, 15, 22),
    );
    final first = repository.getProfile();
    final second = repository.getProfile();
    firstResponse.complete(const Success<dynamic>({'display_name': 'one'}));
    await Future.wait([first, second]);
    verify(remote.getMyProfile).called(1);
    await repository.getProfile();
    verifyNever(remote.getMyProfile);
    when(
      remote.getMyProfile,
    ).thenAnswer((_) async => const Success<dynamic>({'display_name': 'two'}));
    repository.invalidate();
    expect((await repository.getProfile()).valueOrNull!.displayName, 'two');
    verify(remote.getMyProfile).called(1);
    now = DateTime.utc(2026, 11, 15, 22);
    await repository.getProfile();
    verify(remote.getMyProfile).called(1);
    await repository.getProfile(forceRefresh: true);
    verify(remote.getMyProfile).called(1);
    when(() => session.currentUserId).thenReturn('another-user');
    await repository.getProfile();
    verify(remote.getMyProfile).called(1);
  });

  test(
    'invalidating an in-flight profile cannot repopulate old badges (#10)',
    () async {
      final remote = _Remote();
      final cache = _Cache();
      final session = _Session();
      final connectivity = _Connectivity();
      when(() => session.currentUserId).thenReturn('u');
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(() => cache.cacheProfile(any(), any())).thenAnswer((_) async {});
      final old = Completer<Result<dynamic>>();
      when(remote.getMyProfile).thenAnswer((_) => old.future);
      final repository = ProfileRepositoryImpl(
        remote: remote,
        cache: cache,
        sessionGateway: session,
        connectivity: connectivity,
      );
      final first = repository.getProfile();
      await Future<void>.delayed(Duration.zero);
      repository.invalidate();
      when(remote.getMyProfile).thenAnswer(
        (_) async => const Success<dynamic>({'display_name': 'new'}),
      );
      await repository.getProfile();
      old.complete(const Success<dynamic>({'display_name': 'old'}));
      expect((await first).valueOrNull!.displayName, 'new');
      expect((await repository.getProfile()).valueOrNull!.displayName, 'new');
    },
  );
}
