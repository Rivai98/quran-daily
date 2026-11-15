import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/errors/failures.dart';
import 'package:quran_daily/core/errors/result.dart';
import 'package:quran_daily/core/network/rpc_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps membership_limit RPC errors to a stable limit failure', () async {
    final client = RpcClient(
      execute: (_, _) async => throw const PostgrestException(
        message: 'membership_limit',
        code: 'P0001',
      ),
    );

    final result = await client.call<void>('create_group');

    expect(result, isA<FailureResult<void>>());
    final failure = (result as FailureResult<void>).failure;
    expect(failure.code, 'membership_limit');
    expect(failure.kind, FailureKind.limitReached);
  });
}
