import 'repositories/database_repository.dart';
import 'repositories/database_stream_repository.dart';

/// A unified database abstraction layer for Flutter.
///
/// DSEasyDB provides a consistent API across multiple storage backends including
/// local storage (Hive, SharedPreferences), secure storage, and cloud storage
/// (Firestore, Firebase Realtime Database).
///
/// Example:
/// ```dart
/// db.configure(
///   prefs: HiveDatabase(),
///   secure: SecureStorageDatabase(),
///   storage: FirestoreDatabase(),
///   stream: FirebaseRealtimeDatabase(),
/// );
/// await db.init();
/// ```
class DSEasyDB {
  /// The preferences/settings storage repository.
  ///
  /// Typically used for app settings, user preferences, and cached data.
  late DatabaseRepository prefs;

  /// The secure storage repository for sensitive data.
  ///
  /// Use this for storing tokens, passwords, API keys, and other sensitive information.
  late DatabaseRepository secure;

  /// The main storage repository (typically cloud storage).
  ///
  /// Used for primary app data, user-generated content, and persistent storage.
  late DatabaseRepository storage;

  /// The streaming database repository for real-time data.
  ///
  /// Provides live updates and real-time synchronization across clients.
  late DatabaseStreamRepository stream;

  static DSEasyDB? _instance;

  /// Returns the singleton instance of DSEasyDB.
  static DSEasyDB get instance => _instance ??= DSEasyDB();

  /// Configures the database repositories.
  ///
  /// This must be called before [init]. Each repository parameter is required
  /// and should be initialized with the appropriate implementation.
  ///
  /// Example:
  /// ```dart
  /// db.configure(
  ///   prefs: HiveDatabase(),
  ///   secure: SecureStorageDatabase(),
  ///   storage: FirestoreDatabase(options: DefaultFirebaseOptions.currentPlatform),
  ///   stream: FirebaseRealtimeDatabase(options: DefaultFirebaseOptions.currentPlatform),
  /// );
  /// `
  void configure({
    required DatabaseRepository prefs,
    required DatabaseRepository secure,
    required DatabaseRepository storage,
    required DatabaseStreamRepository stream,
  }) {
    this.prefs = prefs;
    this.secure = secure;
    this.storage = storage;
    this.stream = stream;
  }

  /// Initializes all configured database repositories.
  ///
  /// Must be called after [configure] and before using any database operations.
  ///
  /// Example:
  /// ```dart
  /// await db.init();
  /// ```
  Future<void> init() async {
    await prefs.init();
    await secure.init();
    await storage.init();
    await stream.init();
  }
}

/// Global singleton instance for easy access throughout the app.
///
/// Example:
/// ```dart
/// await db.storage.set('users', 'user123', {'name': 'John'});
/// final user = await db.storage.get('users', 'user123');
/// ```
final db = DSEasyDB.instance;
