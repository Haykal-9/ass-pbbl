import 'package:flutter/material.dart';
import '../models/checklist_item.dart';

class SwipeableChecklistItem extends StatefulWidget {
  final ChecklistItem item;
  final int index;
  final ValueChanged<bool?> onChanged;
  final Future<bool?> Function() onConfirmDelete;
  final VoidCallback onDelete;
  final ValueChanged<String> onEdit;

  const SwipeableChecklistItem({
    super.key,
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onConfirmDelete,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<SwipeableChecklistItem> createState() => _SwipeableChecklistItemState();
}

class _SwipeableChecklistItemState extends State<SwipeableChecklistItem> {
  // State untuk melacak jarak pergeseran (swipe) HANYA untuk item ini
  double _dragOffset = 0.0;
  bool _isEditing = false;
  late TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.item.label);
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      clipBehavior: Clip.antiAlias, // Penting agar background merah dipotong sesuai lengkungan sudut Card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      color: Theme.of(context).cardColor,
      child: GestureDetector(
        // Mendeteksi gerakan geser secara horizontal (kiri-kanan)
        onHorizontalDragUpdate: (details) {
          // Hanya me-rebuild UI widget ini saja, BUKAN seluruh halaman
          setState(() {
            // details.delta.dx bernilai negatif jika digeser ke kiri
            _dragOffset += details.delta.dx;
            
            // Batasi agar hanya bisa digeser ke kiri (maksimal offset 0)
            if (_dragOffset > 0) _dragOffset = 0;
          });
        },
        // Dijalankan saat jari dilepas setelah menggeser
        onHorizontalDragEnd: (details) async {
          // Jika digeser ke kiri lebih dari 80 pixel (batas / threshold)
          if (_dragOffset < -80) {
            final confirmed = await widget.onConfirmDelete();
            if (confirmed == true) {
              widget.onDelete();
            } else {
              // Batal hapus, kembalikan posisi ke awal
              setState(() {
                _dragOffset = 0.0;
              });
            }
          } else {
            // Geseran belum cukup jauh, batalkan dan kembalikan posisi ke awal
            setState(() {
              _dragOffset = 0.0;
            });
          }
        },
        child: Stack(
          children: [
            // Lapisan Bawah: Latar Belakang Merah & Ikon Sampah
            Positioned.fill(
              child: Container(
                color: Colors.red[400],
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_sweep, color: Colors.white),
              ),
            ),
            
            // Lapisan Atas: Konten Checklist (Bergeser ke kiri mengikuti dragOffset)
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Container(
                color: Theme.of(context).cardColor,
                child: CheckboxListTile(
                  value: widget.item.isDone,
                  onChanged: widget.onChanged,
                  activeColor: Theme.of(context).colorScheme.primary,
                  checkColor: Theme.of(context).colorScheme.onPrimary,
                  title: _isEditing
                      ? TextField(
                          controller: _editCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                          onSubmitted: (val) {
                            setState(() => _isEditing = false);
                            if (val.trim().isNotEmpty && val.trim() != widget.item.label) {
                              widget.onEdit(val.trim());
                            } else {
                              _editCtrl.text = widget.item.label;
                            }
                          },
                        )
                      : Text(
                          widget.item.label,
                          style: TextStyle(
                            fontSize: 15,
                            decoration: widget.item.isDone ? TextDecoration.lineThrough : null,
                            color: widget.item.isDone ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4) : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  secondary: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: ReorderableDragStartListener(
                          index: widget.index,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.drag_indicator,
                              size: 22,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isEditing ? Icons.check : Icons.edit,
                          size: 18,
                          color: _isEditing ? Colors.green : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        onPressed: () {
                          if (_isEditing) {
                            setState(() => _isEditing = false);
                            final val = _editCtrl.text.trim();
                            if (val.isNotEmpty && val != widget.item.label) {
                              widget.onEdit(val);
                            } else {
                              _editCtrl.text = widget.item.label;
                            }
                          } else {
                            setState(() {
                              _isEditing = true;
                              _editCtrl.text = widget.item.label;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
