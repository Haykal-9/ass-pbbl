// PERSON A — CREATE + READ (home screen & daftar destinasi)

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/destination.dart';
import '../services/app_locale.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/destination_card.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';
import 'scratch_card_screen.dart';
import 'settings_screen.dart';
import 'social_gallery_screen.dart';
import 'statistics_screen.dart';

bool canScratchDestination(Destination destination) {
  return destination.status == 'wishlist' &&
      destination.photoPath?.trim().isNotEmpty == true;
}

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

  // PERSON B SharedPrefs
  String _sortBy = 'terbaru';

  // PERSON C SharedPrefs
  bool _showChecklistProgress = false;

  // Filter & search state
  String _filter = 'in_trip';
  String _search = '';

  final TextEditingController _searchCtrl = TextEditingController();

  // Bottom navigation state
  int _currentIndex = 0;

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
      if (mounted) {
        showSuccessSnackbar(
          context,
          'Destinasi "${dest.name}" berhasil dihapus',
          icon: Icons.delete_sweep,
        );
      }
    }
  }

  Future<void> _onLongPress(Destination dest) async {
    if (dest.status != 'wishlist') {
      await _confirmDelete(dest);
      return;
    }

    final hasPhoto = canScratchDestination(dest);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPhoto)
              ListTile(
                leading: Icon(
                  Icons.auto_awesome,
                  color: Theme.of(sheetContext).colorScheme.primary,
                ),
                title: Text(tr('scratch_reveal')),
                onTap: () => Navigator.pop(sheetContext, 'scratch'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(tr('delete')),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'scratch') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ScratchCardScreen(destination: dest)),
      );
      await _loadDestinations();
    } else if (action == 'delete') {
      await _confirmDelete(dest);
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

  // Dynamic AppBar based on current tab
  PreferredSizeWidget _buildAppBar() {
    switch (_currentIndex) {
      case 1:
        return AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
          title: Text(
            tr('nav_gallery'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          foregroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          scrolledUnderElevation: 0,
        );
      case 2:
        return AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
          title: Text(
            tr('stats_title'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          foregroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          scrolledUnderElevation: 0,
        );
      case 3:
        return AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
          title: Text(
            tr('settings_title'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          foregroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          scrolledUnderElevation: 0,
        );
      case 0:
      default:
        return AppBar(
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
              icon: Icon(
                _tampilanMode == 'grid' ? Icons.view_list : Icons.grid_view,
              ),
              tooltip: _tampilanMode == 'grid'
                  ? tr('list_view')
                  : tr('grid_view'),
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
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Home (destination list)
          _buildHomeBody(),
          // Tab 1: Social Gallery
          const SocialGalleryScreen(),
          // Tab 2: Statistics
          const StatisticsScreen(),
          // Tab 3: Settings
          SettingsScreen(onPrefsChanged: () => _loadPrefs()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: tr('nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.photo_library_outlined),
            selectedIcon: const Icon(Icons.photo_library),
            label: tr('nav_gallery'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: tr('nav_stats'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: tr('nav_settings'),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                // PERSON A — CREATE
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditScreen()),
                );
                await _loadDestinations();
              },
              icon: const Icon(Icons.add),
              label: Text(tr('add')),
            )
          : null,
    );
  }

  Widget _buildHomeBody() {
    return Column(
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
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
                _filterChip(
                  'in_trip',
                  tr('filter_in_trip'),
                  Icons.flight_takeoff,
                ),
                const SizedBox(width: 8),
                _filterChip('wishlist', tr('filter_wishlist'), Icons.favorite),
                const SizedBox(width: 8),
                _filterChip(
                  'visited',
                  tr('filter_visited'),
                  Icons.check_circle,
                ),
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
          onDelete: () => _onLongPress(dest),
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
          onDelete: () => _onLongPress(dest),
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
    final hasFilter = _filter != 'in_trip' || _search.isNotEmpty;
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
            hasFilter ? tr('empty_no_results') : tr('empty_no_dest'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter ? tr('empty_hint_filter') : tr('empty_hint_add'),
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 13,
            ),
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
    String value,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Text(label),
          if (_sortBy == value) ...[
            const Spacer(),
            Icon(
              Icons.check,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}
