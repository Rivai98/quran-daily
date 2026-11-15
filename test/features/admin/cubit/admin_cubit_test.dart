import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/features/admin/cubit/admin_cubit.dart';
import 'package:quran_daily/features/admin/cubit/admin_state.dart';
import 'package:quran_daily/features/admin/data/admin_repository.dart';

class _Repository extends Mock implements AdminRepository {}

void main() {
  test('loads list data and distinguishes an empty result', () async {
    final repository = _Repository();
    when(() => repository.groups(query: null, status: null)).thenAnswer(
      (_) async => const Success<AdminJson>({'total': 0, 'items': []}),
    );
    final cubit = AdminCubit(repository);

    await cubit.groups();

    expect(cubit.state.status, AdminStatus.empty);
    expect(cubit.state.data?['total'], 0);
    await cubit.close();
  });

  test('reports network failures as offline state', () async {
    final repository = _Repository();
    when(() => repository.overview()).thenAnswer(
      (_) async => const FailureResult(
        NetworkFailure(message: 'offline', code: 'network'),
      ),
    );
    final cubit = AdminCubit(repository);

    await cubit.overview();

    expect(cubit.state.status, AdminStatus.offline);
    await cubit.close();
  });
}
