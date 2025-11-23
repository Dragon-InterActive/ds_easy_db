/// Abstract interface for database operations.
///
/// Provides a unified API for CRUD operations across different storage backends.
/// Implementations should handle platform-specific details while maintaining
/// consistent behavior.
abstract class DatabaseRepository {
  /// Placeholder for server-side timestamps.
  ///
  /// Use this value when setting timestamp fields. It will be automatically
  /// converted to the appropriate server timestamp for each database:
  /// - Firestore: `FieldValue.serverTimestamp()`
  /// - Firebase Realtime: `ServerValue.timestamp`
  /// - Local databases: `DateTime.now()`
  static const serverTS = '__TS__';

  /// Initializes the database connection and required resources.
  Future<void> init();

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

  /// Retrieves a document from the database.
  ///
  /// Returns `null` if the document doesn't exist, or [defaultValue] if provided.
  ///
  /// [collection] The collection/table name.
  /// [id] The document/record identifier.
  /// [defaultValue] Optional default value if document doesn't exist.
  Future<Map<String, dynamic>?> get(
    String collection,
    String id, {
    dynamic defaultValue,
  });

  /// Retrieves all documents from a collection.
  ///
  /// Returns a map where keys are document IDs and values are the document data.
  /// Returns `null` if the collection is empty.
  ///
  /// [collection] The collection/table name.
  Future<Map<String, dynamic>?> getAll(String collection);

  /// Checks if a document exists.
  ///
  /// [collection] The collection/table name.
  /// [id] The document/record identifier.
  Future<bool> exists(String collection, String id);

  /// Checks if any document matches the given criteria.
  ///
  /// [collection] The collection/table name.
  /// [where] Map of field-value pairs to match.
  Future<bool> existsWhere(
    String collection, {
    required Map<String, dynamic> where,
  });

  /// Deletes a document from the database.
  ///
  /// [collection] The collection/table name.
  /// [id] The document/record identifier.
  Future<void> delete(String collection, String id);

  /// Queries documents matching the specified criteria.
  ///
  /// Returns a list of documents that match all field-value pairs in [where].
  ///
  /// [collection] The collection/table name.
  /// [where] Map of field-value pairs to filter by. Empty map returns all documents.
  Future<List<Map<String, dynamic>>> query(
    String collection, {
    Map<String, dynamic> where = const {},
  });
}
