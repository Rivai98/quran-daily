import 'package:equatable/equatable.dart';

/// Queued personal completion operations (data-model `sync_queue`).
enum SyncOperationType { markComplete, undoCompletion }

enum SyncOperationStatus { pending, syncing, failed }

class SyncOperation extends Equatable {
  const SyncOperation({
    required this.id,
    required this.type,
    required this.assignmentId,
    required this.clientRecordedAt,
    this.status = SyncOperationStatus.pending,
    this.attempts = 0,
    this.lastErrorKind,
    this.createdAt,
  });

  final String id;
  final SyncOperationType type;
  final String assignmentId;
  final DateTime clientRecordedAt;
  final SyncOperationStatus status;
  final int attempts;
  final String? lastErrorKind;
  final DateTime? createdAt;

  SyncOperation copyWith({
    SyncOperationStatus? status,
    int? attempts,
    String? lastErrorKind,
  }) {
    return SyncOperation(
      id: id,
      type: type,
      assignmentId: assignmentId,
      clientRecordedAt: clientRecordedAt,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastErrorKind: lastErrorKind ?? this.lastErrorKind,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    assignmentId,
    clientRecordedAt,
    status,
    attempts,
    lastErrorKind,
  ];
}
