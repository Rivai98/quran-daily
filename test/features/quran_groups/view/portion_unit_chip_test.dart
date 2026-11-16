import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/localization/arabic_strings.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/core/quran/quran_metadata_repository.dart';
import 'package:quran_daily/features/quran_groups/view/widgets/portion_unit_chip.dart';

import '../../../helpers/quran_metadata_test_asset_bundle.dart';
import '../../../helpers/widget_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('keeps the selected unit chip on one line in all variants', (
    tester,
  ) async {
    final metadata = QuranMetadataRepository(
      bundle: QuranMetadataTestAssetBundle(),
    );
    await tester.runAsync(metadata.load);

    await pumpAllVariants(
      tester,
      PortionUnitChip(unit: PortionUnit.hizb, metadataRepository: metadata),
      (tester, variant) async {
        expect(
          find.text(ArabicStrings.dailyUnitChip(PortionUnit.hizb)),
          findsOneWidget,
          reason: variant,
        );
        expect(
          find.text(ArabicStrings.khatmaDays(2)),
          findsNothing,
          reason: variant,
        );
        expect(tester.takeException(), isNull, reason: variant);
      },
    );
  });
}
