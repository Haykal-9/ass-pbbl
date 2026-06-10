import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/budget_item.dart';
import '../models/checklist_item.dart';
import '../models/destination.dart';
import '../models/destination_photo.dart';

final ValueNotifier<int> budgetChangedNotifier = ValueNotifier<int>(0);

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
    if (kIsWeb) {
      return databaseFactoryFfiWebNoWebWorker.openDatabase(
        'wanderlist.db',
        options: OpenDatabaseOptions(
          version: 7,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'wanderlist.db');
      return openDatabase(
        path,
        version: 7,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  /// Schema shared by fresh installs (v2) and upgrades from v1.
  static const String _createBudgetTable = '''
    CREATE TABLE budget_items (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      destination_id INTEGER NOT NULL,
      label          TEXT    NOT NULL,
      category       TEXT    NOT NULL DEFAULT 'lainnya',
      amount         REAL    NOT NULL DEFAULT 0,
      created_at     TEXT    NOT NULL
    )
  ''';

  static const String _createDestinationPhotosTable = '''
    CREATE TABLE destination_photos (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      destination_id INTEGER NOT NULL,
      photo_path     TEXT    NOT NULL,
      caption        TEXT,
      created_at     TEXT    NOT NULL,
      FOREIGN KEY(destination_id) REFERENCES destinations(id) ON DELETE CASCADE
    )
  ''';

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(_createBudgetTable);
    }
    if (oldVersion < 3) {
      // Migrate Marina Bay Sands to 'in_trip'
      await db.update(
        'destinations',
        {'status': 'in_trip'},
        where: 'name = ?',
        whereArgs: ['Marina Bay Sands'],
      );
      
      final dests = await db.query(
        'destinations',
        columns: ['id'],
        where: 'name = ?',
        whereArgs: ['Marina Bay Sands'],
      );
      if (dests.isNotEmpty) {
        final destId = dests.first['id'] as int;
        final items = await db.query(
          'checklist_items',
          columns: ['id'],
          where: 'destination_id = ?',
          whereArgs: [destId],
          orderBy: 'id ASC',
          limit: 2,
        );
        for (var item in items) {
          await db.update(
            'checklist_items',
            {'is_done': 1},
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        }
      }
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE checklist_items ADD COLUMN order_index INTEGER DEFAULT 0');
      // Set existing items order_index to their id to maintain creation order
      await db.execute('UPDATE checklist_items SET order_index = id');
    }
    if (oldVersion < 7) {
      // 1. Update contextual notes to emotional/logical reasons
      final updates = {
        'Raja Ampat': 'Ingin merasakan keajaiban berenang langsung bersama pari manta di alam yang belum tersentuh.',
        'Taman Nasional Komodo': 'Perjalanan ini membuatku takjub bisa melihat langsung naga purba di habitat aslinya yang menakjubkan.',
        'Gunung Fuji': 'Bermimpi bisa berdiri di kaki gunung suci ini sambil melihat sakura bermekaran.',
        'Air Terjun Niagara': 'Ingin merasakan langsung gemuruh dan percikan air dari salah satu air terjun paling bertenaga di bumi.',
        'Taman Nasional Yellowstone': 'Sangat penasaran melihat keajaiban warna-warni Grand Prismatic Spring dari dekat.',
        'Candi Borobudur': 'Merinding rasanya menyentuh relief kuno ini saat matahari terbit di ufuk timur.',
        'Angkor Wat': 'Ingin menyusuri lorong-lorong batu tua dan merasakan aura magis dari sisa kejayaan Kerajaan Khmer.',
        'Colosseum': 'Berdiri di arena ini membuatku bisa membayangkan gemuruh sorak sorai penonton Romawi ribuan tahun lalu.',
        'Machu Picchu': 'Mendaki pegunungan Andes untuk menemukan kota Inca yang hilang adalah salah satu impian terbesar dalam hidupku.',
        'Tembok Besar China': 'Berharap suatu hari nanti kakiku bisa menjejakkan langkah di atas sejarah pertahanan manusia terpanjang ini.',
        'Burj Khalifa': 'Ingin berdiri di atas awan dan melihat betapa kecilnya dunia dari gedung tertinggi yang pernah dibangun.',
        'Menara Eiffel': 'Menikmati lampu berkelap-kelip dari bawah menara ini benar-benar terasa seperti berada di adegan film romantis.',
        'Shibuya Crossing': 'Tak terlupakan sensasinya menyeberang bersama lautan manusia di persimpangan paling sibuk sedunia ini.',
        'Marina Bay Sands': 'Akhirnya bisa bersantai di infinity pool ikonik ini sambil memandangi cakrawala Singapura!',
        'Times Square': 'Energi kota yang tak pernah tidur ini benar-benar membuatku merasa hidup dan bebas.',
      };
      
      for (final entry in updates.entries) {
        await db.update(
          'destinations',
          {'notes': entry.value},
          where: 'name = ?',
          whereArgs: [entry.key],
        );
      }

      // 2. Create destination_photos table and migrate
      await db.execute(_createDestinationPhotosTable);
      
      final destinations = await db.query('destinations');
      final now = DateTime.now().toIso8601String();
      for (final dest in destinations) {
        final destId = dest['id'] as int;
        final photoPath = dest['photo_path'] as String?;
        if (photoPath != null && photoPath.isNotEmpty) {
          await db.insert('destination_photos', {
            'destination_id': destId,
            'photo_path': photoPath,
            'caption': 'Foto Utama',
            'created_at': now,
          });
        }
      }

      // 3. Seed dummy deck for Raja Ampat (id=1)
      await db.insert('destination_photos', {
        'destination_id': 1,
        'photo_path': 'https://images.unsplash.com/photo-1544550581-5f7ceaf7f992?q=80&w=600',
        'caption': 'Spot Diving Pertama',
        'created_at': now,
      });
      await db.insert('destination_photos', {
        'destination_id': 1,
        'photo_path': 'https://images.unsplash.com/photo-1552554030-ad3b1e39a3f2?q=80&w=600',
        'caption': 'Sunset di Resort',
        'created_at': now,
      });
    }
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
        order_index    INTEGER NOT NULL DEFAULT 0,
        created_at     TEXT    NOT NULL
      )
    ''');

    await db.execute(_createBudgetTable);
    await db.execute(_createDestinationPhotosTable);

    final now = DateTime.now().toIso8601String();
    final seeds = [
      "('Raja Ampat', 'Sorong, Indonesia', 'Wisata Alam', 'wishlist', 'Ingin merasakan keajaiban berenang langsung bersama pari manta di alam yang belum tersentuh.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/Raja_Ampat%2C_West_Papua%2C_Indonesia.jpg/960px-Raja_Ampat%2C_West_Papua%2C_Indonesia.jpg', '$now')",
      "('Taman Nasional Komodo', 'Labuan Bajo, Indonesia', 'Wisata Alam', 'visited', 'Perjalanan ini membuatku takjub bisa melihat langsung naga purba di habitat aslinya yang menakjubkan.', 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?q=80&w=600', '$now')",
      "('Gunung Fuji', 'Shizuoka, Jepang', 'Wisata Alam', 'wishlist', 'Bermimpi bisa berdiri di kaki gunung suci ini sambil melihat sakura bermekaran.', 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?q=80&w=600', '$now')",
      "('Air Terjun Niagara', 'Ontario, Kanada', 'Wisata Alam', 'wishlist', 'Ingin merasakan langsung gemuruh dan percikan air dari salah satu air terjun paling bertenaga di bumi.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/3Falls_Niagara.jpg/960px-3Falls_Niagara.jpg', '$now')",
      "('Taman Nasional Yellowstone', 'Wyoming, Amerika Serikat', 'Wisata Alam', 'wishlist', 'Sangat penasaran melihat keajaiban warna-warni Grand Prismatic Spring dari dekat.', 'https://upload.wikimedia.org/wikipedia/commons/7/73/Grand_Canyon_of_yellowstone.jpg', '$now')",
      "('Candi Borobudur', 'Magelang, Indonesia', 'Budaya & Sejarah', 'visited', 'Merinding rasanya menyentuh relief kuno ini saat matahari terbit di ufuk timur.', 'https://images.unsplash.com/photo-1596402184320-417e7178b2cd?q=80&w=600', '$now')",
      "('Angkor Wat', 'Siem Reap, Kamboja', 'Budaya & Sejarah', 'wishlist', 'Ingin menyusuri lorong-lorong batu tua dan merasakan aura magis dari sisa kejayaan Kerajaan Khmer.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Buddhist_monks_in_front_of_the_Angkor_Wat.jpg/960px-Buddhist_monks_in_front_of_the_Angkor_Wat.jpg', '$now')",
      "('Colosseum', 'Roma, Italia', 'Budaya & Sejarah', 'visited', 'Berdiri di arena ini membuatku bisa membayangkan gemuruh sorak sorai penonton Romawi ribuan tahun lalu.', 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?q=80&w=600', '$now')",
      "('Machu Picchu', 'Cusco, Peru', 'Budaya & Sejarah', 'wishlist', 'Mendaki pegunungan Andes untuk menemukan kota Inca yang hilang adalah salah satu impian terbesar dalam hidupku.', 'https://images.unsplash.com/photo-1526392060635-9d6019884377?q=80&w=600', '$now')",
      "('Tembok Besar China', 'Beijing, China', 'Budaya & Sejarah', 'wishlist', 'Berharap suatu hari nanti kakiku bisa menjejakkan langkah di atas sejarah pertahanan manusia terpanjang ini.', 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?q=80&w=600', '$now')",
      "('Burj Khalifa', 'Dubai, UAE', 'Kota & Urban', 'wishlist', 'Ingin berdiri di atas awan dan melihat betapa kecilnya dunia dari gedung tertinggi yang pernah dibangun.', 'https://images.unsplash.com/photo-1582672060674-bc2bd808a8b5?q=80&w=600', '$now')",
      "('Menara Eiffel', 'Paris, Prancis', 'Kota & Urban', 'visited', 'Menikmati lampu berkelap-kelip dari bawah menara ini benar-benar terasa seperti berada di adegan film romantis.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg/960px-Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg', '$now')",
      "('Shibuya Crossing', 'Tokyo, Jepang', 'Kota & Urban', 'visited', 'Tak terlupakan sensasinya menyeberang bersama lautan manusia di persimpangan paling sibuk sedunia ini.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Shibuya_skyline_from_Tokyu_Plaza_in_Omotesando%2C_Harajuku%2C_Tokyo%2C_2024_May.jpg/960px-Shibuya_skyline_from_Tokyu_Plaza_in_Omotesando%2C_Harajuku%2C_Tokyo%2C_2024_May.jpg', '$now')",
      "('Marina Bay Sands', 'Singapura, Singapura', 'Kota & Urban', 'in_trip', 'Akhirnya bisa bersantai di infinity pool ikonik ini sambil memandangi cakrawala Singapura!', 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?q=80&w=600', '$now')",
      "('Times Square', 'New York, Amerika Serikat', 'Kota & Urban', 'visited', 'Energi kota yang tak pernah tidur ini benar-benar membuatku merasa hidup dan bebas.', 'https://images.unsplash.com/photo-1534430480872-3498386e7856?q=80&w=600', '$now')"
    ];

    for (var val in seeds) {
      await db.execute('''
        INSERT INTO destinations (name, country, category, status, notes, photo_path, created_at)
        VALUES $val
      ''');
    }

    final checklistSeeds = {
      1: ['Snorkeling di Cape Kri', 'Island hopping ke Wayag', 'Foto dari Piaynemo viewpoint', 'Sunset di dermaga'],
      2: ['Lihat komodo langsung', 'Snorkeling di Pink Beach', 'Hiking ke Padar Island viewpoint', 'Foto manta ray'],
      3: ['Pendakian ke puncak', 'Foto dari Danau Kawaguchiko', 'Lihat matahari terbit', 'Kunjungi Chureito Pagoda'],
      4: ['Naik Maid of the Mist', 'Journey Behind the Falls', 'Foto dari Prospect Point', 'Lihat illuminasi malam'],
      5: ['Lihat Old Faithful meletus', 'Grand Prismatic Spring', 'Wildlife spotting bison', 'Canyon viewpoint'],
      6: ['Sunrise tour', 'Naik ke stupa utama', 'Baca relief Karmawibhangga', 'Museum Samudra Raksa'],
      7: ['Foto sunrise di kolam refleksi', 'Jelajahi Ta Prohm', 'Bayon temple 216 wajah', 'Angkor Thom'],
      8: ['Tur lantai arena gladiator', 'Roman Forum', 'Palatine Hill', 'Foto dari Arch of Constantine'],
      9: ['Trekking Inca Trail', 'Sun Gate viewpoint', 'Pendakian Huayna Picchu', 'Foto iconic terrace'],
      10: ['Jalan di seksi Mutianyu', 'Foto panorama', 'Naik cable car', 'Stamp paspor khusus'],
      11: ['At the Top observation deck', 'Dubai Fountain show', 'Dubai Mall', 'Foto skyline malam'],
      12: ['Naik ke puncak', 'Foto dari Trocadéro', 'Makan di Le Jules Verne', 'Light show tengah malam'],
      13: ['Foto dari Starbucks lantai 2', 'Scramble crossing', 'Shibuya Sky rooftop', 'Belanja di Shibuya 109'],
      14: ['Observation deck SkyPark', 'Spectra laser show', 'Casino', 'Foto skyline dari waterfront'],
      15: ['Foto malam hari neon signs', 'Tonton Broadway show', 'TKTS discount booth', 'Naik double decker bus'],
    };

    final visitedIds = {2, 6, 8, 12, 13, 15};

    for (final entry in checklistSeeds.entries) {
      final destId = entry.key;
      final items = entry.value;
      final defaultIsDone = visitedIds.contains(destId) ? 1 : 0;
      
      for (int i = 0; i < items.length; i++) {
        final label = items[i];
        int itemIsDone = defaultIsDone;
        if (destId == 14 && i < 2) {
          itemIsDone = 1; // Marina Bay Sands: checklist 2/4 done
        }
        await db.execute('''
          INSERT INTO checklist_items (destination_id, label, is_done, created_at)
          VALUES ($destId, '$label', $itemIsDone, '$now')
        ''');
      }
    }

    // Insert photo seeds
    final photoSeeds = [
      "1, 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/Raja_Ampat%2C_West_Papua%2C_Indonesia.jpg/960px-Raja_Ampat%2C_West_Papua%2C_Indonesia.jpg', 'Foto Utama'",
      "1, 'https://images.unsplash.com/photo-1544550581-5f7ceaf7f992?q=80&w=600', 'Spot Diving Pertama'",
      "1, 'https://images.unsplash.com/photo-1552554030-ad3b1e39a3f2?q=80&w=600', 'Sunset di Resort'",
      "2, 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?q=80&w=600', 'Foto Utama'",
      "3, 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?q=80&w=600', 'Foto Utama'",
      "4, 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/3Falls_Niagara.jpg/960px-3Falls_Niagara.jpg', 'Foto Utama'",
      "5, 'https://upload.wikimedia.org/wikipedia/commons/7/73/Grand_Canyon_of_yellowstone.jpg', 'Foto Utama'",
      "6, 'https://images.unsplash.com/photo-1596402184320-417e7178b2cd?q=80&w=600', 'Foto Utama'",
      "7, 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Buddhist_monks_in_front_of_the_Angkor_Wat.jpg/960px-Buddhist_monks_in_front_of_the_Angkor_Wat.jpg', 'Foto Utama'",
      "8, 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?q=80&w=600', 'Foto Utama'",
      "9, 'https://images.unsplash.com/photo-1526392060635-9d6019884377?q=80&w=600', 'Foto Utama'",
      "10, 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?q=80&w=600', 'Foto Utama'",
      "11, 'https://images.unsplash.com/photo-1582672060674-bc2bd808a8b5?q=80&w=600', 'Foto Utama'",
      "12, 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg/960px-Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg', 'Foto Utama'",
      "13, 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Shibuya_skyline_from_Tokyu_Plaza_in_Omotesando%2C_Harajuku%2C_Tokyo%2C_2024_May.jpg/960px-Shibuya_skyline_from_Tokyu_Plaza_in_Omotesando%2C_Harajuku%2C_Tokyo%2C_2024_May.jpg', 'Foto Utama'",
      "14, 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?q=80&w=600', 'Foto Utama'",
      "15, 'https://images.unsplash.com/photo-1534430480872-3498386e7856?q=80&w=600', 'Foto Utama'"
    ];
    for (var val in photoSeeds) {
      await db.execute('''
        INSERT INTO destination_photos (destination_id, photo_path, caption, created_at)
        VALUES ($val, '$now')
      ''');
    }
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
      columns: [
        '*',
        '(SELECT COUNT(*) FROM checklist_items WHERE destination_id = destinations.id) AS checklist_total',
        '(SELECT IFNULL(SUM(is_done), 0) FROM checklist_items WHERE destination_id = destinations.id) AS checklist_done'
      ],
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
    if (destination.id == null) return 0;

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
    if (existing?.photoPath != null && !kIsWeb) {
      final f = File(existing!.photoPath!);
      if (await f.exists()) await f.delete();
    }
    final db = await database;
    return await db.transaction((txn) async {
      await txn.delete(
        'checklist_items',
        where: 'destination_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'budget_items',
        where: 'destination_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'destination_photos',
        where: 'destination_id = ?',
        whereArgs: [id],
      );
      return await txn.delete('destinations', where: 'id = ?', whereArgs: [id]);
    });
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
      orderBy: 'order_index ASC, id ASC',
    );
    return maps.map(ChecklistItem.fromMap).toList();
  }

  Future<int> updateChecklistItem(ChecklistItem item) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.update(
        'checklist_items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    });
  }

  Future<int> deleteChecklistItem(int id) async {
    final db = await database;
    return db.delete('checklist_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateChecklistOrder(List<ChecklistItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var item in items) {
        await txn.update(
          'checklist_items',
          {'order_index': item.orderIndex},
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // Budget — estimasi budget wisata (CRUD)
  // ─────────────────────────────────────────────────────────────────

  Future<int> insertBudgetItem(BudgetItem item) async {
    final db = await database;
    final id = await db.insert('budget_items', item.toMap());
    if (id > 0) budgetChangedNotifier.value++;
    return id;
  }

  Future<List<BudgetItem>> getBudgetItems(int destinationId) async {
    final db = await database;
    final maps = await db.query(
      'budget_items',
      where: 'destination_id = ?',
      whereArgs: [destinationId],
      orderBy: 'created_at ASC',
    );
    return maps.map(BudgetItem.fromMap).toList();
  }

  Future<int> updateBudgetItem(BudgetItem item) async {
    final db = await database;
    final count = await db.update(
      'budget_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    if (count > 0) budgetChangedNotifier.value++;
    return count;
  }

  Future<int> deleteBudgetItem(int id) async {
    final db = await database;
    final count = await db.delete(
      'budget_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count > 0) budgetChangedNotifier.value++;
    return count;
  }

  /// Total estimated budget (in base currency, IDR) for one destination.
  Future<double> getDestinationBudgetTotal(int destinationId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT IFNULL(SUM(amount), 0) AS total FROM budget_items WHERE destination_id = ?',
      [destinationId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Grand total estimated budget (in base currency, IDR) across all
  /// destinations.
  Future<double> getTotalBudget() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT IFNULL(SUM(amount), 0) AS total FROM budget_items',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // ─────────────────────────────────────────────────────────────────
  // Statistics — shared READ
  // ─────────────────────────────────────────────────────────────────

  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    final total = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM destinations')) ??
        0;
    final inTrip = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM destinations WHERE status = 'in_trip'")) ??
        0;
    final visited = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM destinations WHERE status = 'visited'")) ??
        0;
    final wishlist = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM destinations WHERE status = 'wishlist'")) ??
        0;
    final wisataAlam = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM destinations WHERE category = 'Wisata Alam'")) ??
        0;
    final budayaSejarah = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM destinations WHERE category = 'Budaya & Sejarah'")) ??
        0;
    final kotaUrban = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM destinations WHERE category = 'Kota & Urban'")) ??
        0;

    return {
      'total': total,
      'in_trip': inTrip,
      'visited': visited,
      'wishlist': wishlist,
      'wisata_alam': wisataAlam,
      'budaya_sejarah': budayaSejarah,
      'kota_urban': kotaUrban,
    };
  }

  // ─────────────────────────────────────────────────────────────────
  // DESTINATION PHOTOS CRUD
  // ─────────────────────────────────────────────────────────────────

  Future<int> insertDestinationPhoto(DestinationPhoto photo) async {
    final db = await database;
    return db.insert('destination_photos', photo.toMap());
  }

  Future<List<DestinationPhoto>> getDestinationPhotos(int destinationId) async {
    final db = await database;
    final maps = await db.query(
      'destination_photos',
      where: 'destination_id = ?',
      whereArgs: [destinationId],
      orderBy: 'created_at ASC, id ASC',
    );
    return maps.map(DestinationPhoto.fromMap).toList();
  }

  Future<void> deleteDestinationPhoto(int id) async {
    final db = await database;
    final maps = await db.query('destination_photos', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final photoPath = maps.first['photo_path'] as String;
      if (!photoPath.startsWith('http') && !kIsWeb) {
        final f = File(photoPath);
        if (await f.exists()) await f.delete();
      }
    }
    await db.delete(
      'destination_photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
