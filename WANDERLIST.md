# WanderList — Repo-Aligned Schema & Sprint Plan (ASM2)

> Repository: `Haykal-9/ass-pbbl`  
> Branch utama: `master`  
> Project Flutter: `ass2`  
> Fokus sekarang: **Assessment 2 (ASM2)**  
> Catatan penting: dokumen ini disusun agar mengikuti struktur file yang sudah ada di repo. Jangan membuat struktur baru dari nol agar tidak menabrak pekerjaan Haykal.

---

## 1. Deskripsi Aplikasi

**WanderList** adalah aplikasi bucket list perjalanan pribadi untuk mencatat destinasi impian dan destinasi yang sudah pernah dikunjungi.

Pengguna dapat:

- Menambahkan destinasi baru.
- Melihat daftar destinasi dalam bentuk grid atau list.
- Melakukan pencarian dan filter destinasi berdasarkan status.
- Melihat detail destinasi.
- Mengedit data destinasi.
- Menghapus destinasi.
- Menambahkan checklist aktivitas untuk setiap destinasi.
- Melihat statistik perjalanan berdasarkan status dan kategori.
- Menyimpan beberapa preferensi menggunakan `shared_preferences`.

Ide utama aplikasi ini bukan hanya CRUD biasa, tetapi aplikasi **dream board perjalanan**. Setiap destinasi memiliki status `wishlist` atau `visited`, foto, catatan pribadi, checklist, dan statistik perjalanan.

---

## 2. App Architecture yang Harus Diikuti

Project ini sudah menggunakan struktur Flutter sederhana berbasis folder `models`, `screens`, `services`, dan `widgets`.

Jangan mengubah struktur utama ini kecuali benar-benar diperlukan.

```txt
lib/
├── main.dart
├── models/
│   ├── destination.dart
│   └── checklist_item.dart
├── screens/
│   ├── home_screen.dart
│   ├── add_edit_screen.dart
│   ├── detail_screen.dart
│   ├── checklist_screen.dart
│   ├── settings_screen.dart
│   └── statistics_screen.dart
├── services/
│   ├── database_helper.dart
│   └── preferences_service.dart
└── widgets/
    ├── destination_card.dart
    ├── category_chip.dart
    └── stat_card.dart
```

### Aturan penting agar tidak saling nabrak

1. Jangan rename folder `models`, `screens`, `services`, atau `widgets`.
2. Jangan rename file yang sudah ada, seperti `home_screen.dart`, `add_edit_screen.dart`, `detail_screen.dart`, dan `database_helper.dart`.
3. Jangan membuat database helper baru. Tetap gunakan `lib/services/database_helper.dart`.
4. Jangan membuat model baru untuk destinasi. Tetap gunakan `lib/models/destination.dart`.
5. Jangan membuat service shared preferences baru. Tetap gunakan `lib/services/preferences_service.dart`.
6. Kalau menambah fitur, tambahkan ke file yang sesuai dengan role masing-masing.
7. Ikuti komentar pembagian `PERSON A`, `PERSON B`, dan `PERSON C` yang sudah ada di beberapa file.
8. Untuk ASM2, prioritaskan CRUD + SQLite + Shared Preferences. Jangan terlalu banyak menambah fitur visual yang masuk scope ASM3.

---

## 3. Dependencies yang Sudah Ada

Di `pubspec.yaml`, project sudah menggunakan dependency yang sesuai untuk ASM2:

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  sqflite: ^2.3.3
  shared_preferences: ^2.3.2
  image_picker: ^1.1.2
  path_provider: ^2.1.3
  path: ^1.9.0
```

Untuk ASM2, dependency ini sudah cukup. Jangan menambahkan library besar dulu kecuali diminta dosen atau memang diperlukan.

---

## 4. Database Schema SQLite

Database utama disimpan sebagai:

```dart
wanderlist.db
```

File pengelola database:

```txt
lib/services/database_helper.dart
```

### 4.1 Tabel `destinations`

```sql
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
);
```

### Penjelasan kolom `destinations`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID unik destinasi, auto increment |
| `name` | TEXT | Nama destinasi |
| `country` | TEXT | Negara atau kota destinasi |
| `category` | TEXT | Kategori destinasi: `pantai`, `kota`, `gunung`, `alam` |
| `status` | TEXT | Status destinasi: `wishlist` atau `visited` |
| `notes` | TEXT | Catatan pribadi |
| `photo_path` | TEXT | Path foto lokal dari galeri |
| `visited_at` | TEXT | Tanggal kunjungan, hanya terisi jika status `visited` |
| `created_at` | TEXT | Waktu data dibuat |

### 4.2 Tabel `checklist_items`

```sql
CREATE TABLE checklist_items (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  destination_id INTEGER NOT NULL,
  label          TEXT    NOT NULL,
  is_done        INTEGER NOT NULL DEFAULT 0,
  created_at     TEXT    NOT NULL
);
```

### Penjelasan kolom `checklist_items`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | ID unik checklist item |
| `destination_id` | INTEGER | ID destinasi yang berelasi dengan checklist |
| `label` | TEXT | Isi aktivitas checklist |
| `is_done` | INTEGER | Status checklist, `0` belum selesai dan `1` selesai |
| `created_at` | TEXT | Waktu item checklist dibuat |

### Catatan relasi

Relasi yang dipakai:

```txt
destinations.id -> checklist_items.destination_id
```

Saat destinasi dihapus, checklist yang berelasi juga harus ikut dihapus menggunakan query:

```sql
DELETE FROM checklist_items WHERE destination_id = ?;
DELETE FROM destinations WHERE id = ?;
```

---

## 5. Model Data

### 5.1 `Destination`

File:

```txt
lib/models/destination.dart
```

Model ini merepresentasikan satu data destinasi.

Field utama:

```dart
int? id;
String name;
String country;
String category;
String status;
String notes;
String? photoPath;
String? visitedAt;
String createdAt;
```

Model ini sudah memiliki:

- `fromMap()` untuk membaca data dari SQLite.
- `toMap()` untuk menyimpan data ke SQLite.
- `copyWith()` untuk membuat salinan data saat update.

### 5.2 `ChecklistItem`

File:

```txt
lib/models/checklist_item.dart
```

Model ini merepresentasikan satu item checklist dalam sebuah destinasi.

Field utama:

```dart
int? id;
int destinationId;
String label;
bool isDone;
String createdAt;
```

Model ini sudah memiliki:

- `fromMap()` untuk membaca data dari SQLite.
- `toMap()` untuk menyimpan data ke SQLite.
- `copyWith()` untuk toggle status checklist.

---

## 6. Pembagian CRUD ASM2

Pembagian ini mengikuti pembagian yang sudah tertulis di kode repo.

| Orang | Nama | Tanggung Jawab Utama | File Utama |
|---|---|---|---|
| Orang A | Haykal | CREATE + READ list destinasi | `home_screen.dart`, `add_edit_screen.dart`, `database_helper.dart` |
| Orang B | Ray | UPDATE + READ detail destinasi | `detail_screen.dart`, `add_edit_screen.dart`, `database_helper.dart` |
| Orang C | Diki | DELETE + READ checklist | `home_screen.dart`, `checklist_screen.dart`, `database_helper.dart` |

---

## 7. Orang A — Haykal

### Scope ASM2

Haykal mengerjakan:

- CREATE destinasi baru.
- READ semua destinasi di Home Screen.
- Filter destinasi berdasarkan status.
- Search destinasi berdasarkan nama atau negara.
- Tampilan grid/list.
- Shared Preferences untuk `bahasa` dan `tampilan_mode`.

### File yang menjadi area utama Haykal

```txt
lib/screens/home_screen.dart
lib/screens/add_edit_screen.dart
lib/services/database_helper.dart
lib/services/preferences_service.dart
lib/widgets/destination_card.dart
```

### Fungsi database milik Haykal

```dart
Future<int> insertDestination(Destination destination)
Future<List<Destination>> getDestinations({
  String filter = 'all',
  String sortBy = 'terbaru',
  String search = '',
})
```

### Flow CREATE

```txt
User membuka Home Screen
-> tekan tombol Tambah
-> masuk ke AddEditScreen mode tambah
-> isi nama, negara, kategori, status, foto, catatan
-> tekan Simpan
-> insertDestination() dipanggil
-> data masuk ke tabel destinations
-> kembali ke Home Screen
-> list destinasi refresh
```

### Flow READ list

```txt
HomeScreen dibuka
-> _loadPrefs()
-> _loadDestinations()
-> DatabaseHelper.getDestinations()
-> data ditampilkan dalam grid/list
```

---

## 8. Orang B — Ray

### Scope ASM2

Ray mengerjakan:

- READ satu destinasi berdasarkan ID.
- Menampilkan detail destinasi.
- UPDATE data destinasi.
- Mengubah status dari `wishlist` ke `visited`.
- Mengatur tanggal kunjungan jika status `visited`.
- Shared Preferences untuk `mata_uang` dan `sort_by`.

### File yang menjadi area utama Ray

```txt
lib/screens/detail_screen.dart
lib/screens/add_edit_screen.dart
lib/services/database_helper.dart
lib/services/preferences_service.dart
lib/screens/settings_screen.dart
```

### Fungsi database milik Ray

```dart
Future<Destination?> getDestinationById(int id)
Future<int> updateDestination(Destination destination)
```

### Flow READ detail

```txt
User tap salah satu card destinasi di Home Screen
-> masuk ke DetailScreen
-> DetailScreen menerima data destination
-> _reload() dipanggil
-> DatabaseHelper.getDestinationById(id)
-> data terbaru ditampilkan di halaman detail
```

### Flow UPDATE destinasi

```txt
User membuka DetailScreen
-> tekan icon Edit
-> masuk ke AddEditScreen mode edit
-> data lama otomatis muncul di form
-> user mengubah nama/negara/kategori/status/catatan/foto
-> tekan Simpan
-> DatabaseHelper.updateDestination(destination)
-> kembali ke DetailScreen
-> _reload() dipanggil
-> data detail tampil versi terbaru
```

### Batas aman pekerjaan Ray agar tidak nabrak Haykal

Ray boleh mengubah bagian berikut:

```txt
lib/screens/detail_screen.dart
```

Aman untuk:

- Menyempurnakan tampilan detail.
- Memastikan tombol edit berjalan.
- Memastikan reload data setelah update.
- Menambahkan validasi khusus detail jika diperlukan.

Ray boleh mengubah bagian edit di:

```txt
lib/screens/add_edit_screen.dart
```

Tetapi jangan merusak mode tambah milik Haykal. File ini dipakai bersama.

Bagian yang harus dijaga:

```dart
bool get _isEditMode => widget.destination != null;
```

Jika `_isEditMode == false`, berarti mode CREATE milik Haykal.

Jika `_isEditMode == true`, berarti mode UPDATE milik Ray.

Ray boleh mengubah bagian berikut di `database_helper.dart`:

```dart
Future<Destination?> getDestinationById(int id)
Future<int> updateDestination(Destination destination)
```

Jangan mengubah query `insertDestination()` dan `getDestinations()` tanpa koordinasi dengan Haykal.

Ray boleh mengubah bagian berikut di `preferences_service.dart`:

```dart
getMataUang()
setMataUang(String value)
getSortBy()
setSortBy(String sortBy)
```

Jangan mengubah key milik Haykal dan Diki.

---

## 9. Orang C — Diki

### Scope ASM2

Diki mengerjakan:

- DELETE destinasi.
- DELETE checklist terkait saat destinasi dihapus.
- READ checklist berdasarkan destination ID.
- CREATE checklist item.
- UPDATE checklist item untuk toggle selesai/belum selesai.
- DELETE checklist item.
- Shared Preferences untuk `tema_warna` dan `show_map_default`.

### File yang menjadi area utama Diki

```txt
lib/screens/checklist_screen.dart
lib/screens/home_screen.dart
lib/services/database_helper.dart
lib/services/preferences_service.dart
lib/screens/settings_screen.dart
```

### Fungsi database milik Diki

```dart
Future<int> deleteDestination(int id)
Future<int> insertChecklistItem(ChecklistItem item)
Future<List<ChecklistItem>> getChecklistItems(int destinationId)
Future<int> updateChecklistItem(ChecklistItem item)
Future<int> deleteChecklistItem(int id)
```

### Flow DELETE destinasi

```txt
User long press destinasi di Home Screen
-> muncul dialog konfirmasi
-> user pilih Hapus
-> deleteDestination(id) dipanggil
-> hapus checklist_items berdasarkan destination_id
-> hapus destinations berdasarkan id
-> HomeScreen refresh
```

### Flow READ checklist

```txt
User buka DetailScreen
-> tekan icon Checklist
-> masuk ke ChecklistScreen
-> getChecklistItems(destination.id)
-> checklist ditampilkan
```

---

## 10. Shared Preferences ASM2

File:

```txt
lib/services/preferences_service.dart
```

| Pemilik | Key | Tipe | Default | Keterangan |
|---|---|---|---|---|
| Haykal | `bahasa` | String | `ID` | Bahasa antarmuka ID/EN |
| Haykal | `tampilan_mode` | String | `grid` | Grid atau list di Home Screen |
| Ray | `mata_uang` | String | `IDR` | Preferensi mata uang |
| Ray | `sort_by` | String | `terbaru` | Urutan destinasi |
| Diki | `tema_warna` | String | `teal` | Warna tema aplikasi |
| Diki | `show_map_default` | bool | `false` | Preferensi peta default |

### Catatan penting

Key Shared Preferences jangan diganti karena sudah dipakai di beberapa file.

Contoh key yang tidak boleh diganti:

```dart
static const String _kBahasa = 'bahasa';
static const String _kSortBy = 'sort_by';
```

Kalau key diganti, data lama tidak akan terbaca dan fitur bisa terlihat error.

---

## 11. Screen dan Tanggung Jawab

### 11.1 `main.dart`

Fungsi:

- Entry point aplikasi.
- Load tema warna dari Shared Preferences.
- Menjalankan `WanderListApp`.
- Membuka `HomeScreen` sebagai halaman awal.

Jangan banyak mengubah file ini untuk ASM2.

### 11.2 `home_screen.dart`

Fungsi:

- Menampilkan daftar destinasi.
- Search destinasi.
- Filter status: semua, wishlist, visited.
- Sort data destinasi.
- Toggle grid/list.
- Navigasi ke tambah destinasi.
- Navigasi ke detail destinasi.
- Trigger hapus destinasi lewat long press.

File ini cukup sensitif karena dipakai oleh Haykal, Ray, dan Diki.

Aturan aman:

- Haykal fokus di CREATE dan READ list.
- Ray hanya perlu memastikan navigasi ke DetailScreen tetap berjalan.
- Diki hanya perlu bagian delete dari long press.

### 11.3 `add_edit_screen.dart`

Fungsi:

- Form tambah destinasi baru.
- Form edit destinasi lama.
- Pick image dari galeri.
- Pilih kategori.
- Pilih status wishlist/visited.
- Pilih tanggal kunjungan jika status visited.

File ini dipakai bersama Haykal dan Ray.

Aturan aman:

- Jangan pisahkan menjadi dua file berbeda untuk add dan edit.
- Gunakan `_isEditMode` sebagai pembeda mode.
- Mode CREATE milik Haykal.
- Mode UPDATE milik Ray.

### 11.4 `detail_screen.dart`

Fungsi:

- Menampilkan detail destinasi.
- Menampilkan foto, nama, negara, kategori, status, catatan, tanggal kunjungan, dan tanggal dibuat.
- Tombol edit.
- Tombol checklist.

File ini menjadi area utama Ray.

### 11.5 `checklist_screen.dart`

Fungsi:

- Menampilkan checklist berdasarkan destinasi.
- Menambahkan checklist item.
- Toggle checklist selesai/belum.
- Menghapus checklist item.
- Menampilkan progress checklist.

File ini menjadi area utama Diki.

### 11.6 `settings_screen.dart`

Fungsi:

- Menampilkan semua pengaturan Shared Preferences.
- Setting milik Haykal, Ray, dan Diki berada dalam satu halaman.

Aturan aman:

- Jika mengubah section tertentu, jangan merusak section orang lain.
- Ray hanya fokus ke bagian `Mata Uang` dan `Urutkan Destinasi`.

### 11.7 `statistics_screen.dart`

Fungsi:

- Menampilkan statistik total destinasi.
- Menampilkan jumlah visited.
- Menampilkan jumlah wishlist.
- Menampilkan jumlah berdasarkan kategori.

Untuk ASM2, screen ini cukup sebagai READ statistik tambahan. Jangan dibuat terlalu kompleks dulu.

---

## 12. Query Reference SQLite

### CREATE destinasi

```dart
await db.insert(
  'destinations',
  destination.toMap(),
  conflictAlgorithm: ConflictAlgorithm.replace,
);
```

### READ semua destinasi

```dart
await db.query(
  'destinations',
  where: whereClause.isEmpty ? null : whereClause,
  whereArgs: whereArgs.isEmpty ? null : whereArgs,
  orderBy: orderBy,
);
```

### READ detail destinasi

```dart
await db.query(
  'destinations',
  where: 'id = ?',
  whereArgs: [id],
  limit: 1,
);
```

### UPDATE destinasi

```dart
await db.update(
  'destinations',
  destination.toMap(),
  where: 'id = ?',
  whereArgs: [destination.id],
);
```

### DELETE destinasi dan checklist terkait

```dart
await db.delete(
  'checklist_items',
  where: 'destination_id = ?',
  whereArgs: [id],
);

await db.delete(
  'destinations',
  where: 'id = ?',
  whereArgs: [id],
);
```

---

## 13. Sprint ASM2

### Tujuan Sprint ASM2

Sprint ASM2 fokus pada:

- CRUD SQLite.
- Shared Preferences.
- Navigasi antar screen.
- Validasi form dasar.
- Pemahaman alur query dari UI sampai database.

### Backlog ASM2 — Haykal

- Pastikan tambah destinasi berhasil.
- Pastikan foto dari galeri bisa tersimpan ke local path.
- Pastikan list destinasi refresh setelah tambah data.
- Pastikan filter wishlist dan visited berjalan.
- Pastikan search berdasarkan nama atau negara berjalan.
- Pastikan `bahasa` tersimpan di Shared Preferences walaupun belum full translate UI.
- Pastikan tampilan grid/list tersimpan di Shared Preferences.

### Backlog ASM2 — Ray

- Pastikan detail destinasi membaca data berdasarkan ID.
- Pastikan tombol edit dari detail membuka form edit.
- Pastikan form edit membawa data lama.
- Pastikan update nama, negara, kategori, status, catatan, dan foto berhasil.
- Pastikan status `visited` dapat menyimpan `visited_at`.
- Pastikan detail refresh setelah update.
- Pastikan `mata_uang` tersimpan di Shared Preferences dan dipakai di tampilan budget.
- Pastikan `sort_by` tersimpan dan dipakai di Home Screen.

### Backlog ASM2 — Diki

- Pastikan destinasi bisa dihapus dari Home Screen.
- Pastikan checklist terkait ikut terhapus saat destinasi dihapus.
- Pastikan checklist bisa ditampilkan berdasarkan destinasi.
- Pastikan checklist item bisa ditambah.
- Pastikan checklist item bisa dicentang selesai/belum.
- Pastikan checklist item bisa dihapus.
- Pastikan `tema_warna` dan `show_map_default` tersimpan.

---

## 14. Sprint ASM3

ASM3 jangan dikerjakan dulu jika ASM2 belum stabil.

Rencana fitur ASM3:

### Haykal — Scratch Card Widget

Destinasi wishlist bisa ditampilkan dengan efek scratch/reveal menggunakan:

- `CustomPainter`
- `GestureDetector`
- `onPanUpdate`

### Ray — Journey Progress Bar

Progress perjalanan berdasarkan persentase visited dari total destinasi.

Menggunakan:

- `CustomPainter`
- `Path`
- Animasi pin/marker
- Gesture swipe kategori

### Diki — Globe Stat Widget

Statistik kategori dalam bentuk lingkaran/globe.

Menggunakan:

- `CustomPainter`
- Arc/segmen kategori
- Gesture drag/rotate
- Animasi sweep

---

## 15. Prompt Guide untuk AI Coding Assistant

Gunakan prompt seperti ini di Codex, Cursor, Antigravity, atau AI coding assistant lain.

### Prompt umum

```txt
Kamu sedang membantu project Flutter bernama WanderList.
Ikuti struktur file yang sudah ada di repository. Jangan membuat struktur baru dari nol.
Jangan rename file/folder yang sudah ada.

Fokus project sekarang adalah ASM2: SQLite CRUD + Shared Preferences.

Struktur utama:
- lib/models/destination.dart
- lib/models/checklist_item.dart
- lib/services/database_helper.dart
- lib/services/preferences_service.dart
- lib/screens/home_screen.dart
- lib/screens/add_edit_screen.dart
- lib/screens/detail_screen.dart
- lib/screens/checklist_screen.dart
- lib/screens/settings_screen.dart
- lib/screens/statistics_screen.dart
- lib/widgets/destination_card.dart
- lib/widgets/category_chip.dart
- lib/widgets/stat_card.dart

Jika mengubah kode, sesuaikan dengan role PERSON A, PERSON B, dan PERSON C yang sudah ada di komentar file.
```

### Prompt khusus untuk Ray

```txt
Saya adalah Ray, bagian PERSON B.
Tugas saya adalah UPDATE + READ detail destinasi.

Tolong bantu hanya pada area berikut:
- lib/screens/detail_screen.dart
- bagian edit mode di lib/screens/add_edit_screen.dart
- getDestinationById dan updateDestination di lib/services/database_helper.dart
- getMataUang, setMataUang, getSortBy, setSortBy di lib/services/preferences_service.dart

Jangan merusak fitur CREATE dan READ list milik Person A.
Jangan mengubah delete/checklist milik Person C.
Pastikan setelah update, detail screen reload data terbaru dari SQLite.
```

### Prompt khusus saat error

```txt
Tolong debug error ini berdasarkan struktur project WanderList yang sudah ada.
Jangan membuat file baru kalau bisa diperbaiki di file yang sudah ada.
Jelaskan file mana yang perlu diedit dan bagian kode mana yang perlu diganti.
```

---

## 16. Definition of Done ASM2

ASM2 dianggap selesai jika:

- Aplikasi bisa dijalankan tanpa error.
- User bisa tambah destinasi baru.
- Data destinasi tersimpan ke SQLite.
- Home Screen bisa menampilkan data dari SQLite.
- User bisa membuka detail destinasi.
- User bisa mengedit destinasi.
- User bisa mengubah status dari wishlist ke visited.
- User bisa menghapus destinasi.
- Checklist destinasi bisa ditampilkan, ditambah, dicentang, dan dihapus.
- Statistik menampilkan jumlah data dari SQLite.
- Shared Preferences tersimpan dan terbaca ulang.
- Setiap orang bisa menjelaskan flow CRUD miliknya dari UI ke database.

---

## 17. Catatan Audit / Presentasi

Saat audit ASM2, masing-masing orang wajib bisa menjelaskan:

### Haykal

```txt
Saya mengerjakan CREATE dan READ list.
Saat tombol tambah ditekan, user masuk ke AddEditScreen.
Setelah form disimpan, data dikirim ke insertDestination() lalu masuk ke tabel destinations.
Setelah kembali ke HomeScreen, _loadDestinations() dipanggil untuk refresh data.
```

### Ray

```txt
Saya mengerjakan READ detail dan UPDATE destinasi.
Saat user membuka detail, data diambil ulang berdasarkan id menggunakan getDestinationById().
Saat user menekan edit, AddEditScreen dibuka dalam edit mode.
Setelah data disimpan, updateDestination() menjalankan query UPDATE berdasarkan id.
Setelah kembali ke detail, _reload() dipanggil supaya data terbaru langsung tampil.
```

### Diki

```txt
Saya mengerjakan DELETE dan READ checklist.
Saat destinasi dihapus, aplikasi menghapus checklist_items yang punya destination_id terkait terlebih dahulu.
Setelah itu data di tabel destinations dihapus.
Untuk checklist, data diambil menggunakan getChecklistItems(destinationId), lalu bisa ditambah, dicentang, dan dihapus.
```

---

## 18. Kesimpulan Cross-Check

Struktur repo saat ini sudah cocok dengan schema WanderList.

Yang perlu dilakukan bukan membuat ulang project, tetapi melanjutkan struktur yang sudah ada.

Prioritas sekarang:

1. Stabilkan fitur ASM2.
2. Jangan rename file/folder.
3. Jangan memecah file yang sudah dipakai bersama.
4. Fokus Ray di `detail_screen.dart`, edit mode di `add_edit_screen.dart`, dan fungsi update/read detail di `database_helper.dart`.
5. Setelah ASM2 aman, baru lanjut ASM3 untuk custom widget.
