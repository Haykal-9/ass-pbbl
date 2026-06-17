import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/budget_item.dart';
import '../models/checklist_item.dart';
import '../models/destination.dart';
import '../models/destination_photo.dart';
import '../models/gallery_feed_item.dart';
import '../models/trip_stop.dart';

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
          version: 17,
          onCreate: (db, version) async {
            await _onCreate(db, version);
            await _seedV9DummyTripStops(db);
          },
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'wanderlist.db');
      return openDatabase(
        path,
        version: 17,
        onCreate: (db, version) async {
            await _onCreate(db, version);
            await _seedV9DummyTripStops(db);
        },
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

  static const String _createTripStopsTable = '''
    CREATE TABLE trip_stops (
      id                         INTEGER PRIMARY KEY AUTOINCREMENT,
      destination_id             INTEGER NOT NULL,
      day_number                 INTEGER NOT NULL DEFAULT 1,
      order_index                INTEGER NOT NULL DEFAULT 0,
      place_name                 TEXT    NOT NULL,
      place_address              TEXT,
      latitude                   REAL,
      longitude                  REAL,
      photo_url                  TEXT,
      opening_hours              TEXT,
      description                TEXT,
      otm_xid                    TEXT,
      visit_time                 TEXT,
      end_time                   TEXT,
      estimated_duration_minutes INTEGER DEFAULT 60,
      transport_mode             TEXT    DEFAULT 'walk',
      distance_meters            REAL,
      travel_minutes             INTEGER,
      is_basecamp                INTEGER DEFAULT 0,
      created_at                 TEXT    NOT NULL,
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

    // ── v8: Trip Planner — add coordinates, dates, and trip_stops table ──
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE destinations ADD COLUMN start_date TEXT');
      await db.execute('ALTER TABLE destinations ADD COLUMN end_date TEXT');
      await db.execute('ALTER TABLE destinations ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE destinations ADD COLUMN longitude REAL');

      await db.execute(_createTripStopsTable);

      // Hardcode coordinates for the 15 seed destinations
      final coordUpdates = <String, Map<String, double>>{
        'Raja Ampat':                {'lat': -0.2353,  'lng': 130.5257},
        'Taman Nasional Komodo':     {'lat': -8.5500,  'lng': 119.4800},
        'Gunung Fuji':               {'lat': 35.3606,  'lng': 138.7278},
        'Air Terjun Niagara':        {'lat': 43.0962,  'lng': -79.0377},
        'Taman Nasional Yellowstone':{'lat': 44.4280,  'lng': -110.5885},
        'Candi Borobudur':           {'lat': -7.6079,  'lng': 110.2038},
        'Angkor Wat':                {'lat': 13.4125,  'lng': 103.8670},
        'Colosseum':                 {'lat': 41.8902,  'lng': 12.4922},
        'Machu Picchu':              {'lat': -13.1631, 'lng': -72.5450},
        'Tembok Besar China':        {'lat': 40.4319,  'lng': 116.5704},
        'Burj Khalifa':              {'lat': 25.1972,  'lng': 55.2744},
        'Menara Eiffel':             {'lat': 48.8584,  'lng': 2.2945},
        'Shibuya Crossing':          {'lat': 35.6580,  'lng': 139.7016},
        'Marina Bay Sands':          {'lat': 1.2838,   'lng': 103.8607},
        'Times Square':              {'lat': 40.7580,  'lng': -73.9855},
      };
      for (final entry in coordUpdates.entries) {
        await db.update(
          'destinations',
          {'latitude': entry.value['lat'], 'longitude': entry.value['lng']},
          where: 'name = ?',
          whereArgs: [entry.key],
        );
      }
    }

    // ── v9: Seed dummy trip stops & dates for map route testing ──
    if (oldVersion < 9) {
      await _seedV9DummyTripStops(db);
    }

    // ── v10: Add is_basecamp column to trip_stops ──
    if (oldVersion < 10) {
      await db.execute('ALTER TABLE trip_stops ADD COLUMN is_basecamp INTEGER DEFAULT 0');
    }

    // ── v11: Update Borobudur Basecamp Address ──
    if (oldVersion < 11) {
      await db.update(
        'trip_stops',
        {
          'place_address': 'Jl. Syailendra Raya, Borobudur, Magelang, Jawa Tengah 56553',
          'opening_hours': 'Check-in: 14:00 - Check-out: 12:00',
        },
        where: 'place_name = ?',
        whereArgs: ['The Omah Borobudur'],
      );
    }

    // ── v12: Full re-seed to apply addresses to all 15 destinations ──
    if (oldVersion < 12) {
      await db.delete('trip_stops');
      await _seedV9DummyTripStops(db);
    }

    // ── v13: Apply manual 'estimated_duration_minutes' from dummy data ──
    if (oldVersion < 13) {
      await db.delete('trip_stops');
      await _seedV9DummyTripStops(db);
    }

    // ── v14: Add end_time explicit column ──
    if (oldVersion < 14) {
      await db.execute('ALTER TABLE trip_stops ADD COLUMN end_time TEXT');
    }

    // ── v15: Re-seed dummy stops with end_time and remove opening_hours ──
    if (oldVersion < 15) {
      await db.delete('trip_stops');
      await _seedV9DummyTripStops(db);
    }

    // ── v16: Re-seed dummy stops for Candi Borobudur end_time tweak ──
    if (oldVersion < 16) {
      await db.delete('trip_stops');
      await _seedV9DummyTripStops(db);
    }

    // ── v17: Re-seed dummy stops to correct Borobudur logical timeline ──
    if (oldVersion < 17) {
      await db.delete('trip_stops');
      await _seedV9DummyTripStops(db);
    }
  }

  Future<void> _seedV9DummyTripStops(Database db) async {
    final now = DateTime.now().toIso8601String();

    Future<int?> getId(String name) async {
      final r = await db.query('destinations', columns: ['id'], where: 'name = ?', whereArgs: [name]);
      return r.isNotEmpty ? r.first['id'] as int : null;
    }

    Future<void> seed(String destName, String startDate, String endDate, List<Map<String, dynamic>> stops) async {
      final id = await getId(destName);
      if (id == null) return;
      await db.update('destinations', {'start_date': startDate, 'end_date': endDate}, where: 'id = ?', whereArgs: [id]);
      for (var i = 0; i < stops.length; i++) {
        final s = stops[i];
        final isBc = s['bc'] == 1;
        await db.insert('trip_stops', {
          'destination_id': id, 'day_number': 1, 'order_index': isBc ? -1 : i,
          'place_name': s['n'], 'place_address': s['a'], 'opening_hours': s['oh'], 'latitude': s['la'], 'longitude': s['lo'],
          'visit_time': s['t'], 'end_time': s['et'], 'transport_mode': s['m'] ?? 'walk',
          'distance_meters': s['d'], 'travel_minutes': s['min'],
          'estimated_duration_minutes': s['ed'] ?? 60,
          'photo_url': s['p'], 'is_basecamp': isBc ? 1 : 0, 'created_at': now,
        });
      }
    }

    // 1. Raja Ampat (wishlist)
    await seed('Raja Ampat', '2027-08-01', '2027-08-07', [
      {'n': 'Meridian Adventure Marina', 'a': 'Waisai, Raja Ampat Regency, West Papua', 'la': -0.4287, 'lo': 130.8166, 't': '07:00', 'et': '08:00', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Pianemo Islands', 'a': 'Groot Fam, Saukabu, Raja Ampat Regency', 'la': -0.2553, 'lo': 130.4757, 't': '08:00', 'et': '09:00', 'm': 'transit', 'd': 20000.0, 'min': 30, 'p': 'https://images.unsplash.com/photo-1516690561799-46d8f74f9abf?q=80&w=600'},
      {'n': 'Wayag Lagoon', 'a': 'Waigeo Barat Kepulauan, Raja Ampat', 'la': -0.1553, 'lo': 130.0557, 't': '11:00', 'et': '12:00', 'm': 'transit', 'd': 48000.0, 'min': 90, 'p': 'https://images.unsplash.com/photo-1570789210967-2cac24ba7b34?q=80&w=600'},
      {'n': 'Arborek Village', 'a': 'Arborek, Meos Mansar, Raja Ampat', 'la': -0.4953, 'lo': 130.4057, 't': '16:00', 'et': '17:00', 'm': 'transit', 'd': 30000.0, 'min': 60, 'p': 'https://images.unsplash.com/photo-1573790387438-4da905039392?q=80&w=600'},
    ]);

    // 2. Taman Nasional Komodo (visited)
    await seed('Taman Nasional Komodo', '2025-05-10', '2025-05-14', [
      {'n': 'Ayana Komodo Resort', 'a': 'Pantai Waecicu, Labuan Bajo, Kabupaten Manggarai Barat', 'la': -8.4900, 'lo': 119.8700, 't': '06:30', 'et': '07:30', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Pulau Komodo', 'a': 'Pulau Komodo, Area', 'la': -8.5550, 'lo': 119.4447, 't': '07:30', 'et': '08:30', 'm': 'transit', 'd': 50000.0, 'min': 60, 'p': 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?q=80&w=600'},
      {'n': 'Pink Beach', 'a': 'Pulau Komodo, Kabupaten Manggarai Barat', 'la': -8.5800, 'lo': 119.4900, 't': '11:00', 'et': '12:00', 'm': 'transit', 'd': 8000.0, 'min': 25, 'p': 'https://images.unsplash.com/photo-1577717903315-1691ae25ab3f?q=80&w=600'},
      {'n': 'Pulau Padar', 'a': 'Taman Nasional Komodo, Kabupaten Manggarai Barat', 'la': -8.6500, 'lo': 119.5700, 't': '14:30', 'et': '15:30', 'm': 'transit', 'd': 15000.0, 'min': 45, 'p': 'https://images.unsplash.com/photo-1571366343168-631c5bcca7a4?q=80&w=600'},
    ]);

    // 3. Gunung Fuji (wishlist)
    await seed('Gunung Fuji', '2027-04-05', '2027-04-12', [
      {'n': 'Hoshinoya Fuji', 'a': '1408 Oishi, Fujikawaguchiko, Minamitsuru District, Yamanashi', 'la': 35.5181, 'lo': 138.7488, 't': '07:30', 'et': '08:30', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Lake Kawaguchi', 'a': 'Fujikawaguchiko, Minamitsuru District, Yamanashi', 'la': 35.5171, 'lo': 138.7518, 't': '08:00', 'et': '09:00', 'm': 'drive', 'd': 500.0, 'min': 5, 'p': 'https://images.unsplash.com/photo-1578271887552-5ac3a72752bc?q=80&w=600'},
      {'n': 'Chureito Pagoda', 'a': '3353-1 Arakura, Fujiyoshida, Yamanashi', 'la': 35.5015, 'lo': 138.8016, 't': '10:30', 'et': '11:30', 'm': 'drive', 'd': 12000.0, 'min': 30, 'p': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=600'},
      {'n': 'Fuji 5th Station', 'a': 'Naruzawa, Minamitsuru District, Yamanashi', 'la': 35.3956, 'lo': 138.7314, 't': '14:00', 'et': '15:00', 'm': 'drive', 'd': 25000.0, 'min': 60, 'p': 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?q=80&w=600'},
    ]);

    // 4. Air Terjun Niagara (wishlist)
    await seed('Air Terjun Niagara', '2027-07-20', '2027-07-24', [
      {'n': 'Sheraton Fallsview', 'a': '5875 Falls Ave, Niagara Falls, ON', 'la': 43.0888, 'lo': -79.0722, 't': '08:30', 'et': '09:30', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Horseshoe Falls', 'a': 'Niagara Falls, ON L2G 0L0', 'la': 43.0799, 'lo': -79.0747, 't': '09:00', 'et': '10:00', 'm': 'walk', 'd': 1500.0, 'min': 20, 'p': 'https://images.unsplash.com/photo-1489447068241-b3490214e879?q=80&w=600'},
      {'n': 'Maid of the Mist', 'a': '1 Prospect St, Niagara Falls, NY', 'la': 43.0862, 'lo': -79.0677, 't': '11:00', 'et': '12:00', 'm': 'walk', 'd': 1200.0, 'min': 15, 'p': 'https://images.unsplash.com/photo-1533094602577-198d3beefb09?q=80&w=600'},
      {'n': 'Skylon Tower', 'a': '5200 Robinson St, Niagara Falls, ON', 'la': 43.0862, 'lo': -79.0767, 't': '14:00', 'et': '15:00', 'm': 'walk', 'd': 800.0, 'min': 10, 'p': 'https://images.unsplash.com/photo-1503614472-8c93d56e92ce?q=80&w=600'},
    ]);

    // 5. Taman Nasional Yellowstone (wishlist)
    await seed('Taman Nasional Yellowstone', '2027-09-01', '2027-09-08', [
      {'n': 'Old Faithful Inn', 'a': '3200 Old Faithful Inn Rd, Yellowstone National Park, WY', 'la': 44.4599, 'lo': -110.8286, 't': '08:00', 'et': '09:00', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Old Faithful Geyser', 'a': 'Yellowstone National Park, WY 82190', 'la': 44.4605, 'lo': -110.8281, 't': '08:30', 'et': '09:30', 'm': 'walk', 'd': 500.0, 'min': 5, 'p': 'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?q=80&w=600'},
      {'n': 'Grand Prismatic Spring', 'a': 'Midway Geyser Basin, Yellowstone National Park, WY', 'la': 44.5251, 'lo': -110.8382, 't': '11:00', 'et': '12:00', 'm': 'drive', 'd': 10000.0, 'min': 20, 'p': 'https://images.unsplash.com/photo-1607265605788-62cbff45a56b?q=80&w=600'},
      {'n': 'Yellowstone Lake', 'a': 'Yellowstone National Park, WY', 'la': 44.4235, 'lo': -110.3541, 't': '15:00', 'et': '16:00', 'm': 'drive', 'd': 45000.0, 'min': 50, 'p': 'https://images.unsplash.com/photo-1529439322271-42931c09bce1?q=80&w=600'},
    ]);

    // 6. Candi Borobudur (visited)
    await seed('Candi Borobudur', '2025-03-15', '2025-03-18', [
      {'n': 'The Omah Borobudur', 'a': 'Jl. Syailendra Raya, Borobudur, Magelang, Jawa Tengah 56553', 'la': -7.6085, 'lo': 110.1985, 't': '05:00', 'et': '05:15', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Candi Borobudur', 'a': 'Jl. Badrawati, Kw. Candi Borobudur, Borobudur, Magelang', 'la': -7.6076, 'lo': 110.2058, 't': '05:30', 'et': '08:30', 'm': 'walk', 'd': 600.0, 'min': 8, 'ed': 180, 'p': 'https://images.unsplash.com/photo-1596402184320-417e7178b2cd?q=80&w=600'},
      {'n': 'Candi Pawon', 'a': 'Brojonalan, Dusun 1, Wanurejo, Borobudur, Magelang', 'la': -7.6050, 'lo': 110.2120, 't': '09:00', 'et': '10:00', 'm': 'walk', 'd': 1800.0, 'min': 22, 'ed': 60, 'p': 'https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?q=80&w=600'},
      {'n': 'Candi Mendut', 'a': 'Jl. Mayor Kusen, Sumberrejo, Mendut, Mungkid, Magelang', 'la': -7.6042, 'lo': 110.2275, 't': '10:45', 'et': '15:00', 'm': 'walk', 'd': 2500.0, 'min': 30, 'ed': 255, 'p': 'https://images.unsplash.com/photo-1565018054866-968e244671af?q=80&w=600'},
    ]);

    // 7. Angkor Wat (wishlist)
    await seed('Angkor Wat', '2027-11-10', '2027-11-15', [
      {'n': 'Raffles Grand Hotel', 'a': '1 Vithei, Charles De Gaulle, Krong Siem Reap', 'la': 13.3615, 'lo': 103.8596, 't': '04:30', 'et': '05:30', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Angkor Wat', 'a': 'Krong Siem Reap, Cambodia', 'la': 13.4125, 'lo': 103.8670, 't': '05:00', 'et': '06:00', 'm': 'drive', 'd': 6000.0, 'min': 15, 'p': 'https://images.unsplash.com/photo-1600100397608-de38c1e7a76d?q=80&w=600'},
      {'n': 'Bayon Temple', 'a': 'Angkor Thom, Siem Reap', 'la': 13.4412, 'lo': 103.8590, 't': '09:30', 'et': '10:30', 'm': 'drive', 'd': 3500.0, 'min': 10, 'p': 'https://images.unsplash.com/photo-1569321172437-42c82e4c6d5e?q=80&w=600'},
      {'n': 'Ta Prohm', 'a': 'Angkor Archaeological Park, Siem Reap', 'la': 13.4351, 'lo': 103.8890, 't': '13:00', 'et': '14:00', 'm': 'drive', 'd': 4000.0, 'min': 12, 'p': 'https://images.unsplash.com/photo-1567422145765-0bf6b3aa7e15?q=80&w=600'},
    ]);

    // 8. Colosseum (visited)
    await seed('Colosseum', '2025-06-20', '2025-06-25', [
      {'n': 'Hotel Forum Rome', 'a': 'Hotel Forum Rome, Area', 'la': 41.8940, 'lo': 12.4870, 't': '08:30', 'et': '09:30', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Colosseum', 'a': 'Piazza del Colosseo, 1, 00184 Roma RM, Italy', 'la': 41.8902, 'lo': 12.4922, 't': '09:00', 'et': '10:00', 'm': 'walk', 'd': 800.0, 'min': 10, 'p': 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?q=80&w=600'},
      {'n': 'Roman Forum', 'a': 'Via della Salara Vecchia, 5/6, 00186 Roma RM', 'la': 41.8925, 'lo': 12.4853, 't': '11:30', 'et': '12:30', 'm': 'walk', 'd': 700.0, 'min': 10, 'p': 'https://images.unsplash.com/photo-1604580864964-0462f5d5b1a8?q=80&w=600'},
      {'n': 'Trevi Fountain', 'a': 'Trevi Fountain, Area', 'la': 41.9009, 'lo': 12.4833, 't': '14:30', 'et': '15:30', 'm': 'walk', 'd': 1400.0, 'min': 17, 'p': 'https://images.unsplash.com/photo-1525874684015-58379d421a52?q=80&w=600'},
    ]);

    // 9. Machu Picchu (wishlist)
    await seed('Machu Picchu', '2027-06-01', '2027-06-06', [
      {'n': 'Belmond Sanctuary Lodge', 'a': 'Belmond Sanctuary Lodge, Area', 'la': -13.1558, 'lo': -72.5369, 't': '05:30', 'et': '06:30', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Sun Gate (Intipunku)', 'a': 'Sun Gate (Intipunku), Area', 'la': -13.1553, 'lo': -72.5350, 't': '06:00', 'et': '07:00', 'm': 'walk', 'd': 2500.0, 'min': 45, 'p': 'https://images.unsplash.com/photo-1526392060635-9d6019884377?q=80&w=600'},
      {'n': 'Temple of the Sun', 'a': 'Temple of the Sun, Area', 'la': -13.1636, 'lo': -72.5451, 't': '09:30', 'et': '10:30', 'm': 'walk', 'd': 1200.0, 'min': 20, 'p': 'https://images.unsplash.com/photo-1580619305218-8423a7ef79b4?q=80&w=600'},
      {'n': 'Huayna Picchu', 'a': 'Machu Picchu 08680, Peru', 'la': -13.1553, 'lo': -72.5480, 't': '13:00', 'et': '14:00', 'm': 'walk', 'd': 1500.0, 'min': 60, 'p': 'https://images.unsplash.com/photo-1587595431973-160d0d94add1?q=80&w=600'},
    ]);

    // 10. Tembok Besar China (wishlist)
    await seed('Tembok Besar China', '2027-10-01', '2027-10-06', [
      {'n': 'Commune by the Great Wall', 'a': 'Commune by the Great Wall, Area', 'la': 40.3235, 'lo': 116.0270, 't': '07:30', 'et': '08:30', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Badaling Section', 'a': 'Badaling Section, Area', 'la': 40.3539, 'lo': 116.0048, 't': '08:00', 'et': '09:00', 'm': 'drive', 'd': 15000.0, 'min': 30, 'p': 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?q=80&w=600'},
      {'n': 'Mutianyu Section', 'a': 'Mutianyu Section, Area', 'la': 40.4319, 'lo': 116.5704, 't': '13:00', 'et': '14:00', 'm': 'drive', 'd': 55000.0, 'min': 70, 'p': 'https://images.unsplash.com/photo-1597655601841-214a4cfe8b2c?q=80&w=600'},
    ]);

    // 11. Burj Khalifa (wishlist)
    await seed('Burj Khalifa', '2027-12-20', '2027-12-25', [
      {'n': 'Armani Hotel Dubai', 'a': 'Burj Khalifa, Downtown Dubai, Dubai', 'la': 25.1972, 'lo': 55.2744, 't': '08:30', 'et': '09:30', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Burj Khalifa Observation', 'a': 'Burj Khalifa Observation, Area', 'la': 25.1972, 'lo': 55.2744, 't': '09:00', 'et': '10:00', 'm': 'walk', 'd': 200.0, 'min': 3, 'p': 'https://images.unsplash.com/photo-1582672060674-bc2bd808a8b5?q=80&w=600'},
      {'n': 'Dubai Fountain', 'a': 'Sheikh Mohammed bin Rashid Blvd, Downtown Dubai', 'la': 25.1952, 'lo': 55.2747, 't': '12:00', 'et': '13:00', 'm': 'walk', 'd': 400.0, 'min': 5, 'p': 'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?q=80&w=600'},
      {'n': 'Dubai Mall Aquarium', 'a': 'Dubai Mall Aquarium, Area', 'la': 25.1976, 'lo': 55.2790, 't': '15:00', 'et': '16:00', 'm': 'walk', 'd': 600.0, 'min': 8, 'p': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=600'},
    ]);

    // 12. Menara Eiffel (visited)
    await seed('Menara Eiffel', '2025-10-10', '2025-10-15', [
      {'n': 'Pullman Paris Tour Eiffel', 'a': '18 Avenue De Suffren, 75015 Paris', 'la': 48.8550, 'lo': 2.2930, 't': '08:30', 'et': '09:30', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Louvre Museum', 'a': 'Rue de Rivoli, 75001 Paris, France', 'la': 48.8606, 'lo': 2.3376, 't': '09:00', 'et': '10:00', 'm': 'walk', 'd': 1200.0, 'min': 15, 'p': 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?q=80&w=600'},
      {'n': 'Menara Eiffel', 'a': 'Menara Eiffel, Area', 'la': 48.8584, 'lo': 2.2945, 't': '12:30', 'et': '13:30', 'm': 'transit', 'd': 3500.0, 'min': 25, 'p': 'https://images.unsplash.com/photo-1543349689-9a4d426bee8e?q=80&w=600'},
      {'n': 'Arc de Triomphe', 'a': 'Arc de Triomphe, Area', 'la': 48.8738, 'lo': 2.2950, 't': '16:00', 'et': '17:00', 'm': 'walk', 'd': 2000.0, 'min': 25, 'p': 'https://images.unsplash.com/photo-1509439581779-6298f75bf6e5?q=80&w=600'},
    ]);

    // 13. Shibuya Crossing (visited)
    await seed('Shibuya Crossing', '2025-11-05', '2025-11-10', [
      {'n': 'Shibuya Excel Hotel Tokyu', 'a': '1-12-2 Dogenzaka, Shibuya City, Tokyo', 'la': 35.6580, 'lo': 139.6990, 't': '09:30', 'et': '10:30', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Shibuya Crossing', 'a': 'Dogenzaka, Shibuya City, Tokyo 150-0043', 'la': 35.6580, 'lo': 139.7016, 't': '10:00', 'et': '11:00', 'm': 'walk', 'd': 200.0, 'min': 3, 'p': 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?q=80&w=600'},
      {'n': 'Meiji Shrine', 'a': 'Meiji Shrine, Area', 'la': 35.6764, 'lo': 139.6993, 't': '13:00', 'et': '14:00', 'm': 'walk', 'd': 2000.0, 'min': 25, 'p': 'https://images.unsplash.com/photo-1583766395091-2eb9994ed094?q=80&w=600'},
      {'n': 'Sensoji Temple', 'a': 'Sensoji Temple, Area', 'la': 35.7148, 'lo': 139.7967, 't': '16:00', 'et': '17:00', 'm': 'transit', 'd': 12000.0, 'min': 30, 'p': 'https://images.unsplash.com/photo-1570521462033-3015e76e7432?q=80&w=600'},
    ]);

    // 14. Marina Bay Sands (in_trip)
    await seed('Marina Bay Sands', '2026-06-15', '2026-06-20', [
      {'n': 'Marina Bay Sands Hotel', 'a': '10 Bayfront Ave, Singapore 018956', 'la': 1.2838, 'lo': 103.8590, 't': '09:00', 'et': '10:00', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Marina Bay Sands', 'a': 'Marina Bay Sands, Area', 'la': 1.2838, 'lo': 103.8607, 't': '09:30', 'et': '10:30', 'm': 'walk', 'd': 800.0, 'min': 10, 'p': 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?q=80&w=600'},
      {'n': 'Gardens by the Bay', 'a': '18 Marina Gardens Dr, Singapore 018953', 'la': 1.2816, 'lo': 103.8636, 't': '12:00', 'et': '13:00', 'm': 'walk', 'd': 1500.0, 'min': 20, 'p': 'https://images.unsplash.com/photo-1506161488156-f947bc6309bb?q=80&w=600'},
      {'n': 'Merlion Park', 'a': '1 Fullerton Rd, Singapore 049213', 'la': 1.2868, 'lo': 103.8545, 't': '15:00', 'et': '16:00', 'm': 'walk', 'd': 1200.0, 'min': 15, 'p': 'https://images.unsplash.com/photo-1565967511849-76a60a516170?q=80&w=600'},
    ]);

    // 15. Times Square (visited)
    await seed('Times Square', '2025-12-28', '2026-01-02', [
      {'n': 'New York Marriott Marquis', 'a': '1535 Broadway, New York, NY 10036', 'la': 40.7586, 'lo': -73.9861, 't': '09:00', 'et': '10:00', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'},
      {'n': 'Times Square', 'a': 'Manhattan, NY 10036', 'la': 40.7580, 'lo': -73.9855, 't': '10:00', 'et': '11:00', 'm': 'walk', 'd': 300.0, 'min': 5, 'p': 'https://images.unsplash.com/photo-1534430480872-3498386e7856?q=80&w=600'},
      {'n': 'Central Park', 'a': 'New York, NY', 'la': 40.7829, 'lo': -73.9654, 't': '13:00', 'et': '14:00', 'm': 'walk', 'd': 3000.0, 'min': 35, 'p': 'https://images.unsplash.com/photo-1534251369789-5067c8971c89?q=80&w=600'},
      {'n': 'Statue of Liberty', 'a': 'Statue of Liberty, Area', 'la': 40.6892, 'lo': -74.0445, 't': '16:30', 'et': '17:30', 'm': 'transit', 'd': 12000.0, 'min': 40, 'p': 'https://images.unsplash.com/photo-1492666673288-3c4b4f1a8b23?q=80&w=600'},
    ]);
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
        start_date TEXT,
        end_date   TEXT,
        latitude   REAL,
        longitude  REAL,
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
    await db.execute(_createTripStopsTable);

    final now = DateTime.now().toIso8601String();
    final seeds = [
      "('Raja Ampat', 'Sorong, Indonesia', 'Wisata Alam', 'wishlist', 'Ingin merasakan keajaiban berenang langsung bersama pari manta di alam yang belum tersentuh.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/Raja_Ampat%2C_West_Papua%2C_Indonesia.jpg/960px-Raja_Ampat%2C_West_Papua%2C_Indonesia.jpg', -0.2353, 130.5257, '$now')",
      "('Taman Nasional Komodo', 'Labuan Bajo, Indonesia', 'Wisata Alam', 'visited', 'Perjalanan ini membuatku takjub bisa melihat langsung naga purba di habitat aslinya yang menakjubkan.', 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?q=80&w=600', -8.5500, 119.4800, '$now')",
      "('Gunung Fuji', 'Shizuoka, Jepang', 'Wisata Alam', 'wishlist', 'Bermimpi bisa berdiri di kaki gunung suci ini sambil melihat sakura bermekaran.', 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?q=80&w=600', 35.3606, 138.7278, '$now')",
      "('Air Terjun Niagara', 'Ontario, Kanada', 'Wisata Alam', 'wishlist', 'Ingin merasakan langsung gemuruh dan percikan air dari salah satu air terjun paling bertenaga di bumi.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/3Falls_Niagara.jpg/960px-3Falls_Niagara.jpg', 43.0962, -79.0377, '$now')",
      "('Taman Nasional Yellowstone', 'Wyoming, Amerika Serikat', 'Wisata Alam', 'wishlist', 'Sangat penasaran melihat keajaiban warna-warni Grand Prismatic Spring dari dekat.', 'https://upload.wikimedia.org/wikipedia/commons/7/73/Grand_Canyon_of_yellowstone.jpg', 44.4280, -110.5885, '$now')",
      "('Candi Borobudur', 'Magelang, Indonesia', 'Budaya & Sejarah', 'visited', 'Merinding rasanya menyentuh relief kuno ini saat matahari terbit di ufuk timur.', 'https://images.unsplash.com/photo-1596402184320-417e7178b2cd?q=80&w=600', -7.6079, 110.2038, '$now')",
      "('Angkor Wat', 'Siem Reap, Kamboja', 'Budaya & Sejarah', 'wishlist', 'Ingin menyusuri lorong-lorong batu tua dan merasakan aura magis dari sisa kejayaan Kerajaan Khmer.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Buddhist_monks_in_front_of_the_Angkor_Wat.jpg/960px-Buddhist_monks_in_front_of_the_Angkor_Wat.jpg', 13.4125, 103.8670, '$now')",
      "('Colosseum', 'Roma, Italia', 'Budaya & Sejarah', 'visited', 'Berdiri di arena ini membuatku bisa membayangkan gemuruh sorak sorai penonton Romawi ribuan tahun lalu.', 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?q=80&w=600', 41.8902, 12.4922, '$now')",
      "('Machu Picchu', 'Cusco, Peru', 'Budaya & Sejarah', 'wishlist', 'Mendaki pegunungan Andes untuk menemukan kota Inca yang hilang adalah salah satu impian terbesar dalam hidupku.', 'https://images.unsplash.com/photo-1526392060635-9d6019884377?q=80&w=600', -13.1631, -72.5450, '$now')",
      "('Tembok Besar China', 'Beijing, China', 'Budaya & Sejarah', 'wishlist', 'Berharap suatu hari nanti kakiku bisa menjejakkan langkah di atas sejarah pertahanan manusia terpanjang ini.', 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?q=80&w=600', 40.4319, 116.5704, '$now')",
      "('Burj Khalifa', 'Dubai, UAE', 'Kota & Urban', 'wishlist', 'Ingin berdiri di atas awan dan melihat betapa kecilnya dunia dari gedung tertinggi yang pernah dibangun.', 'https://images.unsplash.com/photo-1582672060674-bc2bd808a8b5?q=80&w=600', 25.1972, 55.2744, '$now')",
      "('Menara Eiffel', 'Paris, Prancis', 'Kota & Urban', 'visited', 'Menikmati lampu berkelap-kelip dari bawah menara ini benar-benar terasa seperti berada di adegan film romantis.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg/960px-Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg', 48.8584, 2.2945, '$now')",
      "('Shibuya Crossing', 'Tokyo, Jepang', 'Kota & Urban', 'visited', 'Tak terlupakan sensasinya menyeberang bersama lautan manusia di persimpangan paling sibuk sedunia ini.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Shibuya_skyline_from_Tokyu_Plaza_in_Omotesando%2C_Harajuku%2C_Tokyo%2C_2024_May.jpg/960px-Shibuya_skyline_from_Tokyu_Plaza_in_Omotesando%2C_Harajuku%2C_Tokyo%2C_2024_May.jpg', 35.6580, 139.7016, '$now')",
      "('Marina Bay Sands', 'Singapura, Singapura', 'Kota & Urban', 'in_trip', 'Akhirnya bisa bersantai di infinity pool ikonik ini sambil memandangi cakrawala Singapura!', 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?q=80&w=600', 1.2838, 103.8607, '$now')",
      "('Times Square', 'New York, Amerika Serikat', 'Kota & Urban', 'visited', 'Energi kota yang tak pernah tidur ini benar-benar membuatku merasa hidup dan bebas.', 'https://images.unsplash.com/photo-1534430480872-3498386e7856?q=80&w=600', 40.7580, -73.9855, '$now')"
    ];

    for (var val in seeds) {
      await db.execute('''
        INSERT INTO destinations (name, country, category, status, notes, photo_path, latitude, longitude, created_at)
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
      await txn.delete(
        'trip_stops',
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

  Future<List<GalleryFeedItem>> getGalleryFeedItems() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT
        p.id AS gallery_photo_id,
        p.destination_id AS gallery_destination_id,
        p.photo_path AS gallery_photo_path,
        p.caption AS gallery_caption,
        p.created_at AS gallery_created_at,
        d.*,
        (SELECT COUNT(*) FROM checklist_items WHERE destination_id = d.id)
          AS checklist_total,
        (SELECT IFNULL(SUM(is_done), 0) FROM checklist_items WHERE destination_id = d.id)
          AS checklist_done
      FROM destination_photos p
      INNER JOIN destinations d ON d.id = p.destination_id
      ORDER BY p.created_at DESC, p.id DESC
    ''');
    return maps.map(GalleryFeedItem.fromMap).toList();
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

  Future<int> updateDestinationPhoto(DestinationPhoto photo) async {
    if (photo.id == null) return 0;

    final db = await database;
    return db.update(
      'destination_photos',
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
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

  // ─────────────────────────────────────────────────────────────────
  // PERSON C — TRIP STOPS CRUD (Trip Planner / Rencana Perjalanan)
  // ─────────────────────────────────────────────────────────────────

  Future<int> insertTripStop(TripStop stop) async {
    final db = await database;
    return db.insert('trip_stops', stop.toMap());
  }

  Future<List<TripStop>> getTripStops(int destinationId, {int? dayNumber}) async {
    final db = await database;
    String where = 'destination_id = ?';
    List<dynamic> args = [destinationId];
    if (dayNumber != null) {
      where += ' AND day_number = ?';
      args.add(dayNumber);
    }
    final maps = await db.query(
      'trip_stops',
      where: where,
      whereArgs: args,
      orderBy: 'day_number ASC, order_index ASC, id ASC',
    );
    return maps.map(TripStop.fromMap).toList();
  }

  Future<int> updateTripStop(TripStop stop) async {
    final db = await database;
    return db.update(
      'trip_stops',
      stop.toMap(),
      where: 'id = ?',
      whereArgs: [stop.id],
    );
  }

  Future<int> deleteTripStop(int id) async {
    final db = await database;
    return db.delete('trip_stops', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTripStopOrder(List<TripStop> stops) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final stop in stops) {
        await txn.update(
          'trip_stops',
          {
            'order_index': stop.orderIndex,
            'day_number': stop.dayNumber,
            'distance_meters': stop.distanceMeters,
            'travel_minutes': stop.travelMinutes,
          },
          where: 'id = ?',
          whereArgs: [stop.id],
        );
      }
    });
  }

  /// Get the maximum day number for a destination's trip stops.
  Future<int> getMaxDayNumber(int destinationId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT IFNULL(MAX(day_number), 0) AS max_day FROM trip_stops WHERE destination_id = ?',
      [destinationId],
    );
    return (result.first['max_day'] as int?) ?? 0;
  }

  /// Get total number of trip stops for a destination.
  Future<int> getTripStopCount(int destinationId) async {
    final db = await database;
    return Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM trip_stops WHERE destination_id = ?',
        [destinationId],
      ),
    ) ?? 0;
  }
}
