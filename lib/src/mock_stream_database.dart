import 'dart:async';
import 'repositories/database_repository.dart';
import 'repositories/database_stream_repository.dart';

/// A mock implementation of [DatabaseStreamRepository] for testing.
///
/// MockStreamDatabase stores all data in memory and provides reactive streams
/// that emit updates when data changes. Perfect for unit tests and development
/// without requiring actual streaming database connections.
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
class MockStreamDatabase implements DatabaseStreamRepository {
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};
  final Map<String, StreamController<Map<String, dynamic>?>> _watchControllers = {};
  final Map<String, StreamController<Map<String, dynamic>?>> _watchAllControllers = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>> _queryControllers = {};

  @override
  Future<void> init() async {
    // Nothing to do
  }

  String _getWatchKey(String collection, String id) => '$collection:$id';
  String _getWatchAllKey(String collection) => '$collection:*';
  String _getQueryKey(String collection, Map<String, dynamic> where) {
    final whereStr = where.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$collection?$whereStr';
  }

  @override
  Stream<Map<String, dynamic>?> watch(String collection, String id) {
    final key = _getWatchKey(collection, id);
    
    if (!_watchControllers.containsKey(key)) {
      _watchControllers[key] = StreamController<Map<String, dynamic>?>.broadcast();
    }
    
    // Emit current value immediately
    Future.microtask(() {
      if (_watchControllers.containsKey(key)) {
        _watchControllers[key]?.add(_data[collection]?[id]);
      }
    });
    
    return _watchControllers[key]!.stream;
  }

  @override
  Stream<Map<String, dynamic>?> watchAll(String collection) {
    final key = _getWatchAllKey(collection);
    
    if (!_watchAllControllers.containsKey(key)) {
      _watchAllControllers[key] = StreamController<Map<String, dynamic>?>.broadcast();
    }
    
    // Emit current value immediately
    Future.microtask(() {
      if (_watchAllControllers.containsKey(key)) {
        _watchAllControllers[key]?.add(_data[collection]);
      }
    });
    
    return _watchAllControllers[key]!.stream;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchQuery(
    String collection, {
    Map<String, dynamic> where = const {},
  }) {
    final key = _getQueryKey(collection, where);
    
    if (!_queryControllers.containsKey(key)) {
      _queryControllers[key] = StreamController<List<Map<String, dynamic>>>.broadcast();
    }
    
    // Emit current value immediately
    Future.microtask(() {
      if (_queryControllers.containsKey(key)) {
        _queryControllers[key]?.add(_queryData(collection, where));
      }
    });
    
    return _queryControllers[key]!.stream;
  }

  List<Map<String, dynamic>> _queryData(String collection, Map<String, dynamic> where) {
    if (!_data.containsKey(collection)) return [];

    final collectionData = _data[collection]!;

    if (where.isEmpty) {
      return collectionData.entries.map((e) {
        final item = Map<String, dynamic>.from(e.value);
        item['id'] = e.key;
        return item;
      }).toList();
    }

    return collectionData.entries.where((entry) {
      final item = entry.value;
      for (var whereEntry in where.entries) {
        if (item[whereEntry.key] != whereEntry.value) return false;
      }
      return true;
    }).map((e) {
      final item = Map<String, dynamic>.from(e.value);
      item['id'] = e.key;
      return item;
    }).toList();
  }

  void _notifyWatchers(String collection, String id) {
    // Notify specific watch
    final watchKey = _getWatchKey(collection, id);
    if (_watchControllers.containsKey(watchKey)) {
      _watchControllers[watchKey]?.add(_data[collection]?[id]);
    }
    
    // Notify watchAll
    final watchAllKey = _getWatchAllKey(collection);
    if (_watchAllControllers.containsKey(watchAllKey)) {
      _watchAllControllers[watchAllKey]?.add(_data[collection]);
    }
    
    // Notify all queries for this collection
    final queryPrefix = '$collection?';
    for (var key in _queryControllers.keys) {
      if (key.startsWith(queryPrefix)) {
        final where = _parseQueryKey(key);
        _queryControllers[key]?.add(_queryData(collection, where));
      }
    }
    
    // Also notify queries with empty where
    final emptyQueryKey = _getQueryKey(collection, {});
    if (_queryControllers.containsKey(emptyQueryKey)) {
      _queryControllers[emptyQueryKey]?.add(_queryData(collection, {}));
    }
  }

  Map<String, dynamic> _parseQueryKey(String key) {
    final parts = key.split('?');
    if (parts.length < 2) return {};
    
    final queryString = parts[1];
    if (queryString.isEmpty) return {};
    
    final where = <String, dynamic>{};
    for (var pair in queryString.split('&')) {
      final kv = pair.split('=');
      if (kv.length == 2) {
        where[kv[0]] = kv[1];
      }
    }
    return where;
  }

  @override
  Future<void> set(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final processedData = data.map((key, value) {
      if (value == DatabaseRepository.serverTS) {
        return MapEntry(key, DateTime.now());
      }
      return MapEntry(key, value);
    });

    _data.putIfAbsent(collection, () => {});
    _data[collection]![id] = processedData;
    
    _notifyWatchers(collection, id);
  }

  @override
  Future<void> update(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    final processedData = data.map((key, value) {
      if (value == DatabaseRepository.serverTS) {
        return MapEntry(key, DateTime.now());
      }
      return MapEntry(key, value);
    });

    _data.putIfAbsent(collection, () => {});
    final existing = _data[collection]![id] ?? <String, dynamic>{};
    final updated = {...existing, ...processedData};
    _data[collection]![id] = updated;
    
    _notifyWatchers(collection, id);
  }

  @override
  Future<void> delete(String collection, String id) async {
    _data[collection]?.remove(id);
    
    _notifyWatchers(collection, id);
  }

  /// Closes all stream controllers. Call this in tests cleanup.
  void dispose() {
    for (var controller in _watchControllers.values) {
      controller.close();
    }
    for (var controller in _watchAllControllers.values) {
      controller.close();
    }
    for (var controller in _queryControllers.values) {
      controller.close();
    }
    _watchControllers.clear();
    _watchAllControllers.clear();
    _queryControllers.clear();
  }
}
