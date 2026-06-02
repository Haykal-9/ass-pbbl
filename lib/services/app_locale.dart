import 'package:flutter/foundation.dart';

/// Global notifier — widgets rebuild when value changes.
final ValueNotifier<String> bahasaNotifier = ValueNotifier('ID');

/// Translation helper — returns the string for the active language.
String tr(String key) {
  final lang = bahasaNotifier.value;
  return _translations[key]?[lang] ?? _translations[key]?['ID'] ?? key;
}

/// Translate a category value from the database to the current language.
String trCategory(String dbCategory) {
  switch (dbCategory) {
    case 'Wisata Alam':
      return tr('cat_wisata_alam');
    case 'Budaya & Sejarah':
      return tr('cat_budaya_sejarah');
    case 'Kota & Urban':
      return tr('cat_kota_urban');
    default:
      return dbCategory;
  }
}

/// Translate a destination name (seed data only; user-added returns as-is).
String trName(String dbName) {
  return _destNames[dbName]?[bahasaNotifier.value] ?? dbName;
}

/// Translate a country/city string (seed data only; user-added returns as-is).
String trCountry(String dbCountry) {
  return _countryNames[dbCountry]?[bahasaNotifier.value] ?? dbCountry;
}

const Map<String, Map<String, String>> _destNames = {
  'Raja Ampat': {'ID': 'Raja Ampat', 'EN': 'Raja Ampat'},
  'Taman Nasional Komodo': {'ID': 'Taman Nasional Komodo', 'EN': 'Komodo National Park'},
  'Gunung Fuji': {'ID': 'Gunung Fuji', 'EN': 'Mount Fuji'},
  'Air Terjun Niagara': {'ID': 'Air Terjun Niagara', 'EN': 'Niagara Falls'},
  'Taman Nasional Yellowstone': {'ID': 'Taman Nasional Yellowstone', 'EN': 'Yellowstone National Park'},
  'Candi Borobudur': {'ID': 'Candi Borobudur', 'EN': 'Borobudur Temple'},
  'Angkor Wat': {'ID': 'Angkor Wat', 'EN': 'Angkor Wat'},
  'Colosseum': {'ID': 'Colosseum', 'EN': 'Colosseum'},
  'Machu Picchu': {'ID': 'Machu Picchu', 'EN': 'Machu Picchu'},
  'Tembok Besar China': {'ID': 'Tembok Besar China', 'EN': 'Great Wall of China'},
  'Burj Khalifa': {'ID': 'Burj Khalifa', 'EN': 'Burj Khalifa'},
  'Menara Eiffel': {'ID': 'Menara Eiffel', 'EN': 'Eiffel Tower'},
  'Shibuya Crossing': {'ID': 'Shibuya Crossing', 'EN': 'Shibuya Crossing'},
  'Marina Bay Sands': {'ID': 'Marina Bay Sands', 'EN': 'Marina Bay Sands'},
  'Times Square': {'ID': 'Times Square', 'EN': 'Times Square'},
};

const Map<String, Map<String, String>> _countryNames = {
  'Sorong, Indonesia': {'ID': 'Sorong, Indonesia', 'EN': 'Sorong, Indonesia'},
  'Labuan Bajo, Indonesia': {'ID': 'Labuan Bajo, Indonesia', 'EN': 'Labuan Bajo, Indonesia'},
  'Shizuoka, Jepang': {'ID': 'Shizuoka, Jepang', 'EN': 'Shizuoka, Japan'},
  'Ontario, Kanada': {'ID': 'Ontario, Kanada', 'EN': 'Ontario, Canada'},
  'Wyoming, Amerika Serikat': {'ID': 'Wyoming, Amerika Serikat', 'EN': 'Wyoming, United States'},
  'Magelang, Indonesia': {'ID': 'Magelang, Indonesia', 'EN': 'Magelang, Indonesia'},
  'Siem Reap, Kamboja': {'ID': 'Siem Reap, Kamboja', 'EN': 'Siem Reap, Cambodia'},
  'Roma, Italia': {'ID': 'Roma, Italia', 'EN': 'Rome, Italy'},
  'Cusco, Peru': {'ID': 'Cusco, Peru', 'EN': 'Cusco, Peru'},
  'Beijing, China': {'ID': 'Beijing, China', 'EN': 'Beijing, China'},
  'Dubai, UAE': {'ID': 'Dubai, UAE', 'EN': 'Dubai, UAE'},
  'Paris, Prancis': {'ID': 'Paris, Prancis', 'EN': 'Paris, France'},
  'Tokyo, Jepang': {'ID': 'Tokyo, Jepang', 'EN': 'Tokyo, Japan'},
  'Singapura, Singapura': {'ID': 'Singapura, Singapura', 'EN': 'Singapore, Singapore'},
  'New York, Amerika Serikat': {'ID': 'New York, Amerika Serikat', 'EN': 'New York, United States'},
};

const Map<String, Map<String, String>> _translations = {
  // ── General ──────────────────────────────────────────────
  'app_title': {'ID': 'WanderList', 'EN': 'WanderList'},
  'add': {'ID': 'Tambah', 'EN': 'Add'},
  'cancel': {'ID': 'Batal', 'EN': 'Cancel'},
  'delete': {'ID': 'Hapus', 'EN': 'Delete'},
  'save': {'ID': 'Simpan', 'EN': 'Save'},
  'saving': {'ID': 'Menyimpan...', 'EN': 'Saving...'},
  'required_field': {'ID': 'Wajib diisi', 'EN': 'Required'},

  // ── Categories & Status (card display) ───────────────────
  'cat_wisata_alam': {'ID': 'Wisata Alam', 'EN': 'Nature'},
  'cat_budaya_sejarah': {'ID': 'Budaya & Sejarah', 'EN': 'Culture & History'},
  'cat_kota_urban': {'ID': 'Kota & Urban', 'EN': 'City & Urban'},
  'status_visited': {'ID': 'Visited', 'EN': 'Visited'},
  'status_wishlist': {'ID': 'Wishlist', 'EN': 'Wishlist'},

  // ── Home screen ──────────────────────────────────────────
  'search_hint': {'ID': 'Cari destinasi...', 'EN': 'Search destination...'},
  'filter_all': {'ID': 'Semua', 'EN': 'All'},
  'filter_wishlist': {'ID': 'Wishlist', 'EN': 'Wishlist'},
  'filter_visited': {'ID': 'Visited', 'EN': 'Visited'},
  'sort_latest': {'ID': 'Terbaru', 'EN': 'Latest'},
  'sort_az': {'ID': 'A–Z', 'EN': 'A–Z'},
  'sort_category': {'ID': 'Kategori', 'EN': 'Category'},
  'sort_tooltip': {'ID': 'Urutkan', 'EN': 'Sort'},
  'stats_tooltip': {'ID': 'Statistik', 'EN': 'Statistics'},
  'settings_tooltip': {'ID': 'Pengaturan', 'EN': 'Settings'},
  'list_view': {'ID': 'List view', 'EN': 'List view'},
  'grid_view': {'ID': 'Grid view', 'EN': 'Grid view'},
  'empty_no_results': {'ID': 'Tidak ada hasil', 'EN': 'No results'},
  'empty_no_dest': {
    'ID': 'Belum ada destinasi',
    'EN': 'No destinations yet',
  },
  'empty_hint_filter': {
    'ID': 'Coba ubah filter atau kata kunci pencarian',
    'EN': 'Try changing filters or search keyword',
  },
  'empty_hint_add': {
    'ID': 'Tap + untuk menambahkan destinasi impianmu!',
    'EN': 'Tap + to add your dream destination!',
  },
  'delete_title': {'ID': 'Hapus Destinasi?', 'EN': 'Delete Destination?'},
  'delete_dest_confirm': {
    'ID': 'beserta semua checklist-nya? Aksi ini tidak bisa dibatalkan.',
    'EN': 'along with all checklists? This action cannot be undone.',
  },

  // ── Add / Edit screen ────────────────────────────────────
  'add_dest': {'ID': 'Tambah Destinasi', 'EN': 'Add Destination'},
  'edit_dest': {'ID': 'Edit Destinasi', 'EN': 'Edit Destination'},
  'add_photo': {'ID': 'Tambah Foto', 'EN': 'Add Photo'},
  'dest_name': {'ID': 'Nama Destinasi', 'EN': 'Destination Name'},
  'country_city': {'ID': 'Negara / Kota', 'EN': 'Country / City'},
  'category': {'ID': 'Kategori', 'EN': 'Category'},
  'status': {'ID': 'Status', 'EN': 'Status'},
  'visit_date': {
    'ID': 'Tanggal Kunjungan (YYYY-MM-DD)',
    'EN': 'Visit Date (YYYY-MM-DD)',
  },
  'visit_date_required': {
    'ID': 'Tanggal kunjungan wajib diisi',
    'EN': 'Visit date is required',
  },
  'notes_optional': {'ID': 'Catatan (opsional)', 'EN': 'Notes (optional)'},

  // ── Detail screen ────────────────────────────────────────
  'notes_label': {'ID': 'Catatan', 'EN': 'Notes'},
  'visited_on': {'ID': 'Dikunjungi', 'EN': 'Visited on'},
  'added_on': {'ID': 'Ditambahkan', 'EN': 'Added on'},
  'delete_dest_title': {'ID': 'Hapus Destinasi', 'EN': 'Delete Destination'},
  'delete_dest_confirm_detail': {
    'ID': 'Apakah Anda yakin ingin menghapus',
    'EN': 'Are you sure you want to delete',
  },

  // ── Checklist screen ─────────────────────────────────────
  'checklist_title': {'ID': 'Checklist', 'EN': 'Checklist'},
  'checklist_progress': {
    'ID': 'Progres Perjalanan',
    'EN': 'Travel Progress',
  },
  'checklist_done_of': {'ID': 'dari', 'EN': 'of'},
  'checklist_complete': {'ID': 'Selesai', 'EN': 'Done'},
  'checklist_empty': {
    'ID': 'Belum ada aktivitas',
    'EN': 'No activities yet',
  },
  'checklist_empty_hint': {
    'ID': 'Ketik di bawah untuk menambahkannya!',
    'EN': 'Type below to add one!',
  },
  'checklist_add_hint': {
    'ID': 'Tambah hal yang ingin dilakukan...',
    'EN': 'Add something to do...',
  },
  'confirm_delete': {'ID': 'Anda Yakin?', 'EN': 'Are you sure?'},
  'delete_checklist_msg': {
    'ID': 'dari checklist?',
    'EN': 'from checklist?',
  },

  // ── Statistics screen ────────────────────────────────────
  'stats_title': {
    'ID': 'Statistik Perjalanan',
    'EN': 'Travel Statistics',
  },
  'stats_summary': {'ID': 'Ringkasan', 'EN': 'Summary'},
  'stats_total': {'ID': 'Total Destinasi', 'EN': 'Total Destinations'},
  'stats_visited': {'ID': 'Sudah Dikunjungi', 'EN': 'Already Visited'},
  'stats_by_category': {
    'ID': 'Berdasarkan Kategori',
    'EN': 'By Category',
  },
  'stats_budget': {'ID': 'Anggaran', 'EN': 'Budget'},
  'stats_total_budget': {
    'ID': 'Total Estimasi Budget',
    'EN': 'Total Estimated Budget',
  },

  // ── Budget screen ────────────────────────────────────────
  'budget_title': {'ID': 'Budget', 'EN': 'Budget'},
  'budget_estimate': {'ID': 'Estimasi Budget', 'EN': 'Budget Estimate'},
  'budget_used': {'ID': 'Total Budget Digunakan', 'EN': 'Total Budget Used'},
  'budget_total': {'ID': 'Total Estimasi', 'EN': 'Estimated Total'},
  'budget_none': {'ID': 'Belum dianggarkan', 'EN': 'Not budgeted yet'},
  'budget_items_count': {'ID': 'item', 'EN': 'items'},
  'budget_add': {'ID': 'Tambah Anggaran', 'EN': 'Add Budget'},
  'budget_edit': {'ID': 'Edit Anggaran', 'EN': 'Edit Budget'},
  'budget_label': {'ID': 'Keterangan', 'EN': 'Description'},
  'budget_amount': {'ID': 'Perkiraan Biaya', 'EN': 'Estimated Cost'},
  'budget_amount_invalid': {
    'ID': 'Masukkan jumlah yang valid',
    'EN': 'Enter a valid amount',
  },
  'budget_category': {'ID': 'Kategori', 'EN': 'Category'},
  'budget_empty': {
    'ID': 'Belum ada anggaran',
    'EN': 'No budget items yet',
  },
  'budget_empty_hint': {
    'ID': 'Tap + untuk menambahkan estimasi biaya!',
    'EN': 'Tap + to add a cost estimate!',
  },
  'budget_cat_transport': {'ID': 'Transportasi', 'EN': 'Transport'},
  'budget_cat_akomodasi': {'ID': 'Akomodasi', 'EN': 'Accommodation'},
  'budget_cat_makanan': {'ID': 'Makanan', 'EN': 'Food'},
  'budget_cat_aktivitas': {'ID': 'Tiket & Aktivitas', 'EN': 'Tickets & Activities'},
  'budget_cat_lainnya': {'ID': 'Lainnya', 'EN': 'Other'},

  // ── Settings screen ──────────────────────────────────────
  'settings_title': {'ID': 'Pengaturan', 'EN': 'Settings'},
  'settings_display': {'ID': 'Tampilan', 'EN': 'Display'},
  'settings_display_mode': {'ID': 'Mode Tampilan', 'EN': 'Display Mode'},
  'settings_display_desc': {
    'ID': 'Grid atau List di Home',
    'EN': 'Grid or List on Home',
  },
  'settings_currency': {'ID': 'Mata Uang', 'EN': 'Currency'},
  'settings_pref': {'ID': 'Preferensi', 'EN': 'Preferences'},
  'settings_lang': {'ID': 'Bahasa', 'EN': 'Language'},
  'settings_sort': {'ID': 'Urutkan Destinasi', 'EN': 'Sort Destinations'},
  'settings_theme_section': {
    'ID': 'Tema & Tampilan Tambahan',
    'EN': 'Theme & Additional Display',
  },
  'settings_theme': {'ID': 'Tema Warna', 'EN': 'Color Theme'},
  'settings_checklist_progress': {
    'ID': 'Progres Checklist',
    'EN': 'Checklist Progress',
  },
  'settings_checklist_desc': {
    'ID': 'Tampilkan bar progres di beranda',
    'EN': 'Show progress bar on home',
  },

  // ── Bottom Navigation ─────────────────────────────────────
  'nav_home': {'ID': 'Beranda', 'EN': 'Home'},
  'nav_stats': {'ID': 'Statistik', 'EN': 'Statistics'},
  'nav_settings': {'ID': 'Pengaturan', 'EN': 'Settings'},
};
