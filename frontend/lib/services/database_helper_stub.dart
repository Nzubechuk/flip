/// Stub implementation for non-web platforms.
/// On mobile, sqflite works out of the box - no factory initialization needed.
Future<void> initDatabaseFactory() async {
  // No-op on mobile platforms - sqflite uses native SQLite
}
