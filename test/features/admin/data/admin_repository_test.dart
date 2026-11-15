import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/network/rpc_client.dart';
import 'package:quran_daily/features/admin/data/admin_repository_impl.dart';

class _Rpc extends Mock implements RpcClient {}

void main() {
  test('overview reads the server metrics through admin_overview', () async {
    final rpc = _Rpc();
    when(() => rpc.call<dynamic>('admin_overview')).thenAnswer(
      (_) async => const Success<Map<String, Object?>?>({
        'users': {'total': 4},
        'series': [],
      }),
    );
    final repository = AdminRepositoryImpl(
      rpc: rpc,
      invoke: (name, body) async => null,
    );

    final result = await repository.overview();

    expect(result.valueOrNull?['users'], {'total': 4});
    verify(() => rpc.call<dynamic>('admin_overview')).called(1);
  });

  test('group list sends search and status filters to the server', () async {
    final rpc = _Rpc();
    when(() => rpc.call<dynamic>('admin_list_groups', any())).thenAnswer(
      (_) async => const Success<Map<String, Object?>?>({
        'total': 1,
        'items': [
          {'id': 'g1', 'name': 'مجموعة'},
        ],
      }),
    );
    final repository = AdminRepositoryImpl(
      rpc: rpc,
      invoke: (name, body) async => null,
    );

    final result = await repository.groups(query: 'مجموعة', status: 'active');

    expect(result.valueOrNull?['items'], hasLength(1));
    verify(
      () => rpc.call<dynamic>('admin_list_groups', {
        'p_query': 'مجموعة',
        'p_status': 'active',
        'p_limit': 50,
        'p_offset': 0,
      }),
    ).called(1);
  });

  test('delete group sends the required confirmation name', () async {
    final rpc = _Rpc();
    when(() => rpc.call<dynamic>('admin_delete_group', any())).thenAnswer(
      (_) async => const Success<Map<String, Object?>?>({'deleted': true}),
    );
    final repository = AdminRepositoryImpl(
      rpc: rpc,
      invoke: (name, body) async => null,
    );

    await repository.groupAction('delete', 'g1', confirmName: 'مجموعة النور');

    verify(
      () => rpc.call<dynamic>('admin_delete_group', {
        'p_group_id': 'g1',
        'p_confirm_name': 'مجموعة النور',
      }),
    ).called(1);
  });

  test(
    'user account actions call the server function with its contract body',
    () async {
      final rpc = _Rpc();
      final calls = <(String, Map<String, Object?>)>[];
      final repository = AdminRepositoryImpl(
        rpc: rpc,
        invoke: (name, body) async {
          calls.add((name, body));
          return {'userId': 'u1'};
        },
      );

      await repository.userAction('suspend', 'u1');

      expect(calls.single.$1, 'admin-user-action');
      expect(calls.single.$2['action'], 'suspend');
      expect(calls.single.$2['targetUserId'], 'u1');
    },
  );
}
