import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import '../models/bju_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _initialized = false;
  final _recordsStreamController = StreamController<void>.broadcast();

  DatabaseHelper._init();

  Stream<void> get recordsStream => _recordsStreamController.stream;

  bool get isWeb => kIsWeb;

  Future<void> _initializePlatform() async {
    if (_initialized) return;

    if (!kIsWeb) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        debugPrint('Database initialized with FFI for desktop platform');
      } else {
        debugPrint('Database initialized with standard sqflite for mobile');
      }
    } else {
      debugPrint(
          'Web platform detected - database operations will use fallback');
    }

    _initialized = true;
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite database is not supported on Web platform. '
        'Please use the app on Android, iOS, Windows, macOS, or Linux.',
      );
    }

    if (_database != null) return _database!;
    await _initializePlatform();
    _database = await _initDB('bju_calculator.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, filePath);

    debugPrint('Initializing database at: $path');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onOpen: (db) async {
        debugPrint('Database opened successfully at: $path');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint('Database upgrade from $oldVersion to $newVersion');
        if (oldVersion < 2) {
          await _addMealTypeColumn(db);
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    debugPrint('Creating database tables...');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        protein REAL NOT NULL,
        fat REAL NOT NULL,
        carbs REAL NOT NULL,
        calories REAL NOT NULL,
        emoji TEXT NOT NULL,
        isPreInstalled INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE bju_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        grams REAL NOT NULL,
        protein REAL NOT NULL,
        fat REAL NOT NULL,
        carbs REAL NOT NULL,
        calories REAL NOT NULL,
        dateTime TEXT NOT NULL,
        mealType TEXT NOT NULL DEFAULT 'Snack',
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    await _insertPreInstalledProducts(db);
    debugPrint('Database tables created successfully');
  }

  Future<void> _addMealTypeColumn(Database db) async {
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(bju_records)');
      final hasMealTypeColumn =
          tableInfo.any((column) => column['name'] == 'mealType');

      if (!hasMealTypeColumn) {
        debugPrint('Adding mealType column to bju_records table...');
        await db.execute(
            'ALTER TABLE bju_records ADD COLUMN mealType TEXT NOT NULL DEFAULT "Snack"');
        debugPrint('mealType column added successfully');
      } else {
        debugPrint('mealType column already exists');
      }
    } catch (e) {
      debugPrint('Error adding mealType column: $e');
    }
  }

  Future<void> _insertPreInstalledProducts(Database db) async {
    final products = [
      Product(
        id: 1,
        name: 'Chicken Breast',
        protein: 23.1,
        fat: 1.2,
        carbs: 0.0,
        calories: 110,
        emoji: '🍗',
        isPreInstalled: true,
      ),
      Product(
        id: 2,
        name: 'Rice (white)',
        protein: 2.7,
        fat: 0.3,
        carbs: 28.0,
        calories: 130,
        emoji: '🍚',
        isPreInstalled: true,
      ),
      Product(
        id: 3,
        name: 'Oatmeal',
        protein: 12.5,
        fat: 6.2,
        carbs: 61.0,
        calories: 350,
        emoji: '🥣',
        isPreInstalled: true,
      ),
      Product(
        id: 4,
        name: 'Eggs',
        protein: 12.7,
        fat: 10.9,
        carbs: 0.7,
        calories: 157,
        emoji: '🥚',
        isPreInstalled: true,
      ),
      Product(
        id: 5,
        name: 'Salmon',
        protein: 20.0,
        fat: 13.0,
        carbs: 0.0,
        calories: 208,
        emoji: '🐟',
        isPreInstalled: true,
      ),
      Product(
        id: 6,
        name: 'Greek Yogurt',
        protein: 10.0,
        fat: 0.0,
        carbs: 3.6,
        calories: 59,
        emoji: '🥛',
        isPreInstalled: true,
      ),
      Product(
        id: 7,
        name: 'Broccoli',
        protein: 2.8,
        fat: 0.4,
        carbs: 7.0,
        calories: 34,
        emoji: '🥦',
        isPreInstalled: true,
      ),
      Product(
        id: 8,
        name: 'Banana',
        protein: 1.1,
        fat: 0.2,
        carbs: 22.8,
        calories: 89,
        emoji: '🍌',
        isPreInstalled: true,
      ),
      Product(
        id: 9,
        name: 'Almonds',
        protein: 21.2,
        fat: 49.9,
        carbs: 21.6,
        calories: 579,
        emoji: '🥜',
        isPreInstalled: true,
      ),
      Product(
        id: 10,
        name: 'Beef',
        protein: 26.0,
        fat: 15.0,
        carbs: 0.0,
        calories: 250,
        emoji: '🥩',
        isPreInstalled: true,
      ),
      Product(
        id: 11,
        name: 'Potato',
        protein: 2.0,
        fat: 0.1,
        carbs: 17.0,
        calories: 77,
        emoji: '🥔',
        isPreInstalled: true,
      ),
      Product(
        id: 12,
        name: 'Avocado',
        protein: 2.0,
        fat: 14.7,
        carbs: 8.5,
        calories: 160,
        emoji: '🥑',
        isPreInstalled: true,
      ),
      Product(
        id: 13,
        name: 'Cheese',
        protein: 25.0,
        fat: 33.0,
        carbs: 1.3,
        calories: 402,
        emoji: '🧀',
        isPreInstalled: true,
      ),
      Product(
        id: 14,
        name: 'Apple',
        protein: 0.3,
        fat: 0.2,
        carbs: 13.8,
        calories: 52,
        emoji: '🍎',
        isPreInstalled: true,
      ),
      Product(
        id: 15,
        name: 'Bread (whole wheat)',
        protein: 13.0,
        fat: 3.5,
        carbs: 41.0,
        calories: 247,
        emoji: '🍞',
        isPreInstalled: true,
      ),
    ];

    for (var product in products) {
      await db.insert('products', product.toMap());
    }
    debugPrint('Pre-installed ${products.length} products');
  }

  Future<List<Product>> getAllProducts() async {
    if (kIsWeb) return [];

    try {
      final db = await database;
      final result = await db.query('products', orderBy: 'name');
      return result.map((json) => Product.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }

  Future<Product?> getProduct(int id) async {
    if (kIsWeb) return null;

    try {
      final db = await database;
      final maps = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Product.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting product $id: $e');
      return null;
    }
  }

  Future<int> insertProduct(Product product) async {
    if (kIsWeb) return -1;

    try {
      final db = await database;
      return await db.insert('products', product.toMap());
    } catch (e) {
      debugPrint('Error inserting product: $e');
      return -1;
    }
  }

  Future<int> updateProduct(Product product) async {
    if (kIsWeb) return 0;

    try {
      final db = await database;
      return await db.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
    } catch (e) {
      debugPrint('Error updating product: $e');
      return 0;
    }
  }

  Future<int> deleteProduct(int id) async {
    if (kIsWeb) return 0;

    try {
      final db = await database;
      return await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return 0;
    }
  }

  Future<int> insertBjuRecord(BjuRecord record) async {
    if (kIsWeb) return -1;

    try {
      final db = await database;
      final result = await db.insert('bju_records', record.toMap());
      _recordsStreamController.add(null);
      return result;
    } catch (e) {
      debugPrint('Error inserting BJU record: $e');
      return -1;
    }
  }

  Future<List<BjuRecord>> getAllBjuRecords() async {
    if (kIsWeb) return [];

    try {
      final db = await database;
      final result = await db.query('bju_records', orderBy: 'dateTime DESC');
      return result.map((json) => BjuRecord.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error getting BJU records: $e');
      return [];
    }
  }

  Future<List<BjuRecord>> getBjuRecordsByDate(DateTime date) async {
    if (kIsWeb) return [];

    try {
      final db = await database;
      final startOfDay =
          DateTime(date.year, date.month, date.day).toIso8601String();
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59)
          .toIso8601String();

      final result = await db.query(
        'bju_records',
        where: 'dateTime >= ? AND dateTime <= ?',
        whereArgs: [startOfDay, endOfDay],
        orderBy: 'dateTime DESC',
      );
      return result.map((json) => BjuRecord.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error getting BJU records by date: $e');
      return [];
    }
  }

  Future<int> deleteBjuRecord(int id) async {
    if (kIsWeb) return 0;

    try {
      final db = await database;
      final result = await db.delete(
        'bju_records',
        where: 'id = ?',
        whereArgs: [id],
      );
      _recordsStreamController.add(null);
      return result;
    } catch (e) {
      debugPrint('Error deleting BJU record: $e');
      return 0;
    }
  }

  Future<void> close() async {
    if (kIsWeb) return;

    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
        debugPrint('Database closed');
      }
    } catch (e) {
      debugPrint('Error closing database: $e');
    }
  }
}
