# DSEasyDB Example

## Basic Setup

```dart
import 'package:ds_easy_db/ds_easy_db.dart';
import 'package:ds_easy_db_hive/ds_easy_db_hive.dart';
import 'package:ds_easy_db_secure_storage/ds_easy_db_secure_storage.dart';
import 'package:ds_easy_db_firestore/ds_easy_db_firestore.dart';
import 'package:ds_easy_db_firebase_realtime/ds_easy_db_firebase_realtime.dart';
import 'firebase_options.dart';

void main() async {
  // Configure databases
  db.configure(
    prefs: HiveDatabase(),
    secure: SecureStorageDatabase(),
    storage: FirestoreDatabase(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    stream: FirebaseRealtimeDatabase(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
  );
  
  // Initialize
  await db.init();
  
  // Use preferences storage
  await db.prefs.set('settings', 'theme', {'mode': 'dark'});
  final theme = await db.prefs.get('settings', 'theme');
  
  // Use secure storage
  await db.secure.set('auth', 'token', {'jwt': 'eyJhbG...'});
  
  // Use cloud storage
  await db.storage.set('users', 'user123', {
    'name': 'John Doe',
    'email': 'john@example.com',
    'createdAt': DatabaseRepository.serverTS,
  });
  
  // Use streaming database
  db.stream.watch('users', 'user123').listen((user) {
    print('User updated: ${user?['name']}');
  });
}
```

## Testing with MockDatabase

```dart
import 'package:ds_easy_db/ds_easy_db.dart';

void main() async {
  // Use mock for testing
  db.configure(
    prefs: MockDatabase(),
    secure: MockDatabase(),
    storage: MockDatabase(),
    stream: MockDatabase(),
  );
  
  await db.init();
  
  // Your tests here
}
```
