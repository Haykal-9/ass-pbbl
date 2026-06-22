import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  final String? maxEndTime;

  const AddStopSheet({
    super.key, 
    required this.dayNumber,
    this.isBasecamp = false,
    this.existingStop,
    this.minStartTime,
    this.maxEndTime,
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
  String? _startTimeError;
  String? _endTimeError;

  int _toMins(String t) {
    final p = t.split(':');
    return p.length == 2 ? int.parse(p[0]) * 60 + int.parse(p[1]) : 0;
  }

  void _validateTimes() {
    setState(() {
      _startTimeError = null;
      _endTimeError = null;
      
      if (widget.minStartTime != null && widget.minStartTime!.isNotEmpty) {
        if (_toMins(_timeCtrl.text) < _toMins(widget.minStartTime!)) {
          _startTimeError = 'Pilih waktu setelah ${widget.minStartTime}';
        }
      }
      
      if (widget.maxEndTime != null && widget.maxEndTime!.isNotEmpty) {
        if (_toMins(_timeCtrl.text) > _toMins(widget.maxEndTime!)) {
          _startTimeError = 'Tidak boleh melewati jadwal berikutnya (${widget.maxEndTime})';
        }
      }
      
      if (_endTimeCtrl.text.isNotEmpty) {
        if (_toMins(_endTimeCtrl.text) < _toMins(_timeCtrl.text)) {
          _endTimeError = 'Harus setelah jam kunjungan';
        } else if (widget.maxEndTime != null && widget.maxEndTime!.isNotEmpty) {
          if (_toMins(_endTimeCtrl.text) > _toMins(widget.maxEndTime!)) {
            _endTimeError = 'Batas maksimal: ${widget.maxEndTime}';
          }
        }
      }
    });
  }

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
          'lng': stop.longitude,
          'xid': stop.otmXid,
          'photoUrl': stop.photoUrl,
        };
      }
    }
    _validateTimes();
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
      label: Text(tr('transport_$mode'), style: TextStyle(color: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface)),
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

  Future<TimeOfDay?> _showScrollableTimePicker(TimeOfDay initialTime) async {
    TimeOfDay? pickedTime;
    final now = DateTime.now();
    DateTime initialDateTime = DateTime(now.year, now.month, now.day, initialTime.hour, initialTime.minute);

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 280,
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(tr('cancel'), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: Text('OK', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    pickedTime = TimeOfDay(hour: initialDateTime.hour, minute: initialDateTime.minute);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: initialDateTime,
                onDateTimeChanged: (DateTime newDateTime) {
                  initialDateTime = newDateTime;
                },
              ),
            ),
          ],
        ),
      ),
    );
    return pickedTime;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _timeCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: tr('trip_visit_time'),
                      prefixIcon: const Icon(Icons.access_time),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      errorText: _startTimeError,
                    ),
                    onTap: () async {
                      final initialTimeStr = _timeCtrl.text.split(':');
                      final initialH = int.tryParse(initialTimeStr[0]) ?? 9;
                      final initialM = initialTimeStr.length > 1 ? (int.tryParse(initialTimeStr[1]) ?? 0) : 0;
                      
                      final picked = await _showScrollableTimePicker(
                        TimeOfDay(hour: initialH, minute: initialM),
                      );
                      if (picked != null) {
                        _timeCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        _validateTimes();
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
                      errorText: _endTimeError,
                    ),
                    onTap: () async {
                      final initialTimeStr = _endTimeCtrl.text.isNotEmpty ? _endTimeCtrl.text.split(':') : _timeCtrl.text.split(':');
                      final initialH = int.tryParse(initialTimeStr[0]) ?? 9;
                      final initialM = initialTimeStr.length > 1 ? (int.tryParse(initialTimeStr[1]) ?? 0) : 0;

                      final picked = await _showScrollableTimePicker(
                        TimeOfDay(hour: initialH, minute: initialM),
                      );
                      if (picked != null) {
                        _endTimeCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        _validateTimes();
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
                
                _validateTimes();
                if (_startTimeError != null || _endTimeError != null) {
                  return; // Stop submission if there are visual errors
                }
                
                // Best Practice: Prevent saving without map coordinates to avoid breaking route calculations
                if (_selectedPlaceDetails == null || _selectedPlaceDetails!['lat'] == null || _selectedPlaceDetails!['lng'] == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap cari dan pilih lokasi dari daftar Peta agar rute jarak dapat dikalkulasi!'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
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
              icon: Icon(widget.isBasecamp ? Icons.home : Icons.add_location_alt),
              label: Text(widget.isBasecamp ? tr('trip_set_basecamp') : tr('trip_add_stop')),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
