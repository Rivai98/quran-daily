import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/cubit/group_photo_cubit.dart';
import 'package:quran_daily/core/errors/result.dart';

void main() {
  test(
    'keeps typed photo identity and ignores obsolete path results (#14)',
    () async {
      final old = Completer<Result<List<int>>>();
      final current = Completer<Result<List<int>>>();
      final cubit = GroupPhotoCubit(
        loadPhoto: (path) => path == 'old' ? old.future : current.future,
      );
      final first = cubit.show(path: 'old');
      final second = cubit.show(path: 'current');
      final bytes = Uint8List.fromList([1, 2]);
      current.complete(Success(bytes));
      await second;
      expect(identical(cubit.state.bytes, bytes), isTrue);
      old.complete(const Success([3, 4]));
      await first;
      expect(identical(cubit.state.bytes, bytes), isTrue);
      await cubit.close();
    },
  );
}
