import 'package:equatable/equatable.dart';

class AyahRef extends Equatable {
  const AyahRef({required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  List<Object?> get props => [surah, ayah];
}

class MushafAyah extends Equatable {
  const MushafAyah({required this.ref, required this.text});

  final AyahRef ref;
  final String text;

  @override
  List<Object?> get props => [ref, text];
}

class MushafPage extends Equatable {
  const MushafPage({
    required this.number,
    required this.ayahs,
    required this.juz,
    required this.firstSurah,
  });

  final int number;
  final List<MushafAyah> ayahs;
  final int juz;
  final int firstSurah;

  @override
  List<Object?> get props => [number, ayahs, juz, firstSurah];
}

class MushafIntegrityException implements Exception {
  const MushafIntegrityException(this.message);

  final String message;

  @override
  String toString() => 'MushafIntegrityException: $message';
}
