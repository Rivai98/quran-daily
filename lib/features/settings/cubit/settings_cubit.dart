import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/session_gateway.dart';
import '../../../core/settings/settings_repository.dart';
import '../../admin/data/admin_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required SettingsRepository settingsRepository,
    required SessionGateway sessionGateway,
    AdminRepository? adminRepository,
  })  : _settingsRepository = settingsRepository,
        _sessionGateway = sessionGateway,
        _adminRepository = adminRepository,
        super(const SettingsState());

  final SettingsRepository _settingsRepository;
  final SessionGateway _sessionGateway;
  final AdminRepository? _adminRepository;

  static const double minQuranTextScale = 0.85;
  static const double maxQuranTextScale = 1.6;

  Future<void> loadSettings() async {
    final adminRepository = _adminRepository;
    if (adminRepository != null) {
      adminRepository.isAdmin().then((result) {
        if (!isClosed) {
          emit(state.copyWith(isAdmin: result.valueOrNull ?? false));
        }
      });
    }
    final result = await _settingsRepository.getQuranTextScale();
    if (result.isSuccess) {
      final scale = result.valueOrNull ?? 1.0;
      emit(state.copyWith(
        status: SettingsStatus.success,
        quranTextScale: scale.clamp(minQuranTextScale, maxQuranTextScale),
      ));
    } else {
      emit(state.copyWith(
        status: SettingsStatus.failure,
        failure: result.failureOrNull,
      ));
    }
  }

  Future<void> setQuranTextScale(double scale) async {
    final clamped = scale.clamp(minQuranTextScale, maxQuranTextScale);
    emit(state.copyWith(quranTextScale: clamped));
    await _settingsRepository.setQuranTextScale(clamped);
  }

  Future<void> signOut() async {
    emit(state.copyWith(status: SettingsStatus.signingOut));
    final result = await _sessionGateway.signOut();
    if (result.isSuccess) {
      emit(state.copyWith(status: SettingsStatus.signedOut));
    } else {
      emit(state.copyWith(
        status: SettingsStatus.failure,
        failure: result.failureOrNull,
      ));
    }
  }
}
