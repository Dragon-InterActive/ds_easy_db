/// Abstract interface for streaming database operations.
///
/// Provides real-time data synchronization through reactive streams.
/// Ideal for databases that support live updates like Firebase Realtime Database.
abstract class DatabaseStreamRepository {
  /// Initializes the database connection and required resources.
  Future<void> init();

  /// Watches a single document for real-time updates.
  ///
  /// Returns a stream that emits the document data whenever it changes.
  /// Emits `null` if the document doesn't exist or is deleted.
  ///
  /// [collection] The collection/table name.
  /// [id] The document/record identifier.
  Stream<Map<String, dynamic>?> watch(String collection, String id);

  /// Watches an entire collection for real-time updates.
  ///
  /// Returns a stream that emits all documents in the collection whenever any changes occur.
  /// Emits `null` if the collection is empty.
  ///
  /// [collection] The collection/table name.
  Stream<Map<String, dynamic>?> watchAll(String collection);

  /// Watches documents matching specific criteria for real-time updates.
  ///
  /// Returns a stream that emits matching documents whenever they change.
  ///
  /// [collection] The collection/table name.
  /// [where] Map of field-value pairs to filter by. Empty map watches all documents.
  Stream<List<Map<String, dynamic>>> watchQuery(
    String collection, {
    Map<String, dynamic> where = const {},
  });

  /// Creates or overwrites a document in the database.
  ///
  /// [collection] The collection/table name.
  /// [id] The document/record identifier.
  /// [data] The data to store.
  Future<void> set(String collection, String id, Map<String, dynamic> data);

  /// Updates specific fields in an existing document.
  ///
  /// Only modifies the specified fields, leaving other fields unchanged.
  ///
  /// [collection] The collection/table name.
  /// [id] The document/record identifier.
  /// [data] The fields to update.
  Future<void> update(String collection, String id, Map<String, dynamic> data);

  /// Deletes a document from the database.
  ///
  /// [collection] The collection/table name.
  /// [id] The document/record identifier.
  Future<void> delete(String collection, String id);
}
