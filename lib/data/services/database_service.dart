import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/constants.dart';
import '../models/hidden_photo.dart';

class DatabaseService {
  static const String tablePhotos = 'hidden_photos';
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tablePhotos (
            id TEXT PRIMARY KEY,
            encrypted_path TEXT NOT NULL,
            original_name TEXT NOT NULL,
            date_added INTEGER NOT NULL,
            file_size INTEGER NOT NULL,
            width INTEGER,
            height INTEGER
          )
        ''');
      },
    );
  }

  Future<int> insertPhoto(HiddenPhoto photo) async {
    final db = await database;
    return await db.insert(
      tablePhotos,
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HiddenPhoto>> getAllPhotos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePhotos,
      orderBy: 'date_added DESC',
    );
    return maps.map((map) => HiddenPhoto.fromMap(map)).toList();
  }

  Future<HiddenPhoto?> getPhotoById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePhotos,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return HiddenPhoto.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deletePhoto(String id) async {
    final db = await database;
    return await db.delete(
      tablePhotos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllPhotos() async {
    final db = await database;
    return await db.delete(tablePhotos);
  }

  Future<int> getPhotoCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tablePhotos');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
