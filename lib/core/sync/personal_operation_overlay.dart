import '../storage/daos/daos.dart';
import 'sync_operation.dart';

typedef PersonalSnapshot = ({Map<String, Object?> json, bool hasPending});

/// Reconciles remote read models with durable personal operations in queue order.
class PersonalOperationOverlay {
  PersonalOperationOverlay({required this.queue, required this.snapshots});
  final SyncQueueDao queue;
  final CachedSnapshotsDao snapshots;
  int _revision = 0;
  int get revision => _revision;
  void changed() => _revision++;

  Future<Map<String, SyncOperation>> _pending() async => {
    for (final op in await queue.pending())
      if (op.status != SyncOperationStatus.failed) op.assignmentId: op,
  };

  Future<PersonalSnapshot> today(Map<String, Object?> json) async {
    final operations = await _pending();
    if (operations.isEmpty) return (json: json, hasPending: false);
    final groups = [
      for (final raw in json['groups'] as List? ?? const [])
        _todayGroup((raw as Map).cast<String, Object?>(), operations),
    ];
    return (json: {...json, 'groups': groups}, hasPending: true);
  }

  Map<String, Object?> _todayGroup(
    Map<String, Object?> group,
    Map<String, SyncOperation> operations,
  ) => {
    ...group,
    'items': _items(
      group['items'],
      (group['day'] as Map?)?['state'],
      operations,
    ),
  };

  Future<PersonalSnapshot> dashboard(Map<String, Object?> json) async {
    final operations = await _pending();
    if (operations.isEmpty) return (json: json, hasPending: false);
    final previous = await snapshots.read(json['group_id']! as String);
    final contexts = _contexts(previous?.json ?? json, operations);
    final day = (json['today'] as Map?)?.cast<String, Object?>();
    final assignments = _items(json['assignments'], day?['state'], operations);
    return (
      json: {
        ...json,
        '_pending_contexts': contexts,
        'assignments': assignments,
        'my_assignments': _items(
          json['my_assignments'],
          day?['state'],
          operations,
        ),
      },
      hasPending: true,
    );
  }

  List<Map<String, Object?>> _items(
    Object? rawItems,
    Object? dayState,
    Map<String, SyncOperation> operations,
  ) => [
    for (final raw in rawItems as List? ?? const [])
      _item((raw as Map).cast<String, Object?>(), dayState, operations),
  ];

  Map<String, Object?> _item(
    Map<String, Object?> item,
    Object? dayState,
    Map<String, SyncOperation> operations,
  ) {
    final op = operations[item['assignment_id']];
    if (op == null) return item;
    final undo = op.type == SyncOperationType.undoCompletion;
    return {
      ...item,
      'status': undo
          ? (dayState == 'grace' ? 'missed' : 'pending')
          : (dayState == 'grace' ? 'late' : 'completed'),
      'completed_at': undo
          ? null
          : op.clientRecordedAt.toUtc().toIso8601String(),
      if (item.containsKey('can_undo')) 'can_undo': !undo,
    };
  }

  Map<String, Object?> _contexts(
    Map<String, Object?> snapshot,
    Map<String, SyncOperation> operations,
  ) {
    final contexts = <String, Object?>{
      ...?(snapshot['_pending_contexts'] as Map?)?.cast<String, Object?>(),
    }..removeWhere((id, _) => !operations.containsKey(id));
    for (final raw in snapshot['assignments'] as List? ?? const []) {
      final item = raw as Map;
      final id = item['assignment_id'] as String;
      if (!operations.containsKey(id)) continue;
      contexts[id] = {
        'group_id': snapshot['group_id'],
        'date': (snapshot['today'] as Map?)?['group_date'],
        'state': (snapshot['today'] as Map?)?['state'],
        'portion_unit': snapshot['portion_unit'] ?? 'juz',
        'portion_index': item['portion_index'] ?? item['juz'],
        'kind': item['kind'],
      };
    }
    return contexts;
  }

  Future<PersonalSnapshot> log(Map<String, Object?> json) async {
    final operations = await _pending();
    if (operations.isEmpty) return (json: json, hasPending: false);
    final contexts = <String, Map>{};
    for (final row in await snapshots.readAll()) {
      for (final entry in _contexts(row.json, operations).entries) {
        contexts[entry.key] = entry.value! as Map;
      }
    }
    final days = [
      for (final raw in json['days'] as List)
        _logDay((raw as Map).cast<String, Object?>(), contexts, operations),
    ];
    return (json: {...json, 'days': days}, hasPending: true);
  }

  Map<String, Object?> _logDay(
    Map<String, Object?> day,
    Map<String, Map> contexts,
    Map<String, SyncOperation> operations,
  ) {
    final items = [
      for (final raw in day['items'] as List)
        _logItem(
          (raw as Map).cast<String, Object?>(),
          day['date'],
          contexts,
          operations,
        ),
    ];
    return {
      ...day,
      'items': items,
      'complete':
          items.isNotEmpty &&
          items.every(
            (item) => item['status'] == 'completed' || item['status'] == 'late',
          ),
    };
  }

  Map<String, Object?> _logItem(
    Map<String, Object?> item,
    Object? date,
    Map<String, Map> contexts,
    Map<String, SyncOperation> operations,
  ) {
    for (final entry in contexts.entries) {
      final context = entry.value;
      if (context['group_id'] == item['group_id'] &&
          context['date'] == date &&
          context['portion_unit'] == item['portion_unit'] &&
          context['portion_index'] == item['portion_index'] &&
          context['kind'] == item['kind']) {
        final updated = _item(
          {...item, 'assignment_id': entry.key},
          context['state'],
          operations,
        );
        return updated..remove('assignment_id');
      }
    }
    return item;
  }
}
