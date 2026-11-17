import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_daily/core/auth/session_gateway.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/network/connectivity_service.dart';
import 'package:quran_daily/core/network/rpc_client.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/features/quran_groups/cubit/dashboard/dashboard_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/groups_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/khatma_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository_impl.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/khatma_repository_impl.dart';

import 'cache_first_test.dart' show dashboardJson, testNow;

class _Rpc extends Mock implements RpcClient {}

class _GroupsRemote extends Mock implements GroupsRemoteDataSource {}

class _KhatmaRemote extends Mock implements KhatmaRemoteDataSource {}

class _Session extends Mock implements SessionGateway {}

class _Connectivity extends Mock implements ConnectivityService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  late LocalDatabase db;
  late _Rpc rpc;
  late _GroupsRemote remote;
  late _KhatmaRemote khatmaRemote;
  late GroupsRepositoryImpl groups;
  late KhatmaRepositoryImpl khatma;
  setUp(() async {
    db = LocalDatabase();
    await db.open(inMemory: true);
    rpc = _Rpc();
    remote = _GroupsRemote();
    khatmaRemote = _KhatmaRemote();
    final session = _Session();
    final connectivity = _Connectivity();
    when(() => session.currentUserId).thenReturn('u');
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    khatma = KhatmaRepositoryImpl(
      remote: khatmaRemote,
      cache: CachedSnapshotsDao(db),
      now: () => testNow,
    );
    groups = GroupsRepositoryImpl(
      rpc: rpc,
      remote: remote,
      cache: CachedGroupsDao(db),
      sessionGateway: session,
      connectivity: connectivity,
      khatmaRepository: khatma,
    );
  });
  tearDown(() => db.close());

  test('groups emits user cache before shared remote refresh (#2)', () async {
    await CachedGroupsDao(db).upsert('u', {
      'groups': [
        {
          'group_id': 'g',
          'name': 'cached',
          'status': 'active',
          'my_role': 'member',
          'active_member_count': 1,
        },
      ],
      'pending_requests': [],
    });
    final response = Completer<Result<dynamic>>();
    when(() => remote.call('get_my_groups')).thenAnswer((_) => response.future);
    final cached = Completer<MyGroupsOverview>();
    final first = groups.getMyGroups(onCached: cached.complete);
    expect((await cached.future).groups.single.name, 'cached');
    final second = groups.getMyGroups();
    response.complete(
      const Success<dynamic>({'groups': [], 'pending_requests': []}),
    );
    await Future.wait([first, second]);
    verify(() => remote.call('get_my_groups')).called(1);
  });

  test(
    'starting a khatma fetches one dashboard and caches it for completion (#8)',
    () async {
      when(() => rpc.call<dynamic>('start_khatma', any()))
          .thenAnswer((_) async => const Success<dynamic>({'today': true}));
      when(() => khatmaRemote.getDashboard('g'))
          .thenAnswer((_) async => Success<dynamic>(dashboardJson()));
      final cubit = DashboardCubit(
        repository: khatma,
        groupsRepository: groups,
        groupId: 'g',
      );
      await cubit.startKhatma(1);
      expect(cubit.state.status, DashboardStatus.success);
      expect(
        (await CachedSnapshotsDao(db).read('g'))!.json['assignments'],
        isNotEmpty,
      );
      verify(() => khatmaRemote.getDashboard('g')).called(1);
      verifyNever(() => rpc.call<dynamic>('get_dashboard', any()));
      await cubit.close();
    },
  );
}
