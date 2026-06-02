import 'package:flutter/material.dart';
import '../models/checklist_item.dart';

class SwipeableChecklistItem extends StatefulWidget {
  final ChecklistItem item;
  final ValueChanged<bool?> onChanged;
  final Future<bool?> Function() onConfirmDelete;
  final VoidCallback onDelete;

  const SwipeableChecklistItem({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onConfirmDelete,
    required this.onDelete,
  });

  @override
  State<SwipeableChecklistItem> createState() => _SwipeableChecklistItemState();
}

class _SwipeableChecklistItemState extends State<SwipeableChecklistItem> {
  // State untuk melacak jarak pergeseran (swipe) HANYA untuk item ini
  double _dragOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      clipBehavior: Clip.antiAlias, // Penting agar background merah dipotong sesuai lengkungan sudut Card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      color: Colors.white,
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
                color: Colors.white, // Menutupi latar merah saat offset = 0
                child: CheckboxListTile(
                  value: widget.item.isDone,
                  onChanged: widget.onChanged,
                  activeColor: Theme.of(context).colorScheme.primary,
                  checkColor: Colors.white,
                  title: Text(
                    widget.item.label,
                    style: TextStyle(
                      fontWeight: widget.item.isDone ? FontWeight.normal : FontWeight.w500,
                      decoration: widget.item.isDone ? TextDecoration.lineThrough : null,
                      color: widget.item.isDone ? Colors.grey[400] : Colors.black87,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  secondary: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.grey[300],
                    onPressed: () async {
                      final confirmed = await widget.onConfirmDelete();
                      if (confirmed == true) {
                        widget.onDelete();
                      }
                    },
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
