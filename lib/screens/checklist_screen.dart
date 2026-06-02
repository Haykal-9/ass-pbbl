// PERSON C — DELETE + READ (checklist)

import 'package:flutter/material.dart';

import '../models/checklist_item.dart';
import '../models/destination.dart';
import '../services/app_locale.dart';
import '../services/database_helper.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/swipeable_checklist_item.dart';

class ChecklistScreen extends StatefulWidget {
  final Destination destination;

  const ChecklistScreen({super.key, required this.destination});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<ChecklistItem> _items = [];
  bool _isLoading = true;
  final TextEditingController _addCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await _db.getChecklistItems(widget.destination.id!);
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  // PERSON C — CREATE checklist item
  Future<void> _addItem() async {
    final label = _addCtrl.text.trim();
    if (label.isEmpty) return;
    final item = ChecklistItem(
      destinationId: widget.destination.id!,
      label: label,
      isDone: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _db.insertChecklistItem(item);
    _addCtrl.clear();
    await _loadItems();
  }

  // PERSON C — UPDATE checklist item (toggle)
  Future<void> _toggleItem(ChecklistItem item) async {
    await _db.updateChecklistItem(item.copyWith(isDone: !item.isDone));
    await _loadItems();
  }

  // PERSON C — EDIT checklist item (Inline)
  Future<void> _editItem(ChecklistItem item, String newLabel) async {
    await _db.updateChecklistItem(item.copyWith(label: newLabel));
    await _loadItems();
    if (mounted) {
      showSuccessSnackbar(
        context,
        'Aktivitas berhasil diperbarui',
        icon: Icons.check_circle_outline,
      );
    }
  }

  // PERSON C — DELETE checklist item
  Future<void> _deleteItem(ChecklistItem item) async {
    await _db.deleteChecklistItem(item.id!);
    await _loadItems();
    if (mounted) {
      showSuccessSnackbar(
        context,
        'Aktivitas "${item.label}" berhasil dihapus',
        icon: Icons.delete_sweep,
      );
    }
  }

  Future<bool?> _confirmDeleteItem(ChecklistItem item) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('confirm_delete')),
        content: Text('${tr('delete')} "${item.label}" ${tr('delete_checklist_msg')}'),
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
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _items.where((i) => i.isDone).length;
    final progress = _items.isEmpty ? 0.0 : doneCount / _items.length;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Match settings screen background
      appBar: AppBar(
        title: Text(
          'Checklist ${widget.destination.name}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        foregroundColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.grey[50],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Elegant Progress Header
          if (_items.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('checklist_progress'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$doneCount ${tr('checklist_done_of')} ${_items.length} ${tr('checklist_complete')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 5,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // List Items
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          
                          // Menggunakan Custom Widget (Lebih rapi dan performa lebih baik)
                          return SwipeableChecklistItem(
                            key: ValueKey(item.id),
                            item: item,
                            onChanged: (_) => _toggleItem(item),
                            onConfirmDelete: () => _confirmDeleteItem(item),
                            onDelete: () => _deleteItem(item),
                            onEdit: (newVal) => _editItem(item, newVal),
                          );
                        },
                      ),
          ),
          
          // Add Item Input anchored to bottom
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addCtrl,
                      decoration: InputDecoration(
                        hintText: tr('checklist_add_hint'),
                        hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), 
                            fontSize: 13),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 22),
                      onPressed: _addItem,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.checklist_rtl_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr('checklist_empty'),
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('checklist_empty_hint'),
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
