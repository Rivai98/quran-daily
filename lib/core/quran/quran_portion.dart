import 'package:equatable/equatable.dart';

import 'portion_unit.dart';

/// A portion range derived from the verified Tanzil metadata file.
class QuranPortion extends Equatable {
  const QuranPortion({
    required this.unit,
    required this.index,
    required this.startSura,
    required this.startAya,
    required this.endSura,
    required this.endAya,
  });

  final PortionUnit unit;
  final int index;
  final int startSura;
  final int startAya;
  final int endSura;
  final int endAya;

  @override
  List<Object?> get props => [
    unit,
    index,
    startSura,
    startAya,
    endSura,
    endAya,
  ];
}
