import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockStreamDatabase db;

  setUp(() => db = MockStreamDatabase());
  tearDown(() => db.dispose());

  /// Lets queued stream events reach their listeners.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('watchQuery', () {
    test('keeps matching numeric filters after a write', () async {
      final events = <int>[];
      db.watchQuery('users',
          where: {'age': 30}).listen((list) => events.add(list.length));

      await settle();
      await db.set('users', 'u1', {'age': 30});
      await settle();

      expect(events, [0, 1]);
    });

    test('emits exactly once per write, also without a filter', () async {
      final events = <int>[];
      db.watchQuery('users').listen((list) => events.add(list.length));

      await settle();
      await db.set('users', 'u1', {'age': 30});
      await settle();

      expect(events, [0, 1]);
    });

    test('ignores writes to other collections', () async {
      final events = <int>[];
      db.watchQuery('users').listen((list) => events.add(list.length));

      await settle();
      await db.set('orders', 'o1', {'total': 1});
      await settle();

      expect(events, [0]);
    });

    test('includes the document id', () async {
      await db.set('users', 'u1', {'name': 'Ann'});

      expect(await db.watchQuery('users').first, [
        {'id': 'u1', 'name': 'Ann'},
      ]);
    });
  });

  group('watch and watchAll', () {
    test('a late subscriber receives the current value', () async {
      await db.set('users', 'u1', {'name': 'Ann'});

      expect(await db.watch('users', 'u1').first, {'name': 'Ann'});
      expect(await db.watchAll('users').first, {
        'u1': {'name': 'Ann'},
      });
    });

    test('a new subscriber does not replay events to existing ones', () async {
      final first = <Map<String, dynamic>?>[];
      db.watch('users', 'u1').listen(first.add);
      await settle();

      db.watch('users', 'u1').listen((_) {});
      await settle();

      expect(first, [null]);
    });

    test('delete emits null for the document and the empty collection',
        () async {
      await db.set('users', 'u1', {'name': 'Ann'});
      final doc = <Map<String, dynamic>?>[];
      final all = <Map<String, dynamic>?>[];
      db.watch('users', 'u1').listen(doc.add);
      db.watchAll('users').listen(all.add);
      await settle();

      await db.delete('users', 'u1');
      await settle();

      expect(doc.last, isNull);
      expect(all.last, isNull);
    });
  });
}
