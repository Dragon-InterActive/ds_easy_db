abstract class DatabaseRepository {
  static const serverTS = '__TS__';

  Future<void> init();

  Future<void> set(String collection, String id, Map<String, dynamic> data);

  Future<void> update(String collection, String id, Map<String, dynamic> data);

  Future<Map<String, dynamic>?> get(
    String collection,
    String id, {
    dynamic defaultValue,
  });

  Future<Map<String, dynamic>?> getAll(String collection);

  Future<bool> exists(String collection, String id);

  Future<bool> existsWhere(
    String collection, {
    required Map<String, dynamic> where,
  });

  Future<void> delete(String collection, String id);

  Future<List<Map<String, dynamic>>> query(
    String collection, {
    Map<String, dynamic> where = const {},
  });
}
