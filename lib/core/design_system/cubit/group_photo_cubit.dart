import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/result.dart';

class GroupPhotoState extends Equatable {
  const GroupPhotoState([this.bytes]);
  final Uint8List? bytes;

  @override
  List<Object?> get props => [bytes];
}

class GroupPhotoCubit extends Cubit<GroupPhotoState> {
  GroupPhotoCubit({this.loadPhoto}) : super(const GroupPhotoState());

  final Future<Result<List<int>>> Function(String path)? loadPhoto;
  int _request = 0;

  Future<void> show({List<int>? bytes, String? path}) async {
    final request = ++_request;
    emit(GroupPhotoState(_typed(bytes)));
    if (bytes != null && bytes.isNotEmpty || path == null || path.isEmpty) {
      return;
    }
    final response = await loadPhoto?.call(path);
    if (isClosed || request != _request) return;
    emit(GroupPhotoState(_typed(response?.valueOrNull)));
  }

  Uint8List? _typed(List<int>? bytes) => bytes == null
      ? null
      : bytes is Uint8List
      ? bytes
      : Uint8List.fromList(bytes);
}
