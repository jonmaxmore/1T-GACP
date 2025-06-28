import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

class EventStore {
  final PostgreSQLConnection _connection;
  final Uuid _uuid = const Uuid();

  EventStore(String connectionString) 
    : _connection = PostgreSQLConnection.fromConnectionString(connectionString);

  Future<void> init() async {
    await _connection.open();
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS events (
        id UUID PRIMARY KEY,
        aggregate_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        event_data JSONB NOT NULL,
        timestamp TIMESTAMPTZ DEFAULT NOW(),
        version INT NOT NULL
      )
    ''');
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_aggregate_id ON events (aggregate_id)
    ''');
  }

  Future<void> saveEvent(
    String aggregateId,
    String eventType,
    Map<String, dynamic> eventData, {
    int expectedVersion = -1,
  }) async {
    await _connection.transaction((ctx) async {
      // Check current version for optimistic concurrency
      if (expectedVersion >= 0) {
        final result = await ctx.query(
          'SELECT MAX(version) FROM events WHERE aggregate_id = @aggregateId',
          substitutionValues: {'aggregateId': aggregateId},
        );
        final currentVersion = result.first[0] as int? ?? 0;
        if (currentVersion != expectedVersion) {
          throw ConcurrencyException(
            'Aggregate $aggregateId version mismatch: '
            'expected $expectedVersion, found $currentVersion'
          );
        }
      }

      // Get next version
      final nextVersion = expectedVersion + 1;

      // Insert event
      await ctx.execute(
        '''
        INSERT INTO events (id, aggregate_id, event_type, event_data, version)
        VALUES (@id, @aggregateId, @eventType, @eventData, @version)
        ''',
        substitutionValues: {
          'id': _uuid.v4(),
          'aggregateId': aggregateId,
          'eventType': eventType,
          'eventData': Jsonb(eventData),
          'version': nextVersion,
        },
      );
    });
  }

  Future<List<EventRecord>> getEvents(String aggregateId) async {
    final result = await _connection.query(
      '''
      SELECT event_type, event_data, timestamp, version
      FROM events
      WHERE aggregate_id = @aggregateId
      ORDER BY version ASC
      ''',
      substitutionValues: {'aggregateId': aggregateId},
    );

    return result.map((row) {
      return EventRecord(
        eventType: row[0] as String,
        eventData: row[1] as Map<String, dynamic>,
        timestamp: row[2] as DateTime,
        version: row[3] as int,
      );
    }).toList();
  }

  Future<Map<String, dynamic>?> getAggregateState(
    String aggregateId,
    EventHandler handler,
  ) async {
    final events = await getEvents(aggregateId);
    if (events.isEmpty) return null;

    dynamic state;
    for (final event in events) {
      state = handler(event.eventType, event.eventData, state);
    }
    return state;
  }

  Future<void> close() async {
    await _connection.close();
  }
}

class EventRecord {
  final String eventType;
  final Map<String, dynamic> eventData;
  final DateTime timestamp;
  final int version;

  EventRecord({
    required this.eventType,
    required this.eventData,
    required this.timestamp,
    required this.version,
  });
}

typedef EventHandler = dynamic Function(
  String eventType,
  Map<String, dynamic> eventData,
  dynamic currentState,
);

class ConcurrencyException implements Exception {
  final String message;
  ConcurrencyException(this.message);

  @override
  String toString() => 'ConcurrencyException: $message';
}
