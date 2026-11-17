import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/widgets/app_avatar.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  for (final density in [1.0, 3.0]) {
    testWidgets(
      'photo rebuild keeps image identity at density $density (#14)',
      (tester) async {
        final bytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4AWNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=',
        );
        Widget avatar() => buildArabicTestApp(
          MediaQuery(
            data: MediaQueryData(devicePixelRatio: density),
            child: GroupAvatar(name: 'group', photoBytes: bytes, size: 40),
          ),
          dark: true,
        );
        await tester.pumpWidget(avatar());
        await tester.pumpAndSettle();
        final first = tester.widget<Image>(find.byType(Image)).image;
        await tester.pumpWidget(avatar());
        await tester.pumpAndSettle();
        final second = tester.widget<Image>(find.byType(Image)).image;
        expect(second, first);
        expect(second, isA<ResizeImage>());
        final resized = second as ResizeImage;
        expect(resized.width, (40 * density).ceil());
        expect(resized.height, (40 * density).ceil());
        expect(tester.takeException(), isNull);
      },
    );
  }
}
