import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../services/app_locale.dart';
import '../services/osm_nominatim_service.dart';
import '../models/trip_stop.dart';

class AddStopSheet extends StatefulWidget {
  final int dayNumber;
  final bool isBasecamp;
  final TripStop? existingStop;
  final String? minStartTime;

  const AddStopSheet({
    super.key, 
    required this.dayNumber,
    this.isBasecamp = false,
    this.existingStop,
    this.minStartTime,
  });

  @override
  State<AddStopSheet> createState() => _AddStopSheetState();
}

class _AddStopSheetState extends State<AddStopSheet> {
  final _osmService = OsmNominatimService();
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '09:00');
  final _endTimeCtrl = TextEditingController();
  
  String _transport = 'walk';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;
  Map<String, dynamic>? _selectedPlaceDetails;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _timeCtrl.text = widget.minStartTime ?? '09:00';
    if (widget.existingStop != null) {
      final stop = widget.existingStop!;
      _nameCtrl.text = stop.placeName;
      _addressCtrl.text = stop.placeAddress ?? '';
      _timeCtrl.text = stop.visitTime ?? '09:00';
      _endTimeCtrl.text = stop.endTime ?? '';
      _transport = stop.transportMode;
      _photoUrl = stop.photoUrl;
      if (stop.latitude != null && stop.longitude != null) {
        _selectedPlaceDetails = {
          'lat': stop.latitude,
          'lon': stop.longitude,
          'xid': stop.otmXid,
          'photoUrl': stop.photoUrl,
        };
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _timeCtrl.dispose();
    _endTimeCtrl.dispose();
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _photoUrl = pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existingStop != null
                        ? (widget.isBasecamp ? tr('trip_edit_basecamp') : 'Edit Tempat')
                        : (widget.isBasecamp ? tr('trip_set_basecamp') : tr('trip_new_place')),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Tutup',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Photo Picker at the top
            Text('Foto Tempat (Opsional)', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
                child: _photoUrl != null && _photoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _photoUrl!.startsWith('http') || _photoUrl!.startsWith('blob:') || kIsWeb
                            ? Image.network(_photoUrl!, fit: BoxFit.cover)
                            : Image.file(File(_photoUrl!), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 8),
                          Text('Pilih Foto dari Galeri', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Search field
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Cari tempat',
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
            Row(
              children: [
                Expanded(
                  child: TextField(
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endTimeCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Jam Berakhir',
                      prefixIcon: const Icon(Icons.av_timer),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: 'Opsional',
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
                      if (picked != null) {
                        _endTimeCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                ),
              ],
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
            // Photo picker moved to top
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                if (_nameCtrl.text.trim().isEmpty) return;
                
                if (widget.minStartTime != null && widget.minStartTime!.isNotEmpty && widget.existingStop == null) {
                  int toMins(String t) {
                    final p = t.split(':');
                    return p.length == 2 ? int.parse(p[0]) * 60 + int.parse(p[1]) : 0;
                  }
                  if (toMins(_timeCtrl.text) < toMins(widget.minStartTime!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Jam mulai tidak boleh lebih awal dari waktu berakhir tempat sebelumnya (${widget.minStartTime})')),
                    );
                    return;
                  }
                }
                
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
                  'address': _addressCtrl.text,
                  'time': _timeCtrl.text,
                  'endTime': _endTimeCtrl.text.trim().isEmpty ? '' : _endTimeCtrl.text,
                  'transport': _transport,
                  'photoUrl': _photoUrl,
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
