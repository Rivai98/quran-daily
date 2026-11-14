import 'package:shared_preferences/shared_preferences.dart';

import '../errors/failures.dart';
import '../errors/result.dart';
import 'settings_repository.dart';

/// shared_preferences-backed settings: selected group id + Quran text
/// scale (clamped 0.85..1.6, default 1.0).
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  static const _selectedGroupKey = 'selected_group_id';
  static const _quranTextScaleKey = 'quran_text_scale';

  final SharedPreferencesAsync _prefs;

  @override
  Future<Result<String?>> getSelectedGroupId() async {
    try {
      return Success(await _prefs.getString(_selectedGroupKey));
    } catch (error) {
      return FailureResult(NetworkFailure(
          message: 'settings read failed', code: 'unknown'));
    }
  }

  @override
  Future<Result<void>> setSelectedGroupId(String? groupId) async {
    try {
      if (groupId == null) {
        await _prefs.remove(_selectedGroupKey);
      } else {
        await _prefs.setString(_selectedGroupKey, groupId);
      }
      return const Success<void>(null);
    } catch (error) {
      return FailureResult(
          NetworkFailure(message: 'settings write failed', code: 'unknown'));
    }
  }

  @override
  Future<Result<double>> getQuranTextScale() async {
    try {
      final raw = await _prefs.getDouble(_quranTextScaleKey) ?? 1.0;
      return Success(raw.clamp(0.85, 1.6));
    } catch (error) {
      return const Success(1.0);
    }
  }

  @override
  Future<Result<void>> setQuranTextScale(double scale) async {
    try {
      await _prefs.setDouble(_quranTextScaleKey, scale.clamp(0.85, 1.6));
      return const Success<void>(null);
    } catch (error) {
      return FailureResult(
          NetworkFailure(message: 'settings write failed', code: 'unknown'));
    }
  }
}
