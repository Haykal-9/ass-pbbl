// PERSON A — CREATE (form tambah destinasi baru)
// PERSON B — EDIT / UPDATE (form edit destinasi yang sudah ada)

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/destination.dart';
import '../services/app_locale.dart';
import '../services/database_helper.dart';

class AddEditScreen extends StatefulWidget {
  final Destination? destination;

  const AddEditScreen({super.key, this.destination});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _visitedAtCtrl;

  String _category = 'Wisata Alam';
  String _status = 'wishlist';
  String? _imagePath;
  bool _isSaving = false;

  bool get _isEditMode => widget.destination != null;

  @override
  void initState() {
    super.initState();
    final d = widget.destination;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _countryCtrl = TextEditingController(text: d?.country ?? '');
    _notesCtrl = TextEditingController(text: d?.notes ?? '');
    _visitedAtCtrl = TextEditingController(text: d?.visitedAt ?? '');
    if (d != null) {
      _category = ['Wisata Alam', 'Budaya & Sejarah', 'Kota & Urban'].contains(d.category) ? d.category : 'Wisata Alam';
      _status = d.status;
      if (d.photoPath != null) {
        if (kIsWeb || d.photoPath!.startsWith('http')) {
          _imagePath = d.photoPath;
        } else {
          final f = File(d.photoPath!);
          if (f.existsSync()) _imagePath = d.photoPath;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    _notesCtrl.dispose();
    _visitedAtCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (kIsWeb) {
      if (mounted) setState(() => _imagePath = picked.path);
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'photos'));
      await photosDir.create(recursive: true);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destPath = p.join(photosDir.path, fileName);
      await File(picked.path).copy(destPath);
  
      if (mounted) setState(() => _imagePath = destPath);
    }
  }

  Future<void> _pickDate() async {
    final firstDate = DateTime(2000);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _initialVisitedDate(firstDate, now),
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked != null) {
      _visitedAtCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  DateTime _initialVisitedDate(DateTime firstDate, DateTime lastDate) {
    final value = _visitedAtCtrl.text.trim();
    if (value.isEmpty) return lastDate;

    try {
      final parsed = DateTime.parse(value);
      if (parsed.isBefore(firstDate)) return firstDate;
      if (parsed.isAfter(lastDate)) return lastDate;
      return parsed;
    } catch (_) {
      return lastDate;
    }
  }

  // PERSON A — INSERT (create mode)
  // PERSON B — UPDATE (edit mode)
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();
    final dest = Destination(
      id: _isEditMode ? widget.destination!.id : null,
      name: _nameCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      category: _category,
      status: _status,
      notes: _notesCtrl.text.trim(),
      photoPath: _imagePath ?? (_isEditMode ? widget.destination!.photoPath : null),
      visitedAt: _status == 'visited' && _visitedAtCtrl.text.trim().isNotEmpty
          ? _visitedAtCtrl.text.trim()
          : null,
      createdAt: _isEditMode ? widget.destination!.createdAt : now,
    );

    if (_isEditMode) {
      await _db.updateDestination(dest); // PERSON B
    } else {
      await _db.insertDestination(dest); // PERSON A
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? tr('edit_dest') : tr('add_dest'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.grey[50],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imagePath != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            (kIsWeb || _imagePath!.startsWith('http'))
                                ? Image.network(_imagePath!, fit: BoxFit.cover)
                                : Image.file(File(_imagePath!), fit: BoxFit.cover),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.edit,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              tr('add_photo'),
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Nama
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDeco(tr('dest_name'), Icons.place),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? tr('required_field') : null,
              ),
              const SizedBox(height: 12),

              // Negara
              TextFormField(
                controller: _countryCtrl,
                decoration: _inputDeco(tr('country_city'), Icons.flag),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? tr('required_field') : null,
              ),
              const SizedBox(height: 12),

              // Kategori
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _inputDeco(tr('category'), Icons.category),
                items: const [
                  DropdownMenuItem(
                      value: 'Wisata Alam',
                      child: Text('Wisata Alam')),
                  DropdownMenuItem(
                      value: 'Budaya & Sejarah',
                      child: Text('Budaya & Sejarah')),
                  DropdownMenuItem(
                      value: 'Kota & Urban',
                      child: Text('Kota & Urban')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 12),

              // Status
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: _inputDeco(tr('status'), Icons.bookmark),
                items: const [
                  DropdownMenuItem(value: 'wishlist', child: Text('Wishlist')),
                  DropdownMenuItem(value: 'in_trip', child: Text('In Trip')),
                  DropdownMenuItem(value: 'visited', child: Text('Visited')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 12),

              // Tanggal kunjungan (hanya jika visited)
              if (_status == 'visited') ...[
                TextFormField(
                  controller: _visitedAtCtrl,
                  decoration: _inputDeco(
                    tr('visit_date'),
                    Icons.calendar_today,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: _pickDate,
                    ),
                  ),
                  readOnly: true,
                  onTap: _pickDate,
                  validator: (v) {
                    if (_status == 'visited' &&
                        (v == null || v.trim().isEmpty)) {
                      return tr('visit_date_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Catatan
              TextFormField(
                controller: _notesCtrl,
                decoration: _inputDeco(tr('notes_optional'), Icons.notes),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Simpan
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? tr('saving') : tr('save')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
