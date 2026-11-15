import '../errors/result.dart';

/// Lives in core because both quran_groups (SelectedGroupCubit, Quran label
/// scale) and the settings feature use it (repository contract).
abstract class SettingsRepository {
  Future<Result<String?>> getSelectedGroupId();
  Future<Result<void>> setSelectedGroupId(String? groupId);

  /// Quran label text scale, clamped to 0.85..1.6 (default 1.0).
  Future<Result<double>> getQuranTextScale();
  Future<Result<void>> setQuranTextScale(double scale);
}
