import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/sale.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'flip_pos.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        price REAL,
        stock INTEGER,
        productCode TEXT,
        upc TEXT,
        ean13 TEXT,
        branchId TEXT,
        branchName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemsJson TEXT,
        branchId TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_debts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        consumerName TEXT,
        itemsJson TEXT,
        branchId TEXT,
        createdAt TEXT
      )
    ''');
  }

  // Product Operations
  Future<void> saveProducts(List<Product> products) async {
    final db = await database;
    Batch batch = db.batch();
    for (var product in products) {
      batch.insert(
        'products',
        {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'stock': product.stock,
          'productCode': product.productCode,
          'upc': product.upc,
          'ean13': product.ean13,
          'branchId': product.branchId,
          'branchName': product.branchName,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Product>> getProducts(String branchId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'branchId = ?',
      whereArgs: [branchId],
    );
    return List.generate(maps.length, (i) {
      return Product.fromJson(maps[i]);
    });
  }

  Future<Product?> getProductByCode(String code) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'productCode = ? OR upc = ? OR ean13 = ? OR id = ?',
      whereArgs: [code, code, code, code],
    );
    if (maps.isNotEmpty) {
      return Product.fromJson(maps[0]);
    }
    return null;
  }

  // Pending Sales Operations
  Future<int> queueSale(List<SaleItem> items, String branchId) async {
    final db = await database;
    return await db.insert('pending_sales', {
      'itemsJson': jsonEncode(items.map((i) => i.toJson()).toList()),
      'branchId': branchId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSales() async {
    final db = await database;
    return await db.query('pending_sales');
  }

  Future<void> deletePendingSale(int id) async {
    final db = await database;
    await db.delete('pending_sales', where: 'id = ?', whereArgs: [id]);
  }

  // Pending Debts Operations
  Future<int> queueDebt(String consumerName, List<SaleItem> items, String branchId) async {
    final db = await database;
    return await db.insert('pending_debts', {
      'consumerName': consumerName,
      'itemsJson': jsonEncode(items.map((i) => i.toJson()).toList()),
      'branchId': branchId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingDebts() async {
    final db = await database;
    return await db.query('pending_debts');
  }

  Future<void> deletePendingDebt(int id) async {
    final db = await database;
    await db.delete('pending_debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('products');
    await db.delete('pending_sales');
    await db.delete('pending_debts');
  }
}
