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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(_icon(), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _label(),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
