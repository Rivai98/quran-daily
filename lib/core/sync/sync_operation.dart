import 'package:equatable/equatable.dart';

enum SyncOperationType { markComplete, undoCompletion }

enum SyncOperationStatus { pending, syncing, synced, failed }

class LocalSyncOperation extends Equatable {
  const LocalSyncOperation({
    required this.id,
    required this.operationType,
    required this.assignmentId,
    required this.payload,
    required this.createdAt,
    this.status = SyncOperationStatus.pending,
    this.lastError,
  });

  final String id;
  final SyncOperationType operationType;
  final String assignmentId;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final SyncOperationStatus status;
  final String? lastError;

  LocalSyncOperation copyWith({
    SyncOperationStatus? status,
    String? lastError,
  }) {
    return LocalSyncOperation(
      id: id,
      operationType: operationType,
      assignmentId: assignmentId,
      payload: payload,
      createdAt: createdAt,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  List<Object?> get props => [
        id,
        operationType,
        assignmentId,
        payload,
        createdAt,
        status,
        lastError,
      ];
}
