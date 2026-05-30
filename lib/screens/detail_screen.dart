// PERSON B — UPDATE + READ (detail destinasi)

import 'dart:io';

import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../services/database_helper.dart';
import '../widgets/category_chip.dart';
import 'add_edit_screen.dart';
import 'checklist_screen.dart';

class DetailScreen extends StatefulWidget {
  final Destination destination;

  const DetailScreen({super.key, required this.destination});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  late Destination _destination;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _destination = widget.destination;
    _reload();
  }

  // PERSON B — READ single destination by ID
  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final fresh = await _db.getDestinationById(_destination.id!);
    if (mounted) {
      setState(() {
        if (fresh != null) _destination = fresh;
        _isLoading = false;
      });
    }
  }

  Widget _statusBadge() {
    final isVisited = _destination.status == 'visited';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isVisited
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVisited
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.orange.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVisited ? Icons.check_circle : Icons.favorite,
            size: 14,
            color: isVisited ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 5),
          Text(
            isVisited ? 'Visited' : 'Wishlist',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isVisited ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      _destination.name,
                      style: const TextStyle(
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                    background: _photoBackground(),
                  ),
                  actions: [
                    // PERSON B — navigate to edit
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditScreen(
                              destination: _destination,
                            ),
                          ),
                        );
                        await _reload();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.checklist),
                      tooltip: 'Checklist',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChecklistScreen(
                              destination: _destination,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category + Status row
                        Row(
                          children: [
                            CategoryChip(_destination.category),
                            const SizedBox(width: 10),
                            _statusBadge(),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Name
                        Text(
                          _destination.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),

                        // Country
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              _destination.country,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Notes
                        Text(
                          'Catatan',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _destination.notes.isEmpty
                              ? '—'
                              : _destination.notes,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 20),

                        // Visited date
                        if (_destination.visitedAt != null) ...[
                          _infoRow(
                            Icons.event_available,
                            'Dikunjungi',
                            _destination.visitedAt!,
                            Colors.green,
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Created
                        _infoRow(
                          Icons.access_time,
                          'Ditambahkan',
                          _formatDate(_destination.createdAt),
                          Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
              fontWeight: FontWeight.w500, color: Colors.grey[700]),
        ),
        Text(value, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _photoBackground() {
    final photoPath = _destination.photoPath;
    if (photoPath != null) {
      final imageFile = File(photoPath);
      if (imageFile.existsSync()) {
        return Image.file(
          imageFile,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _photoPlaceholder(),
        );
      }
    }

    return _photoPlaceholder();
  }

  Widget _photoPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.landscape,
        size: 80,
        color: Colors.grey[400],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
