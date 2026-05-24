import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/checklist_item.dart';
import '../models/destination.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wanderlist.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE destinations (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        country    TEXT    NOT NULL,
        category   TEXT    NOT NULL,
        status     TEXT    NOT NULL,
        notes      TEXT    NOT NULL DEFAULT '',
        photo_path TEXT,
        visited_at TEXT,
        created_at TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE checklist_items (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        destination_id INTEGER NOT NULL,
        label          TEXT    NOT NULL,
        is_done        INTEGER NOT NULL DEFAULT 0,
        created_at     TEXT    NOT NULL
      )
    ''');
  }

  // ─────────────────────────────────────────────────────────────────
  // PERSON A — CREATE + READ (list)
  // ─────────────────────────────────────────────────────────────────

  Future<int> insertDestination(Destination destination) async {
    final db = await database;
    return db.insert(
      'destinations',
      destination.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// filter: 'all' | 'wishlist' | 'visited'
  /// sortBy: 'az' | 'terbaru' | 'kategori'
  /// search: substring match on name or country
  Future<List<Destination>> getDestinations({
    String filter = 'all',
    String sortBy = 'terbaru',
    String search = '',
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (filter != 'all') {
      whereClause += 'status = ?';
      whereArgs.add(filter);
    }

    if (search.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(name LIKE ? OR country LIKE ?)';
      whereArgs.addAll(['%$search%', '%$search%']);
    }

    String orderBy;
    switch (sortBy) {
      case 'az':
        orderBy = 'name ASC';
        break;
      case 'kategori':
        orderBy = 'category ASC, name ASC';
        break;
      case 'terbaru':
      default:
        orderBy = 'created_at DESC';
    }

    final maps = await db.query(
      'destinations',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );
    return maps.map(Destination.fromMap).toList();
  }

  // ─────────────────────────────────────────────────────────────────
  // PERSON B — UPDATE + READ (detail)
  // ─────────────────────────────────────────────────────────────────

  Future<Destination?> getDestinationById(int id) async {
    final db = await database;
    final maps = await db.query(
      'destinations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Destination.fromMap(maps.first);
  }

  Future<int> updateDestination(Destination destination) async {
    final db = await database;
    return db.update(
      'destinations',
      destination.toMap(),
      where: 'id = ?',
      whereArgs: [destination.id],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // PERSON C — DELETE + READ (checklist)
  // ─────────────────────────────────────────────────────────────────

  Future<int> deleteDestination(int id) async {
    final existing = await getDestinationById(id);
    if (existing?.photoPath != null) {
      final f = File(existing!.photoPath!);
      if (await f.exists()) await f.delete();
    }
    final db = await database;
    await db.delete(
      'checklist_items',
      where: 'destination_id = ?',
      whereArgs: [id],
    );
    return db.delete('destinations', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertChecklistItem(ChecklistItem item) async {
    final db = await database;
    return db.insert('checklist_items', item.toMap());
  }

  Future<List<ChecklistItem>> getChecklistItems(int destinationId) async {
    final db = await database;
    final maps = await db.query(
      'checklist_items',
      where: 'destination_id = ?',
      whereArgs: [destinationId],
      orderBy: 'created_at ASC',
    );
    return maps.map(ChecklistItem.fromMap).toList();
  }

  Future<int> updateChecklistItem(ChecklistItem item) async {
    final db = await database;
    return db.update(
      'checklist_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteChecklistItem(int id) async {
    final db = await database;
    return db.delete('checklist_items', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────────────────────
  // Statistics — shared READ
  // ─────────────────────────────────────────────────────────────────

  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    final total = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM destinations')) ??
        0;
    final visited = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM destinations WHERE status = 'visited'")) ??
        0;
    final wishlist = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM destinations WHERE status = 'wishlist'")) ??
        0;
    final pantai = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM destinations WHERE category = 'pantai'")) ??
        0;
    final kota = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM destinations WHERE category = 'kota'")) ??
        0;
    final gunung = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM destinations WHERE category = 'gunung'")) ??
        0;
    final alam = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM destinations WHERE category = 'alam'")) ??
        0;

    return {
      'total': total,
      'visited': visited,
      'wishlist': wishlist,
      'pantai': pantai,
      'kota': kota,
      'gunung': gunung,
      'alam': alam,
    };
  }
}
