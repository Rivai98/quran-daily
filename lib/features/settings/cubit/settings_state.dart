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
    this.isAdmin = false,
  });

  final SettingsStatus status;
  final double quranTextScale;
  final AppFailure? failure;
  final bool isAdmin;

  SettingsState copyWith({
    SettingsStatus? status,
    double? quranTextScale,
    AppFailure? failure,
    bool? isAdmin,
  }) {
    return SettingsState(
      status: status ?? this.status,
      quranTextScale: quranTextScale ?? this.quranTextScale,
      failure: failure ?? this.failure,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  @override
  List<Object?> get props => [status, quranTextScale, failure, isAdmin];
}
