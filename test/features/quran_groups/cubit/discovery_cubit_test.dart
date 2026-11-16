import 'package:bloc_test/bloc_test.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/quran_groups/cubit/discovery/discovery_cubit.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/models/models.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';

class _Repository extends Mock implements GroupsRepository {}

PublicGroupProfile _group(String id) => PublicGroupProfile(
  groupId: id,
  name: 'حلقة $id',
  status: GroupStatus.forming,
  activeMemberCount: 1,
  timezone: 'Africa/Cairo',
  joinMode: JoinMode.autoAccept,
);

void main() {
  late _Repository repository;
  late Completer<Result<List<PublicGroupProfile>>> oldResponse;
  late Completer<Result<List<PublicGroupProfile>>> newResponse;
  setUp(() => repository = _Repository());

  blocTest<DiscoveryCubit, DiscoveryState>(
    'debounces search input to the latest query',
    build: () {
      when(
        () => repository.searchPublicGroups(
          query: any(named: 'query'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => Success([_group('g1')]));
      return DiscoveryCubit(repository: repository);
    },
    act: (cubit) {
      cubit.search('ف');
      cubit.search('فجر');
    },
    wait: DiscoveryCubit.debounceDuration + const Duration(milliseconds: 20),
    skip: 2,
    expect: () => [
      isA<DiscoveryState>().having(
        (s) => s.status,
        'success',
        DiscoveryStatus.success,
      ),
    ],
    verify: (_) => verify(
      () => repository.searchPublicGroups(query: 'فجر', limit: 20, offset: 0),
    ).called(1),
  );

  blocTest<DiscoveryCubit, DiscoveryState>(
    'keeps existing results while searching and skips an unchanged query',
    build: () {
      when(
        () => repository.searchPublicGroups(
          query: any(named: 'query'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => Success([_group('g1')]));
      return DiscoveryCubit(repository: repository);
    },
    act: (cubit) async {
      await cubit.load();
      cubit.search('فجر');
      await Future<void>.delayed(
        DiscoveryCubit.debounceDuration + const Duration(milliseconds: 20),
      );
      cubit.search('فجر');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    expect: () => [
      isA<DiscoveryState>().having(
        (s) => s.status,
        'loading',
        DiscoveryStatus.loading,
      ),
      isA<DiscoveryState>().having(
        (s) => s.groups,
        'first result',
        hasLength(1),
      ),
      isA<DiscoveryState>()
          .having((s) => s.status, 'searching', DiscoveryStatus.loading)
          .having((s) => s.groups, 'kept result visible', hasLength(1)),
      isA<DiscoveryState>().having((s) => s.groups, 'new result', hasLength(1)),
    ],
    verify: (_) => verify(
      () => repository.searchPublicGroups(
        query: any(named: 'query'),
        limit: 20,
        offset: 0,
      ),
    ).called(2),
  );

  blocTest<DiscoveryCubit, DiscoveryState>(
    'ignores a stale response after the query changes',
    build: () {
      oldResponse = Completer<Result<List<PublicGroupProfile>>>();
      newResponse = Completer<Result<List<PublicGroupProfile>>>();
      var calls = 0;
      when(
        () => repository.searchPublicGroups(
          query: any(named: 'query'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) => calls++ == 0 ? oldResponse.future : newResponse.future,
      );
      return DiscoveryCubit(repository: repository);
    },
    act: (cubit) async {
      cubit.load();
      cubit.search('فجر');
      await Future<void>.delayed(
        DiscoveryCubit.debounceDuration + const Duration(milliseconds: 20),
      );
      newResponse.complete(Success([_group('new')]));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      oldResponse.complete(Success([_group('old')]));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    expect: () => [
      isA<DiscoveryState>().having(
        (s) => s.status,
        'loading',
        DiscoveryStatus.loading,
      ),
      isA<DiscoveryState>()
          .having((s) => s.query, 'new query', 'فجر')
          .having((s) => s.status, 'query loading', DiscoveryStatus.loading),
      isA<DiscoveryState>().having(
        (s) => s.groups.single.groupId,
        'new results',
        'new',
      ),
    ],
    verify: (_) => verify(
      () => repository.searchPublicGroups(query: 'فجر', limit: 20, offset: 0),
    ).called(1),
  );

  blocTest<DiscoveryCubit, DiscoveryState>(
    'loads the next page and appends results',
    build: () {
      when(
        () => repository.searchPublicGroups(
          query: any(named: 'query'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((invocation) async {
        final offset = invocation.namedArguments[#offset] as int;
        return Success(
          offset == 0
              ? List.generate(20, (i) => _group('$i'))
              : [_group('g21')],
        );
      });
      return DiscoveryCubit(repository: repository);
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    expect: () => [
      isA<DiscoveryState>().having(
        (s) => s.status,
        'loading',
        DiscoveryStatus.loading,
      ),
      isA<DiscoveryState>().having((s) => s.groups.length, 'first page', 20),
      isA<DiscoveryState>().having(
        (s) => s.status,
        'loading',
        DiscoveryStatus.loading,
      ),
      isA<DiscoveryState>().having((s) => s.groups.length, 'all pages', 21),
    ],
    verify: (_) => verify(
      () => repository.searchPublicGroups(query: '', limit: 20, offset: 20),
    ).called(1),
  );

  blocTest<DiscoveryCubit, DiscoveryState>(
    'stores pending state for only the joined card',
    build: () {
      when(() => repository.joinGroup(groupId: 'g1')).thenAnswer(
        (_) async =>
            const Success(JoinOutcome(joined: false, joinRequestId: 'r1')),
      );
      return DiscoveryCubit(repository: repository);
    },
    act: (cubit) => cubit.join(_group('g1')),
    expect: () => [
      isA<DiscoveryState>().having(
        (s) => s.joinStates['g1'],
        'joining',
        GroupJoinState.joining,
      ),
      isA<DiscoveryState>().having(
        (s) => s.joinStates['g1'],
        'pending',
        GroupJoinState.pending,
      ),
    ],
  );
}
