import 'package:equatable/equatable.dart';

/// A Quran verse location. Its numeric values are sourced from bundled data.
class AyahRef extends Equatable {
  const AyahRef({required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  List<Object?> get props => [surah, ayah];
}

/// Verse content loaded from the approved QPC Hafs asset.
class MushafAyah extends Equatable {
  const MushafAyah({required this.ref, required this.text});

  final AyahRef ref;
  final String text;

  @override
  List<Object?> get props => [ref, text];
}

/// The verses and metadata for a single Madinah Mushaf page.
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

/// Raised when bundled Mushaf source data fails its integrity checks.
class MushafIntegrityException implements Exception {
  const MushafIntegrityException([
    this.message = 'Mushaf integrity check failed',
  ]);

  final String message;

  @override
  String toString() => message;
}
