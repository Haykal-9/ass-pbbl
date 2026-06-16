import 'package:flutter/material.dart';
import 'dart:async';
import '../services/app_locale.dart';
import '../services/osm_nominatim_service.dart';

class AddStopSheet extends StatefulWidget {
  final int dayNumber;

  const AddStopSheet({super.key, required this.dayNumber});

  @override
  State<AddStopSheet> createState() => _AddStopSheetState();
}

class _AddStopSheetState extends State<AddStopSheet> {
  final _osmService = OsmNominatimService();
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '09:00');
  
  String _transport = 'walk';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;
  Map<String, dynamic>? _selectedPlaceDetails;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _timeCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      try {
        final results = await _osmService.searchPlaces(query);
        if (mounted) setState(() => _searchResults = results);
      } catch (e) {
        // ignore errors for autocomplete
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    setState(() => _isSearching = true);
    try {
      final details = await _osmService.getPlaceDetails(place);
      setState(() {
        _selectedPlaceDetails = details;
        _nameCtrl.text = details['name'] ?? '';
        _addressCtrl.text = details['address_str'] ?? '';
        
        _searchResults = [];
        _searchCtrl.clear();
      });
    } catch (e) {
      // fallback to basic
      setState(() {
        _nameCtrl.text = place['name'] ?? place['display_name']?.split(',').first ?? 'Unknown';
        _searchResults = [];
        _searchCtrl.clear();
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Widget _transportChip(String mode, IconData icon) {
    final isActive = _transport == mode;
    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
      label: Text(mode, style: TextStyle(color: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface)),
      selected: isActive,
      selectedColor: Theme.of(context).colorScheme.primary,
      onSelected: (_) => setState(() => _transport = mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              tr('trip_add_stop'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            
            // Search field
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Cari tempat (OpenStreetMap)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            if (_searchResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (ctx, i) {
                    final place = _searchResults[i];
                    return ListTile(
                      leading: const Icon(Icons.place),
                      title: Text(place['name']?.toString().isNotEmpty == true ? place['name'] : place['display_name']?.split(',').first ?? 'Unknown'),
                      subtitle: Text(place['type']?.toString().replaceAll('_', ' ') ?? ''),
                      onTap: () => _selectPlace(place),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: tr('trip_place_name'),
                prefixIcon: const Icon(Icons.place_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: tr('trip_place_address'),
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: tr('trip_visit_time'),
                prefixIcon: const Icon(Icons.access_time),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                if (picked != null) {
                  _timeCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                }
              },
            ),
            const SizedBox(height: 12),
            Text(tr('trip_transport_mode'), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _transportChip('walk', Icons.directions_walk),
                _transportChip('car', Icons.directions_car),
                _transportChip('bike', Icons.directions_bike),
                _transportChip('public', Icons.directions_bus),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                if (_nameCtrl.text.trim().isEmpty) return;
                
                String? photoUrl;
                double? lat, lng;
                String? xid;
                
                if (_selectedPlaceDetails != null) {
                  lat = _selectedPlaceDetails!['lat'];
                  lng = _selectedPlaceDetails!['lng'];
                  xid = _selectedPlaceDetails!['xid'];
                }

                Navigator.pop(context, {
                  'name': _nameCtrl.text.trim(),
                  'address': _addressCtrl.text.trim(),
                  'time': _timeCtrl.text.trim(),
                  'transport': _transport,
                  'photoUrl': photoUrl,
                  'lat': lat,
                  'lng': lng,
                  'xid': xid,
                });
              },
              icon: const Icon(Icons.add_location_alt),
              label: Text(tr('trip_add_stop')),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
