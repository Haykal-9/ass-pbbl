# Laporan Implementasi Asesmen 2 & 3 
**Anggota Tim:** Diki (Person C)

Dokumen ini dirancang sebagai *Knowledge Base* (Pusat Informasi) fungsional yang merangkum analisis arsitektur dari fitur yang telah diimplementasikan dalam aplikasi WanderList. Dokumen ini dapat memandu AI atau *developer* untuk memahami spesifikasi Asesmen 2 (Fokus Checklist & Penyimpanan) dan Asesmen 3 (Fokus Rencana Perjalanan & Interaktivitas).

---

## 🟢 Asesmen 2: Fitur Checklist & Persistensi Data

Pada Asesmen 2, fokus pengembangan ada pada pembuatan fungsionalitas **Checklist** bawaan wisata beserta pengintegrasian sistem penyimpanan data lokal.

### 1. SQLite (Basis Data Relasional)
Operasi basis data untuk fitur Checklist dikelola di dalam `lib/services/database_helper.dart`.
*   **CRUD Checklist (`checklist_items`)**:
    *   **Create/Read**: Pengguna dapat menambah dan melihat daftar barang bawaan/tugas yang harus diselesaikan untuk tiap destinasi.
    *   **Update**: Memperbarui status centang (*is_done*) ke dalam database saat ditekan, serta memperbarui urutan indeks letak item (`order_index`).
    *   **Delete**: Menghapus item bawaan/tugas dari *database* secara permanen menggunakan aksi usap (swipe).

### 2. Shared Preferences (Penyimpanan Key-Value)
Pengelolaan pengaturan global disimpan menggunakan paket `shared_preferences`, dikoordinasikan dalam `lib/services/preferences_service.dart`.
*   **Tema Warna (Color Theme)**: Pengguna dapat memilih skema warna aplikasi (Hijau, Cokelat, Abu-biru). Preferensi ini disimpan dengan kunci `theme_color` dan langsung diterapkan di antarmuka seluruh fitur Checklist.
*   **Show Progress Bar**: Pengaturan *boolean* independen untuk menampilkan atau menyembunyikan panel *Progress Bar* (indikator progres penyelesaian *checklist*).

### 3. Gesture (Interaksi Gestur pada Checklist)
*   **Drag & Drop (`ReorderableListView` & `ReorderableDragStartListener`)**: Pada layar Checklist, ditambahkan *gesture* tekan-tahan (*long press*) kemudian seret (*drag*) yang memungkinkan pengguna untuk mengubah urutan prioritas barang bawaan secara interaktif.

### 4. Hierarki File Terkait (Knowledge Base Alur Kerja)
Untuk mengembangkan atau memodifikasi fitur Asesmen 2 ini, AI/Developer harus mengelompokkan file secara logis dengan urutan dependensi sebagai berikut:
1. **Lapis Basis Data**: `lib/services/database_helper.dart` (Pendefinisian skema tabel `checklist_items` dan logika CRUD).
2. **Lapis Pengaturan**: `lib/services/preferences_service.dart` (Pengendali Shared Preferences untuk tema warna & *progress bar*).
3. **Lapis Model**: `lib/models/checklist_item.dart` (Kerangka representasi data untuk objek *Checklist*).
4. **Lapis Komponen (Widget)**: `lib/widgets/swipeable_checklist_item.dart` (Komponen spesifik yang menangani UI per-item dan gestur geser-untuk-menghapus).
5. **Lapis Layar Utama (Screen)**: `lib/screens/checklist_screen.dart` (Koordinator utama yang memanggil API database, menerapkan pengaturan tema, dan membungkus data dengan gestur *Drag & Drop*).
6. **Lapis Konfigurasi (Screen)**: `lib/screens/settings_screen.dart` (Layar tempat *user* berinteraksi memicu perubahan *Shared Preferences*).

---

## 🔵 Asesmen 3: Rencana Perjalanan (Trip Planner)

Asesmen 3 berfokus pada pengalaman pengguna tingkat lanjut melalui pembangunan antarmuka kompleks. Fitur **Rencana Perjalanan (Trip Planner)** ini menggabungkan manajemen SQLite khusus rute perjalanan (`trip_stops`) yang diperkaya dengan elemen interaktif berikut:

### 1. Custom Widget (Komponen Kustomisasi Sendiri)
*   **`TripTimelineItem`**: Widget kustom yang membungkus antarmuka garis waktu (*timeline*). Memanajemen *layout* vertikal secara presisi, termasuk garis penghubung, rentang kedatangan, perhitungan *end time*, hingga tampilan informasi operasional.
*   **`TripMapWidget`**: Widget pembungkus untuk memvisualisasikan rute *Polyline* di atas peta interaktif secara otomatis berdasarkan urutan titik *latitude/longitude* di Rencana Perjalanan.
*   **`AddStopSheet`**: *Bottom Sheet* layar penuh kustom yang sangat kompleks, digunakan sebagai form penambahan lokasi rute perjalanan lengkap dengan sinkronisasi API *geocoding*.

### 2. Custom Drawing (`CustomPaint`)
*   **`NumberedMarkerPainter`**: Class ini diturunkan dari `CustomPainter` dan dipanggil di dalam `TripMapWidget` untuk menggambar pin penanda rute di atas peta secara manual (piksel demi piksel).
    *   **Detail Drawing**: Menggunakan API `Canvas` untuk menggambar bayangan objek (*drop shadow* via `MaskFilter`), lingkaran utama, cincin *highlight* semi-transparan saat titik sedang disorot, dan menggunakan `TextPainter` untuk mencetak angka urutan kunjungan di tengah lingkaran.

### 3. Gesture (Interaksi Gestur pada Rencana Perjalanan)
*   **Swipe to Delete (`Dismissible`)**: Diimplementasikan pada `TripTimelineItem` agar pengguna dapat mengusap/menggeser *card* rute perjalanan ke kiri/kanan untuk membuang jadwal tersebut secara instan.
*   **Pan, Zoom, & Pinch (`InteractiveFlag.all`)**: Diaktifkan pada `FlutterMap` dalam widget `TripMapWidget`, memberikan kebebasan bagi pengguna untuk menggunakan dua jari untuk mencubit (*pinch-to-zoom*) serta menyeret peta (*pan gesture*) saat melihat rute perjalanan.
*   **Expandable Tap (`InkWell` / `GestureDetector`)**: Pada *card timeline*, gestur ketuk/klik memicu efek riak (*ripple*) serta mengekspansi *card* untuk mengungkap informasi alamat, jam operasional, dan durasi singgah yang disembunyikan.

### 4. Tools & Teknologi yang Digunakan
*   **Framework & Bahasa**: Flutter, Dart.
*   **Teknologi Penyimpanan**: SQLite (untuk penyimpanan data rute perjalanan secara terstruktur).
*   **Layanan API Eksternal**: OpenStreetMap (peta/basemap), Nominatim (pencarian alamat/geocoding), OpenRouteService (penggambaran garis rute navigasi), OpenWeatherMap (informasi cuaca dinamis di Trip Planner).

### 5. Library Tambahan yang Digunakan beserta Alasan
*   **`flutter_map`**: Dipilih karena merupakan pustaka *open-source* serbaguna yang kuat untuk me-render *tile* OpenStreetMap tanpa perlu integrasi SDK tertutup atau API *billing* berbayar seperti Google Maps.
*   **`latlong2`**: Dipilih untuk mempermudah sistem dalam memanipulasi titik koordinat dan menghitung jarak aktual antar lokasi perjalanan menggunakan formula haversine di dalam peta.
*   **`http`**: Dipilih untuk mengelola pemanggilan *request* asinkronus ke REST API eksternal (cuaca, alamat, dan rute) secara langsung, ringan, dan andal.
*   **`flutter_dotenv`**: Dipilih untuk menyembunyikan dan mengamankan kunci API (seperti API Key OpenRouteService & OpenWeatherMap) dari publik, memastikan keamanan repositori (*best practice*).
*   **`intl`**: Dipilih agar tanggal dan waktu dalam rencana perjalanan dapat diformat secara cerdas dan beradaptasi secara dinamis sesuai dengan lokalisasi aplikasi.

### 6. Hierarki File Terkait (Knowledge Base Alur Kerja)
Untuk membangun keseluruhan arsitektur Rencana Perjalanan secara komprehensif, implementasi harus melewati rantai file berikut secara berurutan:
1. **Lapis Keamanan Konfigurasi**: `lib/services/api_constants.dart` & `.env` (Penyimpanan API Key yang wajib diinisiasi di awal sebelum memanggil layanan).
2. **Lapis Model**: `lib/models/trip_stop.dart` (Pembuatan *blueprint* data yang menampung segala informasi rute, waktu, dan koordinat).
3. **Lapis Basis Data**: `lib/services/database_helper.dart` (Membangun relasi tabel `trip_stops` dan `destinations`, serta integrasi *query* SQL).
4. **Lapis Layanan Pihak Ketiga (API Services)**:
    *   `lib/services/osm_nominatim_service.dart` (Fungsi untuk menerjemahkan alamat string menjadi *latitude/longitude*).
    *   `lib/services/openrouteservice_service.dart` (Fungsi untuk menarik poligon garis lintasan dari API *Routing*).
    *   `lib/services/weather_service.dart` (Fungsi penarikan cuaca dinamis berdasarkan tanggal dan koordinat target).
5. **Lapis Komponen (Custom Widgets & Drawings)**:
    *   `lib/widgets/trip_timeline_item.dart` (Visualisasi blok jadwal dengan fitur gestur *expand/swipe*).
    *   `lib/widgets/trip_map_widget.dart` (Perenderan visual peta yang mengeksekusi `NumberedMarkerPainter`).
    *   `lib/widgets/add_stop_sheet.dart` (Form interaktif untuk pencarian *geocoding* dan pengumpulan *input user*).
6. **Lapis Layar Utama (Screen Koordinator)**: `lib/screens/trip_planner_screen.dart` (Ini adalah otak utama; menyatukan basis data, hasil *request* layanan API cuaca/peta, melempar data ke dalam kustom *widget* garis waktu/peta, dan memfasilitasi interaksi penuh dari pengguna).

### 7. Checklist Pengetesan Fitur (Test Cases)
Berikut adalah daftar skenario pengujian komprehensif yang dirancang khusus untuk mengevaluasi fungsionalitas Rencana Perjalanan (Asesmen 3). Pengujian ini mencakup antarmuka, alur logika, hingga integrasi API eksternal.

#### A. Pengujian Antarmuka Pengguna (UI/UX)
- [ ] **Validasi Warna Tema (Dinamis):** Mengubah tema di halaman pengaturan (misal: Cokelat) harus secara instan mengubah warna garis *timeline*, bayangan *card*, teks jam, dan *highlight* peta.
- [ ] **Pengujian Overflow pada Form (Statis & Dinamis):** Membuka form `AddStopSheet`. Memastikan seluruh input layar terlihat dan tidak ada peringatan *overflow* pada keyboard virtual atau layar berukuran kecil.
- [ ] **Penyesuaian Batas Peta / Bounds (Dinamis):** Saat berpindah hari atau mengubah destinasi, `TripMapWidget` harus secara otomatis melakukan *zoom* dan *pan* untuk memastikan seluruh jalur Polyline masuk ke dalam bingkai layar tanpa terpotong.
- [ ] **Interaksi Expand/Collapse Timeline (Dinamis):** Mengetuk *card timeline* tunggal harus menganimasikan pembukaan alamat dan jam operasional tanpa merusak urutan atau tata letak elemen lain di bawahnya.

#### B. Pengujian Alur Logika (Logic Flow)
- [ ] **Kalkulasi Waktu Efektif (Dinamis):** Sistem harus berhasil menjumlahkan selisih antara *visit time* pertama hingga *end time* dari lokasi terakhir, **dan sukses mengurangi total waktu tempuh harian (travel time)**, sehingga menampilkan durasi bersih di *Progress Bar*.
- [ ] **Siklus Hidup Data - Tambah & Hapus (Dinamis):**
    *   **Tambah:** Menyimpan rute baru via *bottom sheet* harus langsung memunculkan *card* baru di *timeline* dan titik baru di peta (berurutan berdasarkan indeks/jam).
    *   **Hapus:** Melakukan gestur *swipe-to-delete* pada *card timeline* harus segera menghapus entri dari database SQLite dan secara otomatis me-render ulang poligon lintasan (rute) di peta tanpa harus me-refresh aplikasi.
- [ ] **Mekanisme Fallback Cuaca (Dinamis):** Jika hari perjalanan berada di luar cakupan batas 5 hari (API Forecast OpenWeather), sistem harus mampu mencegat (intercept) kegagalan dan secara cerdas mengalihkan pemanggilan ke *Current Weather API* untuk tetap memberikan laporan cuaca aktual yang dinamis, bukan sekadar angka mati (*mock* statis).

#### C. Pengujian Integrasi API (Network & Third-Party)
- [ ] **Uji Geocoding Nominatim (Dinamis):** Memasukkan kata kunci seperti "Gedung Sate" di form pencarian harus dapat ditarik (*fetch*) ke internet dan dikembalikan sebagai string alamat lengkap serta pasangan koordinat *Latitude/Longitude* secara presisi.
- [ ] **Uji Routing OpenRouteService (Dinamis):** Aplikasi harus sukses mengirim dua buah koordinat berdekatan ke API ORS, menerima respons array *GeoJSON*, lalu memplotnya menjadi satu garis rute (*Polyline*) tak terputus (*seamless*) pada `FlutterMap`.
