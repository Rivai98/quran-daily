import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/app/router.dart';

void main() {
  test('parses the supported invite URI and normalizes its code', () {
    expect(
      inviteCodeFromDeepLink(Uri.parse('qurandaily://join/us4a2345')),
      'US4A2345',
    );
  });

  test('rejects unsupported hosts, paths, schemes, and malformed codes', () {
    expect(inviteCodeFromDeepLink(Uri.parse('https://join/US4A2345')), isNull);
    expect(
      inviteCodeFromDeepLink(Uri.parse('qurandaily://other/US4A2345')),
      isNull,
    );
    expect(
      inviteCodeFromDeepLink(Uri.parse('qurandaily://join/US4A2345/extra')),
      isNull,
    );
    expect(
      inviteCodeFromDeepLink(Uri.parse('qurandaily://join/US4A2340')),
      isNull,
    );
  });
}
