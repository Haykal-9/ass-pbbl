import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._();
  factory PreferencesService() => _instance;
  PreferencesService._();

  // ─────────────────────────────────────────────────────────────────
  // PERSON A — mata_uang + tampilan_mode
  // ─────────────────────────────────────────────────────────────────

  static const String _kMataUang = 'mata_uang';
  static const String _kTampilanMode = 'tampilan_mode';

  Future<String> getMataUang() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kMataUang) ?? 'IDR';
  }

  Future<void> setMataUang(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMataUang, value);
  }

  /// Returns 'grid' or 'list'
  Future<String> getTampilanMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTampilanMode) ?? 'grid';
  }

  Future<void> setTampilanMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTampilanMode, mode);
  }

  // ─────────────────────────────────────────────────────────────────
  // PERSON B — bahasa + sort_by
  // ─────────────────────────────────────────────────────────────────

  static const String _kBahasa = 'bahasa';
  static const String _kSortBy = 'sort_by';

  /// Returns 'ID' or 'EN'
  Future<String> getBahasa() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBahasa) ?? 'ID';
  }

  Future<void> setBahasa(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBahasa, lang);
  }

  /// Returns 'az' | 'terbaru' | 'kategori'
  Future<String> getSortBy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSortBy) ?? 'terbaru';
  }

  Future<void> setSortBy(String sortBy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSortBy, sortBy);
  }

  // ─────────────────────────────────────────────────────────────────
  // PERSON C — tema_warna + show_map_default
  // ─────────────────────────────────────────────────────────────────

  static const String _kTemaWarna = 'tema_warna';
  static const String _kShowMapDefault = 'show_map_default';

  /// Returns 'teal' | 'orange' | 'purple'
  Future<String> getTemaWarna() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTemaWarna) ?? 'teal';
  }

  Future<void> setTemaWarna(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTemaWarna, theme);
  }

  Future<bool> getShowMapDefault() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowMapDefault) ?? false;
  }

  Future<void> setShowMapDefault(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowMapDefault, value);
  }

  // ─────────────────────────────────────────────────────────────────
  // Convenience
  // ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loadAllPrefs() async {
    return {
      'mata_uang': await getMataUang(),
      'tampilan_mode': await getTampilanMode(),
      'bahasa': await getBahasa(),
      'sort_by': await getSortBy(),
      'tema_warna': await getTemaWarna(),
      'show_map_default': await getShowMapDefault(),
    };
  }
}
