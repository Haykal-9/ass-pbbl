// PERSON C — DELETE + READ (checklist)

import 'package:flutter/material.dart';

import '../models/checklist_item.dart';
import '../models/destination.dart';
import '../services/database_helper.dart';

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

  // PERSON C — DELETE checklist item
  Future<void> _deleteItem(int id) async {
    await _db.deleteChecklistItem(id);
    await _loadItems();
  }

  Future<void> _confirmDeleteItem(ChecklistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Item?'),
        content: Text('Hapus "${item.label}" dari checklist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _deleteItem(item.id!);
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _items.where((i) => i.isDone).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checklist',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.destination.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        bottom: _items.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _items.isEmpty ? 0 : doneCount / _items.length,
                  backgroundColor: Colors.white24,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress info
          if (_items.isNotEmpty)
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.checklist,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$doneCount dari ${_items.length} selesai',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Add item input
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tambah item checklist...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addItem,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.checklist_rtl,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada item checklist',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tambah hal yang ingin dilakukan di sini!',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Dismissible(
                            key: Key('checklist_${item.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child: const Icon(Icons.delete,
                                  color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Hapus Item?'),
                                  content:
                                      Text('Hapus "${item.label}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                              return confirmed ?? false;
                            },
                            onDismissed: (_) => _deleteItem(item.id!),
                            child: CheckboxListTile(
                              value: item.isDone,
                              onChanged: (_) => _toggleItem(item),
                              title: Text(
                                item.label,
                                style: TextStyle(
                                  decoration: item.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: item.isDone
                                      ? Colors.grey[500]
                                      : null,
                                ),
                              ),
                              secondary: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20),
                                color: Colors.red[300],
                                onPressed: () =>
                                    _confirmDeleteItem(item),
                              ),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
