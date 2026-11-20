import 'dart:async';
import 'repositories/database_repository.dart';
import 'repositories/database_stream_repository.dart';

/// A mock implementation of [DatabaseStreamRepository] for testing.
///
/// MockStreamDatabase stores all data in memory and provides reactive streams
/// that emit updates when data changes. Perfect for unit tests and development
/// without requiring actual streaming database connections.
///
/// Every listener receives the current value as soon as it subscribes, and
/// afterwards one event per change. Emitted maps are copies, so listeners
/// cannot alter the stored data.
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

  final Map<String, _Watch<Map<String, dynamic>?>> _docWatches = {};
  final Map<String, _Watch<Map<String, dynamic>?>> _collectionWatches = {};
  final List<_QueryWatch> _queryWatches = [];

  @override
  Future<void> init() async {
    // Nothing to do
  }

  // ------------------------------------------------------------- snapshots

  Map<String, dynamic>? _documentSnapshot(String collection, String id) {
    final stored = _data[collection]?[id];
    return stored == null ? null : Map<String, dynamic>.of(stored);
  }

  Map<String, dynamic>? _collectionSnapshot(String collection) {
    final collectionData = _data[collection];
    if (collectionData == null || collectionData.isEmpty) return null;
    return <String, dynamic>{
      for (final entry in collectionData.entries)
        entry.key: Map<String, dynamic>.of(entry.value),
    };
  }

  List<Map<String, dynamic>> _querySnapshot(
    String collection,
    Map<String, dynamic> where,
  ) {
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

  // --------------------------------------------------------------- watches

  @override
  Stream<Map<String, dynamic>?> watch(String collection, String id) {
    final watch = _docWatches.putIfAbsent(
      '$collection\u0000$id',
      () => _Watch(() => _documentSnapshot(collection, id)),
    );
    return watch.stream;
  }

  @override
  Stream<Map<String, dynamic>?> watchAll(String collection) {
    final watch = _collectionWatches.putIfAbsent(
      collection,
      () => _Watch(() => _collectionSnapshot(collection)),
    );
    return watch.stream;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchQuery(
    String collection, {
    Map<String, dynamic> where = const {},
  }) {
    // The filter is kept as the original map: turning it into a string key and
    // parsing it back would change value types (30 would become '30').
    final filter = Map<String, dynamic>.of(where);
    final watch = _QueryWatch(
      collection,
      () => _querySnapshot(collection, filter),
    );
    _queryWatches.add(watch);
    return watch.stream;
  }

  void _notifyWatchers(String collection, String id) {
    _docWatches['$collection\u0000$id']?.emit();
    _collectionWatches[collection]?.emit();
    for (final watch in _queryWatches) {
      if (watch.collection == collection) watch.emit();
    }
  }

  // ---------------------------------------------------------------- writes

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

    _notifyWatchers(collection, id);
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

    _notifyWatchers(collection, id);
  }

  @override
  Future<void> delete(String collection, String id) async {
    _data[collection]?.remove(id);

    _notifyWatchers(collection, id);
  }

  /// Closes all stream controllers. Call this in tests cleanup.
  void dispose() {
    for (final watch in _docWatches.values) {
      watch.close();
    }
    for (final watch in _collectionWatches.values) {
      watch.close();
    }
    for (final watch in _queryWatches) {
      watch.close();
    }
    _docWatches.clear();
    _collectionWatches.clear();
    _queryWatches.clear();
  }
}

/// One watched value: a broadcast source of changes plus a snapshot function,
/// so that each new listener starts with the current value instead of whatever
/// happened to be emitted before it subscribed.
class _Watch<T> {
  _Watch(this._snapshot);

  final T Function() _snapshot;
  final StreamController<T> _changes = StreamController<T>.broadcast();

  Stream<T> get stream => Stream<T>.multi((listener) {
        listener.add(_snapshot());
        final subscription = _changes.stream.listen(
          listener.add,
          onError: listener.addError,
          onDone: listener.close,
        );
        listener.onCancel = subscription.cancel;
      });

  void emit() {
    if (_changes.hasListener) _changes.add(_snapshot());
  }

  void close() => _changes.close();
}

class _QueryWatch extends _Watch<List<Map<String, dynamic>>> {
  _QueryWatch(this.collection, super.snapshot);

  final String collection;
}
