import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

/// Web implementation: sets the sqflite database factory to use
/// sql.js (SQLite compiled to WebAssembly) via IndexedDB persistence.
Future<void> initDatabaseFactory() async {
  databaseFactory = databaseFactoryFfiWeb;
}
