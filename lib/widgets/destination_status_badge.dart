import 'package:flutter/material.dart';

import '../services/app_locale.dart';

class DestinationStatusBadge extends StatelessWidget {
  final String status;

  const DestinationStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isVisited = status == 'visited';
    final color = isVisited ? Colors.green : Colors.orange;

    return Chip(
      avatar: Icon(
        isVisited ? Icons.check_circle : Icons.favorite,
        size: 14,
        color: color,
      ),
      label: Text(
        isVisited ? tr('status_visited') : tr('status_wishlist'),
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
