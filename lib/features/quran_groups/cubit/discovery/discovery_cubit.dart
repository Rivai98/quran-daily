import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/models.dart';
import '../../data/repositories/groups_repository.dart';

enum DiscoveryStatus { initial, loading, success, empty, failure, offline }

enum GroupJoinState { joining, joined, pending }

class DiscoveryState extends Equatable {
  const DiscoveryState({
    this.status = DiscoveryStatus.initial,
    this.groups = const [],
    this.query = '',
    this.offset = 0,
    this.hasMore = true,
    this.joinStates = const {},
    this.failure,
  });

  final DiscoveryStatus status;
  final List<PublicGroupProfile> groups;
  final String query;
  final int offset;
  final bool hasMore;
  final Map<String, GroupJoinState> joinStates;
  final AppFailure? failure;

  @override
  List<Object?> get props => [
    status,
    groups,
    query,
    offset,
    hasMore,
    joinStates,
    failure,
  ];
}

/// S2 discovery view model. Search keystrokes are coalesced before querying;
/// page and join state remain local to the discovery result set.
class DiscoveryCubit extends Cubit<DiscoveryState> {
  DiscoveryCubit({required this._repository}) : super(const DiscoveryState());

  static const pageSize = 20;
  static const debounceDuration = Duration(milliseconds: 400);

  final GroupsRepository _repository;
  Timer? _debounce;
  int _searchGeneration = 0;

  Future<void> load() => _fetch(reset: true);

  void search(String query, {bool submit = false}) {
    if (query == state.query) {
      if (submit && _debounce != null) {
        _debounce!.cancel();
        _debounce = null;
        _fetch(reset: true);
      }
      return;
    }
    _debounce?.cancel();
    _debounce = null;
    ++_searchGeneration;
    emit(
      DiscoveryState(
        query: query,
        status: DiscoveryStatus.loading,
        groups: state.groups,
        joinStates: state.joinStates,
        hasMore: true,
      ),
    );
    if (submit) {
      _fetch(reset: true);
    } else {
      _debounce = Timer(debounceDuration, () {
        _debounce = null;
        _fetch(reset: true);
      });
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == DiscoveryStatus.loading ||
        state.status == DiscoveryStatus.initial) {
      return;
    }
    await _fetch(reset: false);
  }

  Future<void> _fetch({required bool reset}) async {
    final generation = ++_searchGeneration;
    final query = state.query;
    final offset = reset ? 0 : state.offset;
    emit(
      DiscoveryState(
        status: DiscoveryStatus.loading,
        groups: state.groups,
        query: query,
        offset: offset,
        hasMore: state.hasMore,
        joinStates: state.joinStates,
      ),
    );
    final result = await _repository.searchPublicGroups(
      query: query,
      limit: pageSize,
      offset: offset,
    );
    if (isClosed || generation != _searchGeneration) return;
    result.when(
      success: (page) {
        final groups = reset ? page : [...state.groups, ...page];
        emit(
          DiscoveryState(
            status: groups.isEmpty
                ? DiscoveryStatus.empty
                : DiscoveryStatus.success,
            groups: groups,
            query: query,
            offset: offset + page.length,
            hasMore: page.length == pageSize,
            joinStates: state.joinStates,
          ),
        );
      },
      failure: (failure) => emit(
        DiscoveryState(
          status: failure.kind == FailureKind.network
              ? DiscoveryStatus.offline
              : DiscoveryStatus.failure,
          groups: state.groups,
          query: query,
          offset: offset,
          hasMore: state.hasMore,
          joinStates: state.joinStates,
          failure: failure,
        ),
      ),
    );
  }

  Future<void> join(PublicGroupProfile group) async {
    if (state.joinStates[group.groupId] != null) return;
    final inProgress = {
      ...state.joinStates,
      group.groupId: GroupJoinState.joining,
    };
    emit(_copy(joinStates: inProgress));
    final result = await _repository.joinGroup(groupId: group.groupId);
    if (isClosed) return;
    result.when(
      success: (outcome) => emit(
        _copy(
          joinStates: {
            ...state.joinStates,
            group.groupId: outcome.joined
                ? GroupJoinState.joined
                : GroupJoinState.pending,
          },
        ),
      ),
      failure: (failure) {
        final states = {...state.joinStates}..remove(group.groupId);
        emit(_copy(joinStates: states, failure: failure));
      },
    );
  }

  DiscoveryState _copy({
    Map<String, GroupJoinState>? joinStates,
    AppFailure? failure,
  }) => DiscoveryState(
    status: state.status,
    groups: state.groups,
    query: state.query,
    offset: state.offset,
    hasMore: state.hasMore,
    joinStates: joinStates ?? state.joinStates,
    failure: failure,
  );

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
