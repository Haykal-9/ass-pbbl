# Rencana Pengembangan Fitur Galeri Foto Polaroid

Dokumen ini merincikan rencana matang (*blueprint*) untuk membangun fitur "Galeri Memori Tumpukan Polaroid" pada aplikasi WanderList sebagai bagian dari Asesmen 3.

## 1. Analisis Kebutuhan & Solusi Teknis

Fitur ini membutuhkan tiga elemen utama sesuai persyaratan ASM3:
1. **Custom Widget (Medium)**: `PolaroidDeckGallery`
2. **Custom Drawing**: `PolaroidPainter`
3. **Gesture (Selain Tap)**: Swipe/Drag menggunakan `GestureDetector` (`onPanUpdate`, `onPanEnd`).

### Kendala Asesmen 2 (ASM2) vs ASM3
Pada ASM2, tabel `destinations` hanya menyimpan satu `photo_path`. Sebuah *deck* polaroid tidak akan terlihat estetik jika hanya ada 1 kartu. Oleh karena itu, kita harus **memperluas skema database** dengan tabel baru.

## 2. Rencana Pembaruan Database (Database Migration)

Kita akan menaikkan versi database menjadi `7` dan membuat tabel baru:
**Tabel `destination_photos`**
- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `destination_id` INTEGER NOT NULL (Relasi ke destinations)
- `photo_path` TEXT NOT NULL
- `caption` TEXT
- `created_at` TEXT NOT NULL

**Strategi Migrasi:**
1. Buat tabel `destination_photos`.
2. Pindahkan data `photo_path` dari tabel `destinations` ke `destination_photos` secara otomatis saat aplikasi dimuat agar foto lama tidak hilang.
3. *Seed* data foto dummy (dari web/unsplash) untuk destinasi bawaan agar *deck* langsung terlihat penuh.

## 3. Desain Komponen UI (Custom Widget & Painter)

### Struktur Polaroid Card
Seperti yang Anda sarankan secara cerdas, me-*render* gambar langsung di `CustomPainter` via `canvas.drawImage` membutuhkan manajemen asinkron yang rumit. 
Solusi *best practice*:
```dart
Stack(
  children: [
    // Layer 1: Frame Polaroid (digambar dengan BoxDecoration atau CustomPainter)
    CustomPaint(
      painter: PolaroidBackgroundPainter(), // Menggambar background putih & shadow
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 60), // Margin bawah besar khas polaroid
        child: Image.network(photo.path), // Menampilkan gambar asli
      ),
    ),
    // Layer 2: Ornamen (Washi Tape / Pin)
    Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: CustomPaint(
        painter: WashiTapePainter(), // Menggambar selotip tembus pandang
        size: Size(double.infinity, 40),
      ),
    ),
  ]
)
```

### Logika Tumpukan (*Deck*) & Gestur Tinder-Swipe
Widget `PolaroidDeckGallery` akan menggunakan `Stack` untuk menumpuk kartu.
- **Card yang di bawah**: Akan diberi sedikit rotasi (misal: -5 derajat, +3 derajat) secara acak agar terlihat berantakan secara estetik.
- **Card Paling Atas (Top Card)**: Dibungkus dengan `GestureDetector`.
  - `onPanUpdate`: Mengubah posisi X, Y, dan rotasi kartu mengikuti jari pengguna.
  - `onPanEnd`: Menghitung kecepatan (velocity) lemparan. Jika melewati batas layar, kartu dianimasikan terbang keluar (kiri/kanan) dan dihapus dari tumpukan (pindah ke tumpukan paling bawah atau hilang sementara). Jika tidak, kartu dianimasikan kembali ke tengah (spring animation).

## 4. Kebutuhan Layar (Screen)

- **`gallery_screen.dart`**: Halaman utama yang memuat `PolaroidDeckGallery`. Terdapat tombol "Tambah Foto" yang akan membuka Image Picker untuk menambah foto ke destinasi tersebut.

## 5. Rencana Pengujian (Test Plan)

1. **Test DB Migration**: Memastikan foto dari destinasi lama berhasil berpindah ke tabel baru.
2. **Test Gesture**: Memastikan lemparan kartu mulus pada 60fps baik di Chrome (Web) maupun Android.
3. **Test Skala Layar**: Memastikan ukuran Polaroid menyesuaikan ukuran layar tanpa mengalami *overflow*.

---
*Dokumen ini disusun untuk mengantisipasi masalah asinkronisasi gambar pada canvas dan arsitektur database relasional yang krusial bagi fitur ASM3.*
