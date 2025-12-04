# DS-EasyDB

A unified database abstraction layer for Flutter that provides a simple, consistent API across multiple storage backends.

## Features

- **Unified Interface**: Single API for all database operations
- **Multiple Backends**: Support for local and remote storage solutions
- **Plugin Architecture**: Easy to extend with custom implementations
- **Type Safety**: Strong typing with Dart's type system
- **Streaming Support**: Real-time data synchronization for supported backends
- **Mock Database**: Built-in mock implementation for testing

## Core Concepts

EasyDB organizes database implementations into four categories:

- **prefs**: Preferences/Settings storage (e.g., SharedPreferences, Hive)
- **secure**: Encrypted/Secure storage (e.g., FlutterSecureStorage)
- **storage**: Remote/Cloud storage (e.g., Firestore, REST APIs)
- **stream**: Real-time database with streaming capabilities (e.g., Firebase Realtime Database)

## Installation

Add EasyDB to your `pubspec.yaml`:

```yaml
dependencies:
  ds_easy_db: ^1.0.0
```

Then add the sub-packages you need:

```yaml
dependencies:
  ds_easy_db: ^1.0.0
  ds_easy_db_hive: ^1.0.0
  ds_easy_db_firestore: ^1.0.0
  ds_easy_db_firebase_realtime: ^1.0.0
  ds_easy_db_secure_storage: ^1.0.0
```

## Quick Start

### 1. Create Configuration File

Create a file `ds_easy_db_config.dart` in your project:

```dart
import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:ds_easy_db_hive/ds_easy_db_hive.dart';
import 'package:ds_easy_db_firestore/ds_easy_db_firestore.dart';
import 'package:ds_easy_db_firebase_realtime/ds_easy_db_firebase_realtime.dart';
import 'package:ds_easy_db_secure_storage/ds_easy_db_secure_storage.dart';

class EasyDBConfig {
  static DatabaseRepository get prefs => HiveDatabase();
  static DatabaseRepository get secure => SecureStorageDatabase();
  // Manual Firebase initialization in main()
  static DatabaseRepository get storage => FirestoreDatabase(); 
  // Automatic initialization via db.init() in main()
  static DatabaseRepository get storage => FirestoreDatabase(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  // Same for Stream Manual Firebae Realtime Database 
  static DatabaseStreamRepository get stream => FirebaseRealtimeDatabase();
  // Automatic initialization via db.init() in main()
  static DatabaseStreamRepository get stream => FirebaseRealtimeDatabase(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
```

### 2. Initialize in main.dart

```dart
import 'package:flutter/material.dart';
import 'package:ds_easy_db/ds_easy_db.dart';
import 'ds_easy_db_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  db.configure(
    prefs: EasyDBConfig.prefs,
    secure: EasyDBConfig.secure,
    storage: EasyDBConfig.storage,
    stream: EasyDBConfig.stream,
  );
  
  await db.init();
  
  runApp(MyApp());
}
```

### 3. Use Throughout Your App

```dart
import 'package:ds_easy_db/ds_easy_db.dart';

// Store user preferences
await db.prefs.set('settings', 'theme', {'mode': 'dark'});

// Store sensitive data
await db.secure.set('tokens', 'auth', {'token': 'secret123'});

// Store in cloud
await db.storage.set('users', 'user123', {
  'name': 'John Doe',
  'email': 'john@example.com',
  'createdAt': DatabaseRepository.serverTS, // Server timestamp
});

// Real-time data
db.stream.watch('users', 'user123').listen((data) {
  print('User data updated: $data');
});
```

## API Reference

### Common Operations

```dart
// Create or overwrite
await db.storage.set('collection', 'id', {'key': 'value'});

// Update existing
await db.storage.update('collection', 'id', {'key': 'newValue'});

// Read single document
final data = await db.storage.get('collection', 'id');

// Read with default value
final data = await db.storage.get('collection', 'id', defaultValue: {});

// Read all documents
final allData = await db.storage.getAll('collection');

// Check existence
final exists = await db.storage.exists('collection', 'id');

// Query with filters
final results = await db.storage.query('collection', 
  where: {'status': 'active'}
);

// Check if any document matches
final hasActive = await db.storage.existsWhere('collection',
  where: {'status': 'active'}
);

// Delete
await db.storage.delete('collection', 'id');
```

### Streaming Operations

```dart
// Watch single document
db.stream.watch('collection', 'id').listen((data) {
  print('Document updated: $data');
});

// Watch entire collection
db.stream.watchAll('collection').listen((data) {
  print('Collection updated: $data');
});

// Watch with query
db.stream.watchQuery('collection', 
  where: {'status': 'active'}
).listen((results) {
  print('Active items: ${results.length}');
});
```

### Server Timestamps

Different databases handle timestamps differently (Firestore uses `FieldValue.serverTimestamp()`, Firebase Realtime uses `ServerValue.timestamp`, local databases use `DateTime.now()`).

EasyDB solves this with `DatabaseRepository.serverTS` - a unified placeholder that automatically converts to the correct format for each database implementation:

```dart
await db.storage.set('posts', 'post123', {
  'title': 'Hello World',
  'createdAt': DatabaseRepository.serverTS, // Automatically uses correct timestamp format
  'updatedAt': DatabaseRepository.serverTS,
});

// Firestore: Converts to FieldValue.serverTimestamp()
// Firebase Realtime: Converts to ServerValue.timestamp
// Hive/Local: Converts to DateTime.now()
// API: Converts to DateTime.now() or custom implementation
```

This ensures consistent behavior across all database backends without changing your code.

## Available Sub-Packages

- **ds_easy_db_hive**: Local storage using Hive
- **ds_easy_db_shared_preferences**: Simple key-value storage
- **ds_easy_db_secure_storage**: Encrypted storage using FlutterSecureStorage
- **ds_easy_db_firestore**: Cloud Firestore integration
- **ds_easy_db_firebase_realtime**: Firebase Realtime Database with streaming
- **ds_easy_db_sqlite**: SQLite database (coming soon)

## Using Mock Database

EasyDB includes a built-in mock database for testing:

```dart
import 'package:ds_easy_db/ds_easy_db.dart';

void main() {
  db.configure(
    prefs: MockDatabase(),
    secure: MockDatabase(),
    storage: MockDatabase(),
    stream: MockStreamDatabase(), // Note: Mock doesn't support streaming
  );
  
  // No init() needed for MockDatabase
}
```

## Creating Custom Implementations

Implement the `DatabaseRepository` interface:

```dart
import 'package:ds_easy_db/ds_easy_db.dart';

class MyCustomDatabase implements DatabaseRepository {
  @override
  Future<void> init() async {
    // Initialize your database
  }

  @override
  Future<void> set(String collection, String id, Map<String, dynamic> data) async {
    // Handle server timestamp
    final processedData = data.map((key, value) {
      if (value == DatabaseRepository.serverTS) {
        return MapEntry(key, DateTime.now());
      }
      return MapEntry(key, value);
    });
    
    // Your implementation
  }

  // Implement other methods...
}
```

For streaming support, implement `DatabaseStreamRepository`:

```dart
import 'package:ds_easy_db/ds_easy_db.dart';

class MyStreamDatabase implements DatabaseStreamRepository {
  @override
  Stream<Map<String, dynamic>?> watch(String collection, String id) {
    // Return a stream of data changes
  }

  // Implement other methods...
}
```

## Best Practices

1. **Single Configuration**: Create one `ds_easy_db_config.dart` file per app
2. **Error Handling**: Always wrap database calls in try-catch blocks
3. **Testing**: Use `MockDatabase` for unit tests
4. **Security**: Never store sensitive data in `prefs`, use `secure` instead
5. **Offline-First**: Use `prefs` or `storage` based on your offline requirements

## Examples

Check out the `/example` folder for complete sample applications demonstrating:

- Basic CRUD operations
- Real-time streaming
- Offline-first architecture
- Testing with MockDatabase

## Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest features
- Submit pull requests
- Create new sub-package implementations

## License

BSD-3-Clause License - see LICENSE file for details.

Copyright (c) 2025, MasterNemo (Dragon Software)

---

Feel free to clone and extend. It's free to use and share.
