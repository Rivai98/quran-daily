import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';

enum SettingsStatus {
  initial,
  loading,
  success,
  signingOut,
  signedOut,
  failure,
}

class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.quranTextScale = 1.0,
    this.failure,
  });

  final SettingsStatus status;
  final double quranTextScale;
  final AppFailure? failure;

  SettingsState copyWith({
    SettingsStatus? status,
    double? quranTextScale,
    AppFailure? failure,
  }) {
    return SettingsState(
      status: status ?? this.status,
      quranTextScale: quranTextScale ?? this.quranTextScale,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, quranTextScale, failure];
}
