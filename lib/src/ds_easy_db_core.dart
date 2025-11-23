import 'repositories/database_repository.dart';
import 'repositories/database_stream_repository.dart';

class DSEasyDB {
  late DatabaseRepository prefs;
  late DatabaseRepository secure;
  late DatabaseRepository storage;
  late DatabaseStreamRepository stream;

  static DSEasyDB? _instance;
  static DSEasyDB get instance => _instance ??= DSEasyDB();

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

  Future<void> init() async {
    await prefs.init();
    await secure.init();
    await storage.init();
    await stream.init();
  }
}

final db = DSEasyDB.instance;
