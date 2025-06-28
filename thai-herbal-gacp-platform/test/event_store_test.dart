import 'package:test/test.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:thai_herbal_gacp_backend/event_ledger/event_store.dart';

void main() {
  group('EventStore', () {
    late PostgreSQLConnection connection;
    late EventStore eventStore;
    const connectionString = 'postgres://user:pass@localhost:5432/test_db';

    setUpAll(() async {
      connection = PostgreSQLConnection.fromConnectionString(connectionString);
      await connection.open();
      await connection.execute('DROP TABLE IF EXISTS events');
    });

    setUp(() async {
      eventStore = EventStore(connectionString);
      await eventStore.init();
    });

    tearDown(() async {
      await connection.execute('TRUNCATE TABLE events RESTART IDENTITY');
    });

    tearDownAll(() async {
      await connection.close();
    });

    test('Save and retrieve events', () async {
      const aggregateId = 'agg_123';
      final eventData = {'name': 'Test Event', 'value': 42};

      // Save event
      await eventStore.saveEvent(
        aggregateId,
        'TestEvent',
        eventData,
      );

      // Retrieve events
      final events = await eventStore.getEvents(aggregateId);

      expect(events, hasLength(1));
      expect(events[0].eventType, 'TestEvent');
      expect(events[0].eventData, eventData);
    });

    test('Optimistic concurrency control', () async {
      const aggregateId = 'agg_456';
      final eventData1 = {'step': 1};
      final eventData2 = {'step': 2};

      // Save first event
      await eventStore.saveEvent(
        aggregateId,
        'Step1',
        eventData1,
        expectedVersion: 0,
      );

      // Should succeed
      await eventStore.saveEvent(
        aggregateId,
        'Step2',
        eventData2,
        expectedVersion: 1,
      );

      // Should fail
      expect(
        () => eventStore.saveEvent(
          aggregateId,
          'Step3',
          {'step': 3},
          expectedVersion: 1, // Actual is 2
        ),
        throwsA(isA<ConcurrencyException>()),
      );
    });

    test('Rebuild aggregate state', () async {
      const aggregateId = 'agg_789';
      final events = [
        {
          'type': 'Created',
          'data': {'name': 'Initial', 'value': 0},
        },
        {
          'type': 'Updated',
          'data': {'value': 1},
        },
        {
          'type': 'Updated',
          'data': {'value': 2},
        },
      ];

      // Save events
      for (final event in events) {
        await eventStore.saveEvent(
          aggregateId,
          event['type'] as String,
          event['data'] as Map<String, dynamic>,
        );
      }

      // Define event handler
      dynamic handler(String eventType, Map<String, dynamic> eventData, currentState) {
        final state = currentState ?? {'name': '', 'value': 0};
        
        switch (eventType) {
          case 'Created':
            return {
              'name': eventData['name'],
              'value': eventData['value'],
            };
          case 'Updated':
            return {
              ...state,
              'value': eventData['value'],
            };
          default:
            return state;
        }
      }

      // Rebuild state
      final state = await eventStore.getAggregateState(aggregateId, handler);

      expect(state, isNotNull);
      expect(state['name'], 'Initial');
      expect(state['value'], 2);
    });
  });
}
