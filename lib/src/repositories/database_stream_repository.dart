abstract class DatabaseStreamRepository {
  Future<void> init();

  Stream<Map<String, dynamic>?> watch(String collection, String id);

  Stream<Map<String, dynamic>?> watchAll(String collection);

  Stream<List<Map<String, dynamic>>> watchQuery(
    String collection, {
    Map<String, dynamic> where = const {},
  });

  Future<void> set(String collection, String id, Map<String, dynamic> data);

  Future<void> update(String collection, String id, Map<String, dynamic> data);

  Future<void> delete(String collection, String id);
}
