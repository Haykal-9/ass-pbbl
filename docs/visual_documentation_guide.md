# Panduan Visual Dokumentasi README.md (WanderList)

Berdasarkan arsitektur dan fitur kompleks dari aplikasi **WanderList**, berikut adalah panduan (*Shot List*) lengkap tentang aset visual (Screenshot & GIF) apa saja yang harus kamu siapkan menggunakan Canva, dan bagaimana cara menampilkannya secara strategis di README agar memukau perekrut.

Aplikasi WanderList memiliki fitur unggulan berupa tema dinamis (*Canopy, Urban Slate, Ancient Earth*), *Trip Planner* dengan peta, *Scratch Card*, dan *Social Gallery*. Kita harus memamerkan **semuanya** tanpa membuat README terlalu penuh.

---

## 1. Hero Image (Bagian Paling Atas)
Ini adalah gambar pertama yang dilihat pengunjung. Tujuannya adalah memamerkan *UI (User Interface)* yang cantik dan variasi tema yang dimiliki aplikasi.

*   **Format:** 1 Gambar statis lebar (resolusi Canva 1600x900).
*   **Isi:** 3 *Frame* HP yang diletakkan berdampingan secara proporsional.
*   **Skenario Tangkapan Layar (Sangat Penting):**
    *   **HP 1 (Kiri):** Halaman **Home Screen** (Mode Grid) menampilkan daftar destinasi Wishlist. Gunakan tema **Canopy (Hijau/Terang)** agar terlihat segar.
    *   **HP 2 (Tengah & Sedikit lebih besar/maju):** Halaman **Trip Planner / Peta (OpenRouteService)**. Gunakan tema **Urban Slate (Gelap/Dark Mode)**. Menempatkan peta mode gelap di tengah akan memberikan kontras yang sangat elegan dan menonjolkan fitur paling teknis dari aplikasimu.
    *   **HP 3 (Kanan):** Halaman **Social Gallery**. Gunakan tema **Ancient Earth (Coklat/Klasik)** yang sangat cocok dengan visual foto-foto estetik dari pengguna.

## 2. Fitur Interaktif & Teknis (Bagian Tengah - GIF)
Perekrut (*Hiring Manager*) suka melihat kode yang sulit diimplementasikan, seperti animasi kustom dan peta. Gunakan GIF di sini agar otomatis memutar (*auto-play*).

*   **Format:** 2 buah GIF berdampingan (Gunakan HTML `<img width="350">` agar rapi).
*   **Skenario GIF 1 (Gamifikasi):** Merekam fitur **Scratch Card**. Mulai rekam saat jari menggosok kartu destinasi *wishlist* yang belum terbuka, hingga gambar destinasi (misalnya Raja Ampat) terungkap sepenuhnya. (Durasi ideal: 6 detik).
*   **Skenario GIF 2 (Kompleksitas Data):** Merekam fitur **Trip Planner & Cuaca**. Rekam saat *user* melihat urutan *itinerary* (hari 1, hari 2), men-scroll cuaca (OpenWeather API), lalu melihat garis rute perjalanan ditarik di atas peta (`flutter_map`). (Durasi ideal: 10 detik).

## 3. Grid Fitur Esensial (Bagian Bawah - 2x2 Screenshot)
Untuk menunjukkan bahwa ini adalah aplikasi berskala penuh dengan fungsionalitas CRUD dan arsitektur yang solid, tunjukkan halaman-halaman fungsional.

*   **Format:** Tabel Markdown 2 baris dan 2 kolom. Setiap sel berisi 1 *frame* HP (Kanvas Canva 450x950px, ditampilkan di README dengan `width="250"`).
*   **Skenario Tangkapan Layar:**
    *   **Gambar 1 (Kiri Atas): Halaman Detail Destinasi.** Menunjukkan bagaimana data destinasi (deskripsi, status) ditampilkan.
    *   **Gambar 2 (Kanan Atas): Halaman Budget Management.** Menunjukkan fitur pelacakan pengeluaran yang terstruktur. 
    *   **Gambar 3 (Kiri Bawah): Halaman Checklist / Timeline.** Menunjukkan fitur *to-do list* saat liburan.
    *   **Gambar 4 (Kanan Bawah): Halaman Pengaturan (Settings & Profile).** Membuktikan bahwa aplikasi ini memiliki *State Management* yang baik karena *user* bisa mengganti mata uang, bahasa, dan tema warna dari sini.

---

## 4. Tips Tambahan Saat Mengambil Screenshot

1.  **Gunakan Data yang Masuk Akal (Dummy Data Berkualitas):** Jangan menggunakan nama "Test 123" atau deskripsi "asdfghjkl". Gunakan data *seed* yang sudah ada di aplikasimu (Raja Ampat, Gunung Fuji, dll) beserta fotonya yang berkualitas (*Unsplash*). Ini menunjukkan profesionalitas tingkat tinggi.
2.  **Sembunyikan Debug Banner:** Sebelum *screenshot* atau *screen record*, pastikan label merah "DEBUG" di pojok kanan atas aplikasi Flutter sudah dimatikan.
    *(Cara: `debugShowCheckedModeBanner: false` di `MaterialApp` pada `main.dart`)*.
3.  **Matikan Indikator Status Bar HP (Opsional tapi Pro):** Jika memakai emulator Android/iOS, bersihkan *status bar* agar jam menunjuk waktu 12:00, baterai penuh, dan ikon notifikasi bersih (bisa menggunakan *System UI Tuner* di emulator Android).

Dengan komposisi visual di atas, README-mu tidak hanya menjelaskan apa yang bisa dilakukan aplikasimu, tetapi juga membuktikan kualitas desain, keragaman status (*dark/light/themes*), dan kompleksitas teknis tanpa perlu membuat pengunjung repot men-*download* aplikasinya.
