import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String category;

  const CategoryChip(this.category, {super.key});

  Color _color() {
    switch (category) {
      case 'pantai':
        return Colors.blue;
      case 'kota':
        return Colors.blueGrey;
      case 'gunung':
        return Colors.brown;
      case 'alam':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _icon() {
    switch (category) {
      case 'pantai':
        return Icons.beach_access;
      case 'kota':
        return Icons.location_city;
      case 'gunung':
        return Icons.terrain;
      case 'alam':
        return Icons.park;
      default:
        return Icons.place;
    }
  }

  String _label() {
    switch (category) {
      case 'pantai':
        return 'Pantai';
      case 'kota':
        return 'Kota';
      case 'gunung':
        return 'Gunung';
      case 'alam':
        return 'Alam';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Chip(
      avatar: Icon(_icon(), size: 14, color: color),
      label: Text(
        _label(),
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
