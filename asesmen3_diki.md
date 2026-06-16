# Asesmen 3 — Rancangan Pengembangan Fitur (PERSON C / Diki)
# WanderList: "TripPlanner" — Transformasi Checklist menjadi Perencana Perjalanan Interaktif

> **Status:** Dokumen Rancangan — Belum Dieksekusi  
> **Tanggal Rancangan:** 2026-06-15  
> **Konteks:** Reset total dari fitur ScratchCard & PolaroidGallery ASM3 sebelumnya. Fitur baru ini menggantikan `checklist_screen.dart` secara keseluruhan.  

---

## 0. Penilaian Ide (Evaluasi Sebelum Eksekusi)

| Aspek | Penilaian | Catatan |
|---|---|---|
| Relevansi dengan WanderList | ✅ Sangat Tinggi | Travel itinerary adalah inti dari sebuah aplikasi wisata, bukan fitur tambahan |
| Memenuhi Syarat ASM3 | ✅ Terpenuhi Semua | Custom widget (peta + timeline), gesture pan/drag, 3-5 library baru |
| Kompleksitas Teknis | ⚠️ Tinggi | Routing multi-API, migrasi DB, kompatibilitas Web+Android |
| Risiko Waktu Pengerjaan | ⚠️ Perlu Prioritas | Bagi fitur menjadi fase, implementasi bertahap |
| Nilai Tambah vs CRUD Biasa | ✅ Jauh Melampaui | Peta interaktif + cuaca real-time tidak bisa digantikan spreadsheet manapun |

**Kesimpulan:** Ide ini sangat kuat dan layak dilanjutkan. Risiko utama ada di kompleksitas integrasi API ganda (OpenTripMap + OpenWeatherMap + Peta). Mitigasi: implementasikan per fase, mulai dari yang paling inti.

---

## 1. Konsep & Nama Branding Baru

### 1.1 Nama Fitur
Karena fitur ini bukan lagi sekadar "coret jika selesai", nama berikut direkomendasikan:

| Opsi Nama | Deskripsi |
|---|---|
| **TripPlanner** | Simpel, jelas, internasional |
| **ItineraryBoard** | Terasa profesional seperti aplikasi travel nyata |
| **Rute Perjalanan** | Pilihan jika ingin mempertahankan Bahasa Indonesia |
| **Jadwal Jalan** | Lebih kasual, cocok dengan tone WanderList yang personal |

> **Rekomendasi: "Rencana Perjalanan"** (ID) / **"Trip Planner"** (EN) — konsisten dengan sistem bilingual yang sudah ada di `app_locale.dart`.

### 1.2 Perubahan Entry Point
- **Sebelum:** Tombol "Checklist" di `detail_screen.dart` → `checklist_screen.dart`  
- **Sesudah:** Tombol "Rencana Perjalanan" di `detail_screen.dart` → `trip_planner_screen.dart` (file baru)  
- **File lama** `checklist_screen.dart` dan `swipeable_checklist_item.dart` akan dihapus atau diarsipkan.

---

## 2. Rancangan Antarmuka (UI/UX)

### 2.1 Struktur Halaman

```
TripPlannerScreen
│
├── [Header] — Foto destinasi sebagai background (atau peta overview)
│   ├── Nama Destinasi
│   └── Rentang Tanggal (start_date → end_date)
│
├── [Statistik Strip] — Baris horizontal berisi:
│   ├── 📍 Total Tempat (jumlah stop/waypoint)
│   ├── 📏 Total Jarak (km, dihitung dari sum jarak antar stop)
│   ├── ⏱️ Estimasi Waktu Total
│   └── 🚗 Mode Transportasi Dominan
│
├── [Peta Rute] — Widget utama (Custom Widget)
│   ├── flutter_map dengan tile OpenStreetMap
│   ├── Polyline menghubungkan semua stop (A→B→C→...)
│   ├── Marker bernomor di setiap stop (A, B, C...)
│   └── Gesture: pinch-to-zoom, pan (bukan tap)
│
└── [Day Selector + Timeline] — Bottom Sheet yang bisa ditarik ke atas
    ├── Tab horizontal: Day 1 | Day 2 | Day 3 | [+]
    │   └── Setiap tab menampilkan tanggal + ikon cuaca + suhu
    │
    └── ListView Timeline per Hari:
        ├── [Jam] — [Foto Tempat] — [Nama Tempat]
        │          [Ikon Transport] [Jarak] [Durasi] [Edit]
        ├── Garis vertikal penghubung antar item
        └── [+ Tambah Tempat] di bagian bawah
```

### 2.2 Spesifikasi Bottom Sheet

Bottom Sheet ini adalah **DraggableScrollableSheet** yang bisa ditarik dari posisi `initialChildSize: 0.45` hingga `maxChildSize: 0.9`. Ini BUKAN modal sheet biasa — ia permanen di layar dan bisa di-drag.

Saat Bottom Sheet di posisi minimum → **Peta mendominasi layar**  
Saat Bottom Sheet di posisi maksimum → **Timeline mendominasi layar, peta mengecil di atas**

### 2.3 Setiap Item Timeline (TripStop)

```
┌─────────────────────────────────────────────────┐
│ 09:30  [Foto]  Tower of London                  │
│               London, UK                         │
│        [🚶 walk] [↕ 1.4 km] [⏱ 17 min] [✏️]   │
└─────────────────────────────────────────────────┘
    │ (garis vertikal ke item berikutnya)
┌─────────────────────────────────────────────────┐
│ 10:15  [Foto]  The Shard                        │
│               London, UK                         │
│        [🚶 walk] [↕ 1.2 km] [⏱ 5 min]  [✏️]   │
└─────────────────────────────────────────────────┘
```

**Tap item** → membuka **Detail Stop** (bottom sheet overlay):
- Foto besar dari API
- Nama + Alamat lengkap
- Koordinat
- Opening Hours (dari OpenTripMap)
- Rating (jika tersedia)
- Deskripsi singkat (Wikipedia excerpt via OpenTripMap)
- Tombol: Edit Jam | Ganti Transport | Hapus Stop

### 2.4 Informasi Cuaca Per Hari

Posisi ideal: **Di dalam tab Day selector**, bukan ditumpuk di timeline.  
Contoh tampilan tab:
```
[ Day 1      ] [ Day 2      ] [ Day 3      ]
[ 5 Des      ] [ 6 Des      ] [ 7 Des      ]
[ ☀️ 28°C   ] [ 🌧️ 24°C   ] [ ⛅ 26°C   ]
```

Cuaca diambil dari **OpenWeatherMap API** berdasarkan koordinat destinasi dan tanggal yang dipilih.

---

## 3. Perubahan Skema Database (KRITIS)

### 3.1 Versi Database: v7 → v8

Perubahan ini HARUS diimplementasikan sebagai migrasi `if (oldVersion < 8)` di `_onUpgrade`, bukan menulis ulang `_onCreate` (agar 15 data awal tidak hilang).

### 3.2 Tabel `destinations` — Perubahan Kolom

**Kolom yang DITAMBAH:**
```sql
ALTER TABLE destinations ADD COLUMN start_date TEXT;
ALTER TABLE destinations ADD COLUMN end_date   TEXT;
ALTER TABLE destinations ADD COLUMN latitude   REAL;
ALTER TABLE destinations ADD COLUMN longitude  REAL;
```

**Penjelasan:**
- `visited_at` (TEXT yang sudah ada) **TIDAK DIHAPUS** untuk backward compatibility. Kolom ini tetap ada untuk 15 data awal.
- `start_date` dan `end_date` adalah kolom baru untuk rentang perjalanan.
- `latitude` & `longitude` diperlukan oleh API Cuaca dan rendering marker peta.

**Strategi Migrasi Data 15 Destinasi:**
Isi `latitude` & `longitude` secara hardcoded di blok migrasi untuk 15 destinasi yang sudah ada, karena koordinatnya sudah diketahui:

```dart
// Di dalam _onUpgrade, if (oldVersion < 8):
final coordUpdates = {
  'Raja Ampat':               {'lat': -0.2353,  'lng': 130.5257},
  'Taman Nasional Komodo':    {'lat': -8.5500,  'lng': 119.4800},
  'Gunung Fuji':              {'lat': 35.3606,  'lng': 138.7278},
  'Air Terjun Niagara':       {'lat': 43.0962,  'lng': -79.0377},
  'Taman Nasional Yellowstone':{'lat': 44.4280, 'lng': -110.5885},
  'Candi Borobudur':          {'lat': -7.6079,  'lng': 110.2038},
  'Angkor Wat':               {'lat': 13.4125,  'lng': 103.8670},
  'Colosseum':                {'lat': 41.8902,  'lng': 12.4922},
  'Machu Picchu':             {'lat': -13.1631, 'lng': -72.5450},
  'Tembok Besar China':       {'lat': 40.4319,  'lng': 116.5704},
  'Burj Khalifa':             {'lat': 25.1972,  'lng': 55.2744},
  'Menara Eiffel':            {'lat': 48.8584,  'lng': 2.2945},
  'Shibuya Crossing':         {'lat': 35.6580,  'lng': 139.7016},
  'Marina Bay Sands':         {'lat': 1.2838,   'lng': 103.8607},
  'Times Square':             {'lat': 40.7580,  'lng': -74.0058},
};
```

### 3.3 Tabel Baru: `trip_stops`

Tabel ini **menggantikan** `checklist_items` sebagai tempat menyimpan item per-hari per-destinasi.

```sql
CREATE TABLE trip_stops (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  destination_id    INTEGER NOT NULL,
  day_number        INTEGER NOT NULL DEFAULT 1,   -- Day 1, Day 2, dst.
  order_index       INTEGER NOT NULL DEFAULT 0,   -- Urutan dalam satu hari
  
  -- Data Tempat (bisa dari OpenTripMap API atau input manual)
  place_name        TEXT    NOT NULL,
  place_address     TEXT,
  latitude          REAL,
  longitude         REAL,
  photo_url         TEXT,                         -- URL foto dari API
  opening_hours     TEXT,                         -- JSON string dari API
  description       TEXT,                         -- Deskripsi singkat
  otm_xid           TEXT,                         -- OpenTripMap Place ID
  
  -- Data Kunjungan
  visit_time        TEXT,                         -- "09:30" (format HH:mm)
  estimated_duration_minutes INTEGER DEFAULT 60,
  
  -- Data Transportasi (ke tempat BERIKUTNYA)
  transport_mode    TEXT DEFAULT 'walk',           -- walk | car | bike | public
  distance_meters   REAL,                          -- Jarak ke stop berikutnya
  travel_minutes    INTEGER,                       -- Durasi ke stop berikutnya
  
  created_at        TEXT NOT NULL,
  FOREIGN KEY(destination_id) REFERENCES destinations(id) ON DELETE CASCADE
)
```

**Perhatian:** Tabel `checklist_items` **tetap ada** (tidak di-DROP) karena:
1. Migrasi DROP TABLE berisiko jika ada user yang punya data lama
2. PERSON A/B mungkin masih memiliki referensi di kode mereka
3. Tabel lama bisa dihapus di versi DB berikutnya setelah dipastikan tidak dipakai

### 3.4 Model Dart Baru: `TripStop`

```dart
// lib/models/trip_stop.dart
class TripStop {
  final int? id;
  final int destinationId;
  final int dayNumber;
  final int orderIndex;
  final String placeName;
  final String? placeAddress;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? openingHours;   // JSON string
  final String? description;
  final String? otmXid;
  final String? visitTime;      // "09:30"
  final int estimatedDurationMinutes;
  final String transportMode;   // 'walk' | 'car' | 'bike' | 'public'
  final double? distanceMeters;
  final int? travelMinutes;
  final String createdAt;
  
  // ...constructor, fromMap, toMap, copyWith
}
```

### 3.5 Perubahan Model `Destination`

Tambahkan field baru tanpa menghapus yang lama:

```dart
class Destination {
  // ... field yang sudah ada ...
  final String? startDate;   // BARU: "2024-12-05"
  final String? endDate;     // BARU: "2024-12-07"
  final double? latitude;    // BARU
  final double? longitude;   // BARU
  
  // visitedAt TETAP ADA (backward compatible)
}
```

---

## 4. Integrasi API

### 4.1 OpenTripMap API — Pencarian Tempat

**Tujuan:** Saat user menambah stop baru ke itinerary, mereka bisa mencari nama tempat dan hasilnya auto-filled dari API.

**Endpoint yang Digunakan:**
```
# Autocomplete / Pencarian berdasarkan nama
GET https://api.opentripmap.com/0.1/en/places/geoname?name={query}&apikey={KEY}

# Dapatkan detail lengkap (foto, jam buka, deskripsi)
GET https://api.opentripmap.com/0.1/en/places/xid/{xid}?apikey={KEY}

# Cari tempat berdasarkan radius dari koordinat destinasi
GET https://api.opentripmap.com/0.1/en/places/radius?radius=5000&lon={lng}&lat={lat}&apikey={KEY}
```

**Cara Mendapatkan API Key:**
1. Daftar di [opentripmap.io](https://opentripmap.io)
2. Gratis, batas 5.000 request/hari
3. Simpan key di constants file: `lib/services/api_constants.dart`

**Response yang Diparsing:**
```json
{
  "xid": "W24818969",
  "name": "Tower of London",
  "address": { "city": "London", "country": "United Kingdom" },
  "rate": 3,
  "image": "https://commons.wikimedia.org/...",
  "info": { "descr": "The Tower of London is..." },
  "opening_hours": "Mo-Su 09:00-17:00"
}
```

### 4.2 OpenWeatherMap API — Cuaca Per Hari

**Tujuan:** Tampilkan ikon cuaca + suhu di setiap tab "Day X" berdasarkan lokasi destinasi dan tanggal.

**Endpoint yang Digunakan:**
```
# Forecast 5 hari (gratis)
GET https://api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lng}&appid={KEY}&units=metric&lang=id

# Historical weather (memerlukan tier berbayar)
# → Gunakan forecast saja untuk tujuan akademis
```

**Cara Mendapatkan API Key:**
1. Daftar di [openweathermap.org](https://openweathermap.org)
2. Tier gratis: 1.000 calls/hari, forecast 5 hari ke depan
3. Simpan key di `lib/services/api_constants.dart`

**Batasan Penting:**
- API cuaca gratis hanya untuk **5 hari ke depan**. Jika tanggal perjalanan di masa lalu (destinasi yang sudah `visited`), cuaca tidak akan tersedia. Tampilkan placeholder "Data tidak tersedia" dengan elegan.

**Pemetaan Icon Cuaca:**
```dart
String weatherIconPath(String condition) {
  switch (condition.toLowerCase()) {
    case 'clear': return '☀️';
    case 'clouds': return '⛅';
    case 'rain': return '🌧️';
    case 'drizzle': return '🌦️';
    case 'thunderstorm': return '⛈️';
    case 'snow': return '❄️';
    default: return '🌡️';
  }
}
```

### 4.3 flutter_map + OpenStreetMap — Peta Rute

**Tujuan:** Tampilkan peta dengan garis rute yang menghubungkan semua stop dalam satu hari (atau semua hari).

**Library yang Diperlukan:**
```yaml
# Tambahkan ke pubspec.yaml
flutter_map: ^7.0.2
latlong2: ^0.9.1
```

**Tile Provider:**
Gunakan OpenStreetMap (gratis, tanpa API key):
```
https://tile.openstreetmap.org/{z}/{x}/{y}.png
```

**Fitur Peta yang Diimplementasikan:**
```
MapWidget
├── TileLayer (OpenStreetMap)
├── PolylineLayer — garis rute antar stop
└── MarkerLayer — marker bernomor (1, 2, 3, ...)
    └── Setiap marker: lingkaran berwarna + nomor urut
```

**Gesture pada Peta (Memenuhi Syarat ASM3):**
- `InteractiveFlags.pinchZoom` → pinch untuk zoom (bukan tap)
- `InteractiveFlags.drag` → drag/pan untuk menggeser peta
- Tap pada marker → highlight stop tersebut di timeline

---

## 5. Struktur File & Kode (Rencana)

### 5.1 File Baru (Dibuat dari Nol)

```
lib/
├── models/
│   └── trip_stop.dart                  [BARU] Model data untuk setiap stop itinerary
│
├── screens/
│   └── trip_planner_screen.dart        [BARU] Layar utama pengganti checklist_screen
│
├── widgets/
│   ├── trip_map_widget.dart            [BARU] Custom Widget: peta rute dengan flutter_map
│   ├── trip_timeline_item.dart         [BARU] Item dalam timeline per hari
│   ├── day_weather_tab.dart            [BARU] Tab Day X dengan info cuaca
│   └── add_stop_sheet.dart             [BARU] Bottom sheet untuk menambah stop baru
│
└── services/
    ├── api_constants.dart              [BARU] Menyimpan API keys (jangan di-commit ke Git publik)
    ├── opentripmap_service.dart        [BARU] Service untuk OpenTripMap API
    └── weather_service.dart            [BARU] Service untuk OpenWeatherMap API
```

### 5.2 File yang Dimodifikasi

```
lib/
├── models/
│   └── destination.dart        [EDIT] Tambah field startDate, endDate, latitude, longitude
│
├── screens/
│   ├── detail_screen.dart      [EDIT] Ganti tombol "Checklist" → "Rencana Perjalanan"
│   └── add_edit_screen.dart    [EDIT] Ganti input visited_at menjadi start_date + end_date
│
└── services/
    └── database_helper.dart    [EDIT] Versi DB v8, tambah migrasi, tambah CRUD untuk trip_stops
```

### 5.3 File yang Dihapus / Dinonaktifkan

```
lib/screens/checklist_screen.dart        [HAPUS atau ARSIPKAN]
lib/widgets/swipeable_checklist_item.dart [HAPUS atau ARSIPKAN]
lib/models/checklist_item.dart           [BIARKAN — tidak dihapus untuk keamanan migrasi]
```

---

## 6. Custom Widget (Memenuhi Syarat ASM3)

### 6.1 `TripMapWidget` — Custom Widget Utama

**Mengapa ini Custom Widget yang memenuhi syarat:**
- Menggabungkan `flutter_map`, custom `MarkerLayer`, dan custom `PolylineLayer`
- **Custom Drawing:** Marker angka digambar menggunakan `CustomPainter` (lingkaran berwarna dengan angka di tengah, dengan efek shadow dan numbered badge)
- **Gesture Bukan Tap:** `InteractiveViewer`-like gesture — **pinch-to-zoom** dan **pan/drag** pada peta adalah gesture non-tap

```dart
// Struktur class
class TripMapWidget extends StatefulWidget {
  final List<TripStop> stops;
  final int? highlightedDayNumber; // null = tampilkan semua hari
  final Function(TripStop)? onStopTapped;
  
  // ...
}

class _TripMapWidgetState extends State<TripMapWidget> {
  final MapController _mapController = MapController();
  
  // Hitung bounds otomatis dari semua koordinat stop
  // Pan kamera ke stop yang di-tap dari timeline
}
```

**Custom Painter untuk Marker:**
```dart
class NumberedMarkerPainter extends CustomPainter {
  final int number;
  final Color color;
  final bool isHighlighted;
  
  @override
  void paint(Canvas canvas, Size size) {
    // Gambar lingkaran berwarna dengan drop shadow
    // Gambar angka di tengah dengan font bold
    // Jika highlighted: gambar ring animasi di luar lingkaran
  }
}
```

### 6.2 `TripTimelineItem` — Widget dengan Gesture Swipe

Item dalam timeline mendukung:
- **Swipe kiri:** Tombol hapus stop muncul (sama seperti `SwipeableChecklistItem` lama, tapi redesigned)
- **Long press + drag vertikal:** Reorder urutan stop dalam satu hari
- **Tap:** Buka detail stop (bottom sheet)

Gesture **swipe horizontal** dan **long press + vertical drag** keduanya bukan gesture tap biasa → memenuhi syarat ASM3.

---

## 7. Rencana Implementasi (Urutan Pengerjaan)

Implementasi dibagi ke dalam **3 fase** untuk mengurangi risiko dan memudahkan debugging.

### Fase 1 — Fondasi (Database + Model) [PRIORITAS TINGGI]

- [ ] Naikkan versi DB ke 8
- [ ] Tulis migrasi: `ALTER TABLE destinations ADD COLUMN start_date, end_date, latitude, longitude`
- [ ] Hardcode koordinat 15 destinasi di blok migrasi
- [ ] Buat tabel baru `trip_stops` di migrasi
- [ ] Update model `Destination` (tambah field baru, backward compatible)
- [ ] Buat model `TripStop`
- [ ] Buat CRUD methods untuk `trip_stops` di `database_helper.dart`
- [ ] Update `add_edit_screen.dart`: ganti `visited_at` input menjadi `start_date` + `end_date`

### Fase 2 — Layar Utama (Tanpa API Dulu) [INTI FITUR]

- [ ] Buat `trip_planner_screen.dart` dengan struktur dasar (Header + Statistik + Shell Bottom Sheet)
- [ ] Implementasikan `DraggableScrollableSheet` untuk timeline
- [ ] Buat tab Day selector (tanpa cuaca dulu)
- [ ] Buat `TripTimelineItem` widget dengan gesture swipe & drag reorder
- [ ] Implementasikan Add Stop secara manual (tanpa API, user ketik nama sendiri)
- [ ] Sambungkan ke database (CRUD trip_stops berjalan)
- [ ] Hitung dan tampilkan statistik (total tempat, total jarak manual)
- [ ] **Uji di Android dan Web** — pastikan tidak ada crash

### Fase 3 — Integrasi API [FITUR PREMIUM]

- [ ] Tambah `flutter_map` + `latlong2` ke `pubspec.yaml`
- [ ] Buat `TripMapWidget` dengan peta OSM, polyline, dan numbered markers
- [ ] Integrasikan peta ke `trip_planner_screen.dart`
- [ ] Buat `api_constants.dart` (simpan API keys)
- [ ] Buat `OpenTripMapService` dengan fungsi search & detail
- [ ] Integrasikan search OpenTripMap ke `AddStopSheet` (auto-complete saat mengetik)
- [ ] Buat `WeatherService` untuk OpenWeatherMap
- [ ] Tampilkan cuaca di tab Day selector
- [ ] Polish: animasi, loading states, error handling API

---

## 8. Checklist Pemenuhan Syarat ASM3

| Syarat | Terpenuhi Via | Status |
|---|---|---|
| Custom Widget (1 per orang) | `TripMapWidget` | 🔵 Rencana |
| Custom Drawing (CustomPainter) | `NumberedMarkerPainter` untuk marker peta | 🔵 Rencana |
| Gesture selain Tap | Pinch-zoom + pan di peta; swipe + drag di timeline | 🔵 Rencana |
| 3–5 Library (di luar SQLite & SharedPrefs) | `flutter_map`, `latlong2`, `http`/`dio`, `google_fonts` | 🔵 Rencana |
| Dilanjut dari ASM2 | Checklist ASM2 → Trip Planner ASM3, basis data sama | ✅ |
| Bukan CRUD generik | Peta rute, cuaca real-time, itinerary berbasis hari | ✅ |

---

## 9. Hal Teknis Kritis yang Wajib Diketahui AI

Bagian ini berisi informasi yang SERING menjadi sumber bug dan harus selalu diperhatikan saat menulis kode baru.

### 9.1 Aturan Web vs Android

```dart
// SELALU gunakan pattern ini saat menangani file/gambar:
if (kIsWeb || path.startsWith('http')) {
  return Image.network(path);
} else if (path.startsWith('assets/')) {
  return Image.asset(path);
} else {
  return Image.file(File(path)); // HANYA untuk Android
}

// JANGAN pernah panggil File() atau dart:io di kode yang bisa jalan di Web!
```

### 9.2 Database Initialization

```dart
// KRITIS: Web HARUS pakai factory khusus ini, bukan openDatabase biasa
if (kIsWeb) {
  return databaseFactoryFfiWebNoWebWorker.openDatabase('wanderlist.db', ...);
} else {
  return openDatabase(path, ...);
}
```

### 9.3 Migrasi Database — Aturan Tidak Boleh Dilanggar

1. **JANGAN tulis ulang `_onCreate`** saat ada perubahan skema. Selalu tambahkan blok `if (oldVersion < X)` di `_onUpgrade`.
2. **WAJIB naikkan angka versi** di SEMUA pemanggilan `openDatabase` jika ada perubahan skema. Jika lupa, migrasi tidak akan pernah berjalan.
3. **Urutkan migrasi secara kumulatif**: `if (oldVersion < 2)`, `if (oldVersion < 3)`, dst. Jangan gabungkan.
4. **Test migrasi** dengan cara: uninstall app, install ulang (fresh install akan pakai `_onCreate`), lalu update app (akan pakai `_onUpgrade`). Keduanya harus menghasilkan skema yang sama.

### 9.4 HTTP Requests di Flutter

Package yang direkomendasikan: `http` (sudah sederhana untuk kebutuhan API GET ini).

```dart
// Tambah ke pubspec.yaml:
http: ^1.2.1

// SELALU handle error jaringan:
try {
  final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    // proses data
  } else {
    throw Exception('API Error: ${response.statusCode}');
  }
} on TimeoutException {
  // Tampilkan pesan: "Koneksi bermasalah, coba lagi"
} on SocketException {
  // Tampilkan pesan: "Tidak ada koneksi internet"
}
```

### 9.5 `flutter_map` — Gotchas

1. **Tile tidak muncul di Web**: Tambahkan CORS header di `web/index.html` jika ada masalah, atau gunakan tile HTTPS.
2. **MapController**: Harus di-initialize setelah widget build. Gunakan `WidgetsBinding.instance.addPostFrameCallback` jika perlu memanggil `_mapController.move()` di `initState`.
3. **Update polyline**: Jika daftar stop berubah, polyline akan ikut update karena flutter_map reaktif terhadap perubahan list.

### 9.6 API Keys — Keamanan

```dart
// lib/services/api_constants.dart
class ApiConstants {
  static const String openTripMapKey = 'ISI_API_KEY_ANDA_DISINI';
  static const String openWeatherMapKey = 'ISI_API_KEY_ANDA_DISINI';
}
```

> ⚠️ **JANGAN commit file ini ke repository publik jika API key sudah diisi.** Tambahkan ke `.gitignore` jika perlu. Untuk keperluan tugas (repo privat/tim), ini aman.

### 9.7 Pembagian SharedPreferences — Jangan Overlap

Setiap PERSON punya namespace key sendiri. Key baru PERSON C yang mungkin ditambahkan:

```dart
// lib/services/preferences_service.dart — Bagian PERSON C
static const String _kMapStyle = 'map_style';      // 'standard' | 'satellite'
static const String _kDefaultTransport = 'default_transport'; // 'walk' | 'car' | 'bike'
```

### 9.8 Cara Hitung Jarak antar Koordinat (Haversine Formula)

Untuk menghitung jarak antara dua titik koordinat tanpa API tambahan:

```dart
double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000.0; // Radius bumi dalam meter
  final phi1 = lat1 * pi / 180;
  final phi2 = lat2 * pi / 180;
  final dPhi = (lat2 - lat1) * pi / 180;
  final dLambda = (lon2 - lon1) * pi / 180;

  final a = sin(dPhi / 2) * sin(dPhi / 2) +
      cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c; // Hasil dalam meter
}
```

### 9.9 `withOpacity` Sudah Deprecated

Selalu gunakan `.withValues(alpha: X)` sebagai pengganti di Flutter 3.10+:
```dart
// SALAH (deprecated):
color.withOpacity(0.5)

// BENAR:
color.withValues(alpha: 0.5)
```

### 9.10 Singleton Pattern DatabaseHelper

Selalu akses database via: `final _db = DatabaseHelper();`  
Tidak perlu membuat instance baru — sudah singleton sejak pertama kali dipanggil.

---

## 10. Informasi Konteks Proyek (Untuk AI Baru)

### 10.1 Gambaran Umum Tim

- **PERSON A:** Fitur bahasa (ID/EN via `app_locale.dart`) + mode tampilan (grid/list) + form tambah destinasi
- **PERSON B:** Fitur budget/estimasi biaya + mata uang + sorting destinasi + form edit destinasi
- **PERSON C (= Diki):** Tema warna + fitur checklist → kini menjadi **Trip Planner** (ASM3)

### 10.2 Sistem Bilingual

Semua teks UI harus menggunakan `tr('key')` dari `lib/services/app_locale.dart`. Jangan hardcode teks Bahasa Indonesia langsung di widget. Contoh:
```dart
Text(tr('trip_planner_title')) // Bukan: Text('Rencana Perjalanan')
```
Tambahkan key baru di `_stringsID` dan `_stringsEN` di `app_locale.dart`.

### 10.3 Tema Warna

Selalu gunakan `Theme.of(context).colorScheme.primary` untuk warna utama.  
Tiga tema: `Canopy` (hijau), `Ancient Earth` (cokelat), `Urban Slate` (abu).  
Warna berubah secara global via `themeNotifier` di `lib/main.dart`.

### 10.4 Navigasi dari Detail Screen

Semua navigasi ke fitur PERSON C dimulai dari `lib/screens/detail_screen.dart`:
- Tombol "Checklist" → akan diganti menjadi tombol "Rencana Perjalanan" → `TripPlannerScreen`
- Perubahan di `detail_screen.dart` harus hati-hati agar tidak merusak kode PERSON A/B

### 10.5 Pattern Snackbar

Gunakan `showSuccessSnackbar` atau buat `showErrorSnackbar` di `lib/widgets/custom_snackbar.dart` untuk konsistensi notifikasi.

---

## 11. Pertanyaan Terbuka (Perlu Keputusan Sebelum Eksekusi)

1. **Apakah `checklist_items` lama akan sepenuhnya dihapus atau dipertahankan?**  
   → Rekomendasi: Biarkan tabel ada di DB (jangan DROP), tapi hapus screen dan widget-nya.

2. **Apakah input manual tempat (tanpa API) perlu ada sebagai fallback?**  
   → Rekomendasi: Ya, sediakan mode "Tambah Manual" di samping pencarian API agar fitur tetap berjalan saat tidak ada internet.

3. **Berapa batas maksimum hari perjalanan?**  
   → Rekomendasi: Tidak dibatasi di kode, tapi UI tab hanya scroll horizontal jika lebih dari 4 hari.

4. **Apakah peta juga tampil untuk destinasi berstatus `wishlist` (belum ada tanggal)?**  
   → Rekomendasi: Peta tetap tampil tapi kosong (hanya marker lokasi destinasi, tanpa stop), dengan pesan "Tambah rencana perjalananmu!"

---

*Dokumen ini dibuat pada 2026-06-15. Siap untuk review sebelum eksekusi kode.*
