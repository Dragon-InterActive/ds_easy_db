import 'repositories/database_repository.dart';

/// A mock implementation of [DatabaseRepository] for testing.
///
/// MockDatabase stores all data in memory and provides a simple way to test
/// database operations without requiring actual database connections.
///
/// Perfect for unit tests and development.
///
/// Every read hands out a copy, so a caller mutating a returned map can never
/// change what is stored — the same guarantee a real backend gives.
///
/// Example:
/// ```dart
/// db.configure(
///   prefs: MockDatabase(),
///   secure: MockDatabase(),
///   storage: MockDatabase(),
///   stream: MockStreamDatabase(),
/// );
/// ```
class MockDatabase implements DatabaseRepository {
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};

  @override
  Future<void> init() async {
    // Nothing to initialise.
  }

  Map<String, dynamic> _resolveServerTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value == DatabaseRepository.serverTS) {
        return MapEntry(key, DateTime.now());
      }
      return MapEntry(key, value);
    });
  }

  @override
  Future<void> set(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    _data.putIfAbsent(collection, () => {});
    _data[collection]![id] = _resolveServerTimestamps(data);
  }

  @override
  Future<void> update(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    _data.putIfAbsent(collection, () => {});
    final existing = _data[collection]![id] ?? <String, dynamic>{};
    _data[collection]![id] = {...existing, ..._resolveServerTimestamps(data)};
  }

  @override
  Future<Map<String, dynamic>?> get(
    String collection,
    String id, {
    dynamic defaultValue,
  }) async {
    final stored = _data[collection]?[id];
    if (stored == null) return defaultValue;
    return Map<String, dynamic>.of(stored);
  }

  @override
  Future<Map<String, dynamic>?> getAll(String collection) async {
    final collectionData = _data[collection];
    if (collectionData == null || collectionData.isEmpty) return null;
    return <String, dynamic>{
      for (final entry in collectionData.entries)
        entry.key: Map<String, dynamic>.of(entry.value),
    };
  }

  @override
  Future<bool> exists(String collection, String id) async {
    return _data[collection]?.containsKey(id) ?? false;
  }

  @override
  Future<bool> existsWhere(
    String collection, {
    required Map<String, dynamic> where,
  }) async {
    final collectionData = _data[collection];
    if (collectionData == null) return false;
    return collectionData.values.any((item) => _matches(item, where));
  }

  @override
  Future<void> delete(String collection, String id) async {
    _data[collection]?.remove(id);
  }

  /// Returns the matching documents, each with its document id under `id`.
  ///
  /// A document that carries its own `id` field keeps it.
  @override
  Future<List<Map<String, dynamic>>> query(
    String collection, {
    Map<String, dynamic> where = const {},
  }) async {
    final collectionData = _data[collection];
    if (collectionData == null) return [];

    return [
      for (final entry in collectionData.entries)
        if (_matches(entry.value, where))
          <String, dynamic>{'id': entry.key, ...entry.value},
    ];
  }

  bool _matches(Map<String, dynamic> item, Map<String, dynamic> where) {
    for (final entry in where.entries) {
      if (item[entry.key] != entry.value) return false;
    }
    return true;
  }
}
