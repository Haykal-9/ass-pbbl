import 'package:flutter/material.dart';

import '../main.dart';
import '../services/app_locale.dart';
import '../services/currency_service.dart';
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
  String _temaWarna = 'Canopy';
  bool _showChecklistProgress = false;

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
        _showChecklistProgress = all['show_checklist_progress'] as bool;
        _isLoading = false;
      });
    }
  }

  Color _themeColor(String theme) {
    switch (theme) {
      case 'Ancient Earth':
        return const Color(0xFF8B5E3C);
      case 'Urban Slate':
        return const Color(0xFF3D4451);
      case 'Canopy':
      default:
        return const Color(0xFF3A6B4A);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Modern off-white background
      appBar: AppBar(
        title: Text(
          tr('settings_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.grey[50],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _sectionHeader(tr('settings_display')),
          _buildCardGroup([
            ListTile(
              leading: _iconBox(Icons.dashboard_customize_outlined),
              title: Text(tr('settings_display_mode'), style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(tr('settings_display_desc')),
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
            _divider(),
            ListTile(
              leading: _iconBox(Icons.payments_outlined),
              title: Text(tr('settings_currency'), style: const TextStyle(fontWeight: FontWeight.w500)),
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
                  currencyNotifier.value = v;
                },
              ),
            ),
          ]),
          
          _sectionHeader(tr('settings_pref')),
          _buildCardGroup([
            ListTile(
              leading: _iconBox(Icons.language_outlined),
              title: Text(tr('settings_lang'), style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ID', label: Text('ID')),
                  ButtonSegment(value: 'EN', label: Text('EN')),
                ],
                selected: {_bahasa},
                onSelectionChanged: (s) async {
                  setState(() => _bahasa = s.first);
                  await _prefs.setBahasa(s.first);
                  bahasaNotifier.value = s.first;
                },
              ),
            ),
            _divider(),
            ListTile(
              leading: _iconBox(Icons.sort_outlined),
              title: Text(tr('settings_sort'), style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(_sortByLabel(_sortBy)),
              trailing: DropdownButton<String>(
                value: _sortBy,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 'terbaru', child: Text(tr('sort_latest'))),
                  DropdownMenuItem(value: 'az', child: Text(tr('sort_az'))),
                  DropdownMenuItem(value: 'kategori', child: Text(tr('sort_category'))),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _sortBy = v);
                  await _prefs.setSortBy(v);
                },
              ),
            ),
          ]),

          _sectionHeader(tr('settings_theme_section')),
          _buildCardGroup([
            ListTile(
              leading: _iconBox(Icons.palette_outlined),
              title: Text(tr('settings_theme'), style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: ['Canopy', 'Ancient Earth', 'Urban Slate'].map((t) {
                  final selected = _temaWarna == t;
                  return GestureDetector(
                    onTap: () async {
                      setState(() => _temaWarna = t);
                      await _prefs.setTemaWarna(t);
                      themeNotifier.value = t;
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
            _divider(),
            SwitchListTile(
              secondary: _iconBox(Icons.checklist_rtl_outlined),
              title: Text(tr('settings_checklist_progress'), style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(tr('settings_checklist_desc')),
              value: _showChecklistProgress,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (v) async {
                setState(() => _showChecklistProgress = v);
                await _prefs.setShowChecklistProgress(v);
              },
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
    );
  }

  Widget _divider() {
    return Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey[200]);
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _sortByLabel(String v) {
    switch (v) {
      case 'az':
        return tr('sort_az');
      case 'kategori':
        return tr('sort_category');
      default:
        return tr('sort_latest');
    }
  }
}
