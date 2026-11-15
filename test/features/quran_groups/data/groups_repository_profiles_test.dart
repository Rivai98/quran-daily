import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/auth/session_gateway.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/network/connectivity_service.dart';
import 'package:quran_daily/core/network/rpc_client.dart';
import 'package:quran_daily/core/storage/daos/daos.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/groups_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository_impl.dart';

class _MockRpc extends Mock implements RpcClient {}
class _MockRemote extends Mock implements GroupsRemoteDataSource {}
class _MockGroups extends Mock implements CachedGroupsDao {}
class _MockSession extends Mock implements SessionGateway {}
class _MockConnectivity extends Mock implements ConnectivityService {}

void main() {
  late _MockRpc rpc;
  late _MockRemote remote;
  late _MockGroups cache;
  late _MockSession session;
  late _MockConnectivity connectivity;
  late GroupsRepositoryImpl repository;

  setUp(() {
    rpc = _MockRpc();
    remote = _MockRemote();
    cache = _MockGroups();
    session = _MockSession();
    connectivity = _MockConnectivity();
    repository = GroupsRepositoryImpl(
      rpc: rpc,
      remote: remote,
      cache: cache,
      sessionGateway: session,
      connectivity: connectivity,
    );
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
  });

  group('Spec 007 GroupsRepository profiles & group info (T009)', () {
    test('getGroupInfo calls get_group_info RPC and parses response', () async {
      when(() => remote.call('get_group_info', {'p_group_id': 'g-1'})).thenAnswer(
        (_) async => const Success<dynamic>({
          'group_id': 'g-1',
          'name': 'مجموعة النور',
          'description': 'وصف تجريبي',
          'photo_path': null,
          'status': 'active',
          'visibility': 'public',
          'join_mode': 'auto_accept',
          'portion_unit': 'juz',
          'timezone': 'Asia/Riyadh',
          'day_start_time': '00:00:00',
          'created_at': '2026-11-15T00:00:00.000Z',
          'start_date': '2026-11-15',
          'my_role': 'owner',
          'member_count': 10,
          'seat_capacity': 30,
          'khatma_count': 2,
          'invite_code': 'NOOR123',
          'members': [],
        }),
      );

      final result = await repository.getGroupInfo('g-1');
      expect(result.isSuccess, isTrue);
      result.when(
        success: (info) {
          expect(info.groupId, 'g-1');
          expect(info.name, 'مجموعة النور');
          expect(info.khatmaCount, 2);
          expect(info.inviteCode, 'NOOR123');
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('getMemberProfile calls get_member_profile RPC and parses response', () async {
      when(() => remote.call('get_member_profile', {'p_user_id': 'u-1', 'p_group_id': 'g-1'})).thenAnswer(
        (_) async => const Success<dynamic>({
          'user_id': 'u-1',
          'group_id': 'g-1',
          'display_name': 'سعيد',
          'initials': 'س',
          'bio': 'نبذة شخصية',
          'role': 'member',
          'seat_number': 3,
          'member_since': '2026-11-01T00:00:00.000Z',
          'is_me': false,
          'current_streak': 4,
          'completion_rate': 80,
          'portions_read': 8,
          'recent_days': [],
        }),
      );

      final result = await repository.getMemberProfile('u-1', 'g-1');
      expect(result.isSuccess, isTrue);
      result.when(
        success: (profile) {
          expect(profile.displayName, 'سعيد');
          expect(profile.currentStreak, 4);
          expect(profile.completionRate, 80);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('updateMyProfile calls update_my_profile RPC', () async {
      when(() => remote.call('update_my_profile', {
        'p_display_name': 'عثمان',
        'p_bio': 'حفظ متقن',
        'p_avatar_key': 'ornament',
      })).thenAnswer(
        (_) async => const Success<dynamic>({
          'user_id': 'u-me',
          'display_name': 'عثمان',
          'initials': 'ع',
          'bio': 'حفظ متقن',
          'avatar_key': 'ornament',
          'updated_at': '2026-11-15T12:00:00.000Z',
        }),
      );

      final result = await repository.updateMyProfile('عثمان', bio: 'حفظ متقن');
      expect(result.isSuccess, isTrue);
      result.when(
        success: (user) {
          expect(user.displayName, 'عثمان');
          expect(user.bio, 'حفظ متقن');
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('updateGroupDetails calls update_group_details RPC', () async {
      when(() => rpc.call<dynamic>('update_group_details', {
        'p_group_id': 'g-1',
        'p_name': 'اسم جديد',
        'p_description': 'وصف جديد',
      })).thenAnswer((_) async => const Success<dynamic>({}));

      final result = await repository.updateGroupDetails('g-1', 'اسم جديد', description: 'وصف جديد');
      expect(result.isSuccess, isTrue);
    });

    test('setGroupPhoto calls set_group_photo RPC', () async {
      when(() => rpc.call<dynamic>('set_group_photo', {
        'p_group_id': 'g-1',
        'p_path': 'g-1/photo.jpg',
      })).thenAnswer((_) async => const Success<dynamic>({}));

      final result = await repository.setGroupPhoto('g-1', 'g-1/photo.jpg');
      expect(result.isSuccess, isTrue);
    });

    test('offline calls return NetworkFailure', () async {
      when(() => connectivity.isOnline).thenAnswer((_) async => false);

      final result = await repository.getGroupInfo('g-1');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.kind, FailureKind.network);
    });
  });
}
