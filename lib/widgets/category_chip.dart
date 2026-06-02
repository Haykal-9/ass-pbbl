import 'package:flutter/material.dart';

import '../services/app_locale.dart';

class CategoryChip extends StatelessWidget {
  final String category;

  const CategoryChip(this.category, {super.key});

  Color _color() {
    switch (category) {
      case 'Wisata Alam':
        return Colors.green;
      case 'Budaya & Sejarah':
        return Colors.brown;
      case 'Kota & Urban':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  IconData _icon() {
    switch (category) {
      case 'Wisata Alam':
        return Icons.park;
      case 'Budaya & Sejarah':
        return Icons.account_balance;
      case 'Kota & Urban':
        return Icons.location_city;
      default:
        return Icons.place;
    }
  }

  String _label() {
    return trCategory(category);
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
