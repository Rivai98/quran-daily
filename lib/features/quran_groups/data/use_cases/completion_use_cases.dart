import '../../../../core/errors/result.dart';
import '../entities/entities.dart';
import '../repositories/khatma_repository.dart';

class MarkAssignmentComplete {
  const MarkAssignmentComplete(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final KhatmaRepository _repository;
  final DateTime Function() _clock;

  Future<Result<DashboardSnapshot>> call(String assignmentId) =>
      _repository.markComplete(assignmentId, _clock());
}

class UndoAssignmentCompletion {
  const UndoAssignmentCompletion(this._repository);

  final KhatmaRepository _repository;

  Future<Result<DashboardSnapshot>> call(String assignmentId) =>
      _repository.undoCompletion(assignmentId);
}

class SyncPendingCompletions {
  const SyncPendingCompletions(this._repository);

  final KhatmaRepository _repository;

  Future<SyncReport> call() => _repository.syncPending();
}
