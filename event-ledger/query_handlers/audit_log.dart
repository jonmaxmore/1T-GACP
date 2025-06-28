import 'package:thai_herbal_gacp_event_ledger/event_store.dart';

class AuditQueryHandler {
  final EventStore eventStore;

  AuditQueryHandler(this.eventStore);

  Future<List<AuditRecord>> getAuditLog(
    String aggregateId, {
    int offset = 0,
    int limit = 100,
  }) async {
    final result = await eventStore.connection.query(
      '''
      SELECT event_type, event_data, timestamp, version
      FROM events
      WHERE aggregate_id = @aggregateId
      ORDER BY timestamp DESC
      OFFSET @offset
      LIMIT @limit
      ''',
      substitutionValues: {
        'aggregateId': aggregateId,
        'offset': offset,
        'limit': limit,
      },
    );

    return result.map((row) {
      return AuditRecord(
        eventType: row[0] as String,
        eventData: row[1] as Map<String, dynamic>,
        timestamp: row[2] as DateTime,
        version: row[3] as int,
      );
    }).toList();
  }

  Future<List<AuditRecord>> searchAuditLog({
    String? eventType,
    DateTime? fromDate,
    DateTime? toDate,
    int offset = 0,
    int limit = 100,
  }) async {
    final conditions = <String>[];
    final params = <String, dynamic>{};

    if (eventType != null) {
      conditions.add('event_type = @eventType');
      params['eventType'] = eventType;
    }

    if (fromDate != null) {
      conditions.add('timestamp >= @fromDate');
      params['fromDate'] = fromDate;
    }

    if (toDate != null) {
      conditions.add('timestamp <= @toDate');
      params['toDate'] = toDate;
    }

    final whereClause = conditions.isNotEmpty
        ? 'WHERE ${conditions.join(' AND ')}'
        : '';

    final query = '''
      SELECT aggregate_id, event_type, event_data, timestamp, version
      FROM events
      $whereClause
      ORDER BY timestamp DESC
      OFFSET @offset
      LIMIT @limit
    ''';

    final result = await eventStore.connection.query(
      query,
      substitutionValues: {
        ...params,
        'offset': offset,
        'limit': limit,
      },
    );

    return result.map((row) {
      return AuditRecord(
        aggregateId: row[0] as String,
        eventType: row[1] as String,
        eventData: row[2] as Map<String, dynamic>,
        timestamp: row[3] as DateTime,
        version: row[4] as int,
      );
    }).toList();
  }
}

class AuditRecord {
  final String? aggregateId;
  final String eventType;
  final Map<String, dynamic> eventData;
  final DateTime timestamp;
  final int version;

  AuditRecord({
    this.aggregateId,
    required this.eventType,
    required this.eventData,
    required this.timestamp,
    required this.version,
  });

  Map<String, dynamic> toJson() => {
        if (aggregateId != null) 'aggregateId': aggregateId,
        'eventType': eventType,
        'eventData': eventData,
        'timestamp': timestamp.toIso8601String(),
        'version': version,
      };
}
