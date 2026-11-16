import 'package:equatable/equatable.dart';

/// One of the 30 juz with its reading range, derived ONLY from the
/// verified Tanzil metadata file (constitution Principle VII).
class JuzInfo extends Equatable {
  const JuzInfo({
    required this.number,
    required this.startSura,
    required this.startAya,
    required this.endSura,
    required this.endAya,
  });

  final int number;
  final int startSura;
  final int startAya;
  final int endSura;
  final int endAya;

  @override
  List<Object?> get props => [number, startSura, startAya, endSura, endAya];
}
