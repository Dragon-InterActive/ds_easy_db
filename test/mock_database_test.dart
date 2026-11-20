import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockDatabase db;

  setUp(() => db = MockDatabase());

  group('MockDatabase', () {
    test('query returns the document id under "id"', () async {
      await db.set('users', 'u1', {'name': 'Ann'});

      expect(await db.query('users'), [
        {'id': 'u1', 'name': 'Ann'},
      ]);
    });

    test('a document with its own "id" field keeps it', () async {
      await db.set('users', 'u1', {'id': 'custom', 'name': 'Ann'});

      expect((await db.query('users')).single['id'], 'custom');
    });

    test('query filters with the original value types', () async {
      await db.set('users', 'u1', {'age': 30});
      await db.set('users', 'u2', {'age': '30'});

      final result = await db.query('users', where: {'age': 30});
      expect(result.map((d) => d['id']), ['u1']);
    });

    test('returned maps are copies, not the stored data', () async {
      await db.set('users', 'u1', {'name': 'Ann'});

      (await db.get('users', 'u1'))!['name'] = 'changed';
      (await db.getAll('users'))!['u1']['name'] = 'changed';
      (await db.query('users')).single['name'] = 'changed';

      expect((await db.get('users', 'u1'))!['name'], 'Ann');
    });

    test('getAll returns null once the collection is empty', () async {
      await db.set('users', 'u1', {'name': 'Ann'});
      await db.delete('users', 'u1');

      expect(await db.getAll('users'), isNull);
    });

    test('update merges and creates missing documents', () async {
      await db.update('users', 'u1', {'a': 1});
      await db.update('users', 'u1', {'b': 2});

      expect(await db.get('users', 'u1'), {'a': 1, 'b': 2});
    });

    test('serverTS becomes a DateTime', () async {
      await db.set('users', 'u1', {'at': DatabaseRepository.serverTS});

      expect((await db.get('users', 'u1'))!['at'], isA<DateTime>());
    });
  });
}
