import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefs = PreferencesService();

  // PERSON A
  String _tampilanMode = 'grid';
  String _mataUang = 'IDR';

  // PERSON B
  String _bahasa = 'ID';
  String _sortBy = 'terbaru';

  // PERSON C
  String _temaWarna = 'teal';
  bool _showMapDefault = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final all = await _prefs.loadAllPrefs();
    if (mounted) {
      setState(() {
        _tampilanMode = all['tampilan_mode'] as String;
        _mataUang = all['mata_uang'] as String;
        _bahasa = all['bahasa'] as String;
        _sortBy = all['sort_by'] as String;
        _temaWarna = all['tema_warna'] as String;
        _showMapDefault = all['show_map_default'] as bool;
        _isLoading = false;
      });
    }
  }

  Color _themeColor(String theme) {
    switch (theme) {
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'teal':
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          // ─── PERSON A ──────────────────────────────────────────
          _sectionHeader('Tampilan (Person A)'),
          ListTile(
            title: const Text('Mode Tampilan'),
            subtitle: const Text('Grid atau List di Home'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'grid', icon: Icon(Icons.grid_view, size: 18)),
                ButtonSegment(value: 'list', icon: Icon(Icons.list, size: 18)),
              ],
              selected: {_tampilanMode},
              onSelectionChanged: (s) async {
                setState(() => _tampilanMode = s.first);
                await _prefs.setTampilanMode(s.first);
              },
            ),
          ),
          ListTile(
            title: const Text('Mata Uang'),
            subtitle: Text(_mataUang),
            trailing: DropdownButton<String>(
              value: _mataUang,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'IDR', child: Text('IDR')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _mataUang = v);
                await _prefs.setMataUang(v);
              },
            ),
          ),

          // ─── PERSON B ──────────────────────────────────────────
          _sectionHeader('Preferensi (Person B)'),
          ListTile(
            title: const Text('Bahasa'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ID', label: Text('ID')),
                ButtonSegment(value: 'EN', label: Text('EN')),
              ],
              selected: {_bahasa},
              onSelectionChanged: (s) async {
                setState(() => _bahasa = s.first);
                await _prefs.setBahasa(s.first);
              },
            ),
          ),
          ListTile(
            title: const Text('Urutkan Destinasi'),
            subtitle: Text(_sortByLabel(_sortBy)),
            trailing: DropdownButton<String>(
              value: _sortBy,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'terbaru', child: Text('Terbaru')),
                DropdownMenuItem(value: 'az', child: Text('A–Z')),
                DropdownMenuItem(value: 'kategori', child: Text('Kategori')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _sortBy = v);
                await _prefs.setSortBy(v);
              },
            ),
          ),

          // ─── PERSON C ──────────────────────────────────────────
          _sectionHeader('Tema & Tampilan (Person C)'),
          ListTile(
            title: const Text('Tema Warna'),
            subtitle: const Text('Berlaku setelah restart'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: ['teal', 'orange', 'purple'].map((t) {
                final selected = _temaWarna == t;
                return GestureDetector(
                  onTap: () async {
                    setState(() => _temaWarna = t);
                    await _prefs.setTemaWarna(t);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _themeColor(t),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.black54, width: 2.5)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          SwitchListTile(
            title: const Text('Tampilkan Peta Secara Default'),
            subtitle: const Text('Tab peta aktif saat buka detail'),
            value: _showMapDefault,
            onChanged: (v) async {
              setState(() => _showMapDefault = v);
              await _prefs.setShowMapDefault(v);
            },
          ),
          const SizedBox(height: 24),
          if (_temaWarna != 'teal')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tema warna akan diterapkan setelah aplikasi di-restart.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  String _sortByLabel(String v) {
    switch (v) {
      case 'az':
        return 'A–Z';
      case 'kategori':
        return 'Kategori';
      default:
        return 'Terbaru';
    }
  }
}
