// PERSON A — CREATE + READ (home screen & daftar destinasi)

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/destination.dart';
import '../services/app_locale.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../widgets/destination_card.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final PreferencesService _prefs = PreferencesService();

  List<Destination> _destinations = [];
  bool _isLoading = true;

  // PERSON A SharedPrefs
  String _tampilanMode = 'grid';
  bool _showChecklistProgress = false;

  // PERSON B SharedPref
  String _sortBy = 'terbaru';

  // Filter & search state
  String _filter = 'all';
  String _search = '';

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final tampilan = await _prefs.getTampilanMode();
    final sortBy = await _prefs.getSortBy();
    final showProgress = await _prefs.getShowChecklistProgress();
    if (mounted) {
      setState(() {
        _tampilanMode = tampilan;
        _sortBy = sortBy;
        _showChecklistProgress = showProgress;
      });
    }
    await _loadDestinations();
  }

  // PERSON A — READ (list)
  Future<void> _loadDestinations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final list = await _db.getDestinations(
      filter: _filter,
      sortBy: _sortBy,
      search: _search,
    );
    if (mounted) {
      setState(() {
        _destinations = list;
        _isLoading = false;
      });
    }
  }

  // PERSON C — DELETE (triggered from HomeScreen via long-press)
  Future<void> _confirmDelete(Destination dest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('delete_title')),
        content: Text(
          '${tr('delete')} "${dest.name}" ${tr('delete_dest_confirm')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteDestination(dest.id!);
      await _loadDestinations();
    }
  }

  Future<void> _toggleTampilan() async {
    final next = _tampilanMode == 'grid' ? 'list' : 'grid';
    await _prefs.setTampilanMode(next);
    setState(() => _tampilanMode = next);
  }

  Future<void> _changeSortBy(String value) async {
    await _prefs.setSortBy(value);
    setState(() => _sortBy = value);
    await _loadDestinations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.primary,
        title: Semantics(
          label: 'WanderList',
          child: SizedBox(
            width: 150,
            height: 45,
            child: SvgPicture.asset(
              'wanderlist-logo-horizontal-transparent.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: tr('stats_tooltip'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: tr('settings_tooltip'),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              await _loadPrefs();
            },
          ),
          IconButton(
            icon: Icon(
              _tampilanMode == 'grid' ? Icons.view_list : Icons.grid_view,
            ),
            tooltip: _tampilanMode == 'grid' ? tr('list_view') : tr('grid_view'),
            onPressed: _toggleTampilan,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: tr('sort_tooltip'),
            onSelected: _changeSortBy,
            itemBuilder: (_) => [
              _sortMenuItem('terbaru', tr('sort_latest'), Icons.access_time),
              _sortMenuItem('az', tr('sort_az'), Icons.sort_by_alpha),
              _sortMenuItem('kategori', tr('sort_category'), Icons.category),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: tr('search_hint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                          _loadDestinations();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              onChanged: (v) {
                setState(() => _search = v);
                _loadDestinations();
              },
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', tr('filter_all'), Icons.public),
                  const SizedBox(width: 8),
                  _filterChip('wishlist', tr('filter_wishlist'), Icons.favorite),
                  const SizedBox(width: 8),
                  _filterChip('visited', tr('filter_visited'), Icons.check_circle),
                ],
              ),
            ),
          ),

          // Destination list / grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _destinations.isEmpty
                    ? _emptyState()
                    : _tampilanMode == 'grid'
                        ? _buildGrid()
                        : _buildList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // PERSON A — CREATE
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditScreen(),
            ),
          );
          await _loadDestinations();
        },
        icon: const Icon(Icons.add),
        label: Text(tr('add')),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: _destinations.length,
      itemBuilder: (context, index) {
        final dest = _destinations[index];
        return DestinationCard(
          destination: dest,
          isGrid: true,
          showChecklistProgress: _showChecklistProgress,
          onTap: () => _openDetail(dest),
          onDelete: () => _confirmDelete(dest),
        );
      },
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _destinations.length,
      itemBuilder: (context, index) {
        final dest = _destinations[index];
        return DestinationCard(
          destination: dest,
          isGrid: false,
          showChecklistProgress: _showChecklistProgress,
          onTap: () => _openDetail(dest),
          onDelete: () => _confirmDelete(dest),
        );
      },
    );
  }

  Future<void> _openDetail(Destination dest) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(destination: dest)),
    );
    await _loadDestinations();
  }

  Widget _emptyState() {
    final hasFilter = _filter != 'all' || _search.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.travel_explore,
            size: 72,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? tr('empty_no_results')
                : tr('empty_no_dest'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? tr('empty_hint_filter')
                : tr('empty_hint_add'),
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, IconData icon) {
    final selected = _filter == value;
    return FilterChip(
      selected: selected,
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onSelected: (_) {
        setState(() => _filter = value);
        _loadDestinations();
      },
    );
  }

  PopupMenuItem<String> _sortMenuItem(
      String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Text(label),
          if (_sortBy == value) ...[
            const Spacer(),
            Icon(Icons.check,
                size: 16,
                color: Theme.of(context).colorScheme.primary),
          ],
        ],
      ),
    );
  }
}
