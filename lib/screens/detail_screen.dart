// PERSON B — UPDATE + READ (detail destinasi)

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../services/app_locale.dart';
import '../services/currency_service.dart';
import '../services/database_helper.dart';
import '../widgets/category_chip.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/destination_status_badge.dart';
import 'add_edit_screen.dart';
import 'budget_screen.dart';
import 'checklist_screen.dart';
import 'gallery_screen.dart';

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
  double _budgetTotal = 0;
  int _checklistTotal = 0;
  int _checklistDone = 0;

  @override
  void initState() {
    super.initState();
    _destination = widget.destination;
    _reload();
    currencyNotifier.addListener(_onCurrencyChanged);
  }

  @override
  void dispose() {
    currencyNotifier.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) setState(() {});
  }

  // PERSON B — READ single destination by ID
  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final fresh = await _db.getDestinationById(_destination.id!);
    final budgetTotal = await _db.getDestinationBudgetTotal(_destination.id!);
    final checklistItems = await _db.getChecklistItems(_destination.id!);
    
    if (mounted) {
      setState(() {
        if (fresh != null) _destination = fresh;
        _budgetTotal = budgetTotal;
        _checklistTotal = checklistItems.length;
        _checklistDone = checklistItems.where((item) => item.isDone).length;
        _isLoading = false;
      });
    }
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
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        tooltip: tr('cancel'),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _photoBackground(),
                  ),
                  actions: [
                    _buildCircleButton(
                      icon: Icons.edit,
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
                    _buildCircleButton(
                      icon: Icons.delete,
                      tooltip: tr('delete'),
                      onPressed: _confirmDelete,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category + Status row
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            CategoryChip(_destination.category),
                            DestinationStatusBadge(status: _destination.status),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Name
                        Text(
                          trName(_destination.name),
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
                                size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text(
                              trCountry(_destination.country),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Notes
                        Text(
                          tr('notes_label'),
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

                        // Action Cards (Checklist, Budget, Gallery)
                        _checklistCard(),
                        const SizedBox(height: 12),
                        _budgetCard(),
                        const SizedBox(height: 12),
                        _galleryCard(),

                        const SizedBox(height: 24),

                        // Visited date
                        if (_destination.visitedAt != null) ...[
                          DetailInfoRow(
                            icon: Icons.event_available,
                            label: tr('visited_on'),
                            value: _destination.visitedAt!,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Created
                        DetailInfoRow(
                          icon: Icons.access_time,
                          label: tr('added_on'),
                          value: _formatDate(_destination.createdAt),
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _checklistCard() {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChecklistScreen(destination: _destination),
          ),
        );
        await _reload();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.checklist, color: primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Checklist Perjalanan',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _checklistTotal > 0
                        ? '$_checklistDone dari $_checklistTotal selesai'
                        : 'Belum ada daftar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _checklistDone == _checklistTotal && _checklistTotal > 0
                          ? Colors.green
                          : primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: primary),
          ],
        ),
      ),
    );
  }

  Widget _budgetCard() {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BudgetScreen(destination: _destination),
          ),
        );
        await _reload();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_balance_wallet, color: primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _destination.status == 'visited'
                        ? tr('budget_used')
                        : tr('budget_estimate'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _budgetTotal > 0
                        ? CurrencyService.format(_budgetTotal)
                        : tr('budget_none'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _budgetTotal > 0 ? primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: primary),
          ],
        ),
      ),
    );
  }

  Widget _galleryCard() {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GalleryScreen(destination: _destination),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.photo_library, color: primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Galeri Polaroid',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lihat Kenangan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: primary),
          ],
        ),
      ),
    );
  }

  Widget _photoBackground() {
    final photoPath = _destination.photoPath;
    if (photoPath != null) {
      if (kIsWeb || photoPath.startsWith('http')) {
        return Image.network(
          photoPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _photoPlaceholder(),
        );
      } else {
        final imageFile = File(photoPath);
        if (imageFile.existsSync()) {
          return Image.file(
            imageFile,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _photoPlaceholder(),
          );
        }
      }
    }

    return _photoPlaceholder();
  }

  Widget _photoPlaceholder() {
    return Container(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.broken_image,
            size: 50,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
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

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 20),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('delete_dest_title')),
        content: Text(
          '${tr('delete_dest_confirm_detail')} "${_destination.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _db.deleteDestination(_destination.id!);
      if (mounted) {
        showSuccessSnackbar(
          context,
          'Destinasi "${_destination.name}" berhasil dihapus',
          icon: Icons.delete_sweep,
        );
        Navigator.pop(context, true);
      }
    }
  }
}
