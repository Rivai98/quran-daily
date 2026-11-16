import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/auth/session_gateway.dart';
import '../../../../core/settings/settings_repository.dart';

class SelectedGroupState extends Equatable {
  const SelectedGroupState({this.selectedGroupId, this.loading = true});

  final String? selectedGroupId;
  final bool loading;

  SelectedGroupState copyWith({
    String? selectedGroupId,
    bool? loading,
    bool clear = false,
  }) {
    return SelectedGroupState(
      selectedGroupId: clear ? null : (selectedGroupId ?? this.selectedGroupId),
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [selectedGroupId, loading];
}

/// App-root selected group (repository contract): persists the last
/// selected group and switches between groups.
class SelectedGroupCubit extends Cubit<SelectedGroupState> {
  SelectedGroupCubit({
    required SettingsRepository settingsRepository,
    required SessionGateway sessionGateway,
  }) : _settings = settingsRepository,
       _session = sessionGateway,
       super(const SelectedGroupState());

  final SettingsRepository _settings;

  /// Kept as a dependency so the gate can observe auth-driven group resets;
  /// per-repository contract, cross-cutting auth is read by Views.
  // ignore: unused_field
  final SessionGateway _session;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final result = await _settings.getSelectedGroupId();
    result.when(
      success: (groupId) =>
          emit(state.copyWith(selectedGroupId: groupId, loading: false)),
      failure: (_) => emit(state.copyWith(loading: false)),
    );
  }

  Future<void> selectGroup(String groupId) async {
    emit(state.copyWith(selectedGroupId: groupId));
    await _settings.setSelectedGroupId(groupId);
  }

  Future<void> clearSelection() async {
    emit(state.copyWith(clear: true));
    await _settings.setSelectedGroupId(null);
  }
}
